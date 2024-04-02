//************** UTILITY AND HELPERS ****************

int GAUSSIAN_FILTER[] = {
    2, 4,  5,  4,  2, // sum=17
    4, 9,  12, 9,  4, // sum=38
    5, 12, 15, 12, 5, // sum=49
    4, 9,  12, 9,  4, // sum=38
    2, 4,  5,  4,  2  // sum=17
};

int SOBEL_VERTICAL_FILTER[] = {-1, 0, +1, -2, 0, +2, -1, 0, +1};
int SOBEL_HORIZONTAL_FILTER[] = {+1, +2, +1, 0, 0, 0, -1, -2, -1};
int SOBEL_SIZE = 3;

double GAUSSIAN_SUM = 159.0;
int GAUSSIAN_SIZE = 5;
int COLOUR_BITS = 8;
int COLOUR_MASK = 255;
int RED = 2;
int GREEN = 1;
int BLUE = 0;

// Minimum of 0 and maximum if 255
int clamp(double value) {
  int result = (int)(value + 0.5); // round to nearest integer
  if (result <= 0) {
    return 0;
  } else if (result > COLOUR_MASK) {
    return 255;
  } else {
    return result;
  }
}

// Construct an integer with the different colour components in RGB
int createPixel(int red, int green, int blue) {
  // Construct the pixel value
  if (red >= 0 && red <= COLOUR_MASK && green >= 0 && green <= COLOUR_MASK &&
      blue >= 0 && blue <= COLOUR_MASK) {
    return (red << (2 * COLOUR_BITS)) + (green << COLOUR_BITS) + blue;
  }
}

// Wraps overflows above and below the size of the image/matrix
int wrap(int pos, int size) {
  if (pos < 0) {
    pos = size + (pos % size);
  } else if (pos >= size) {
    pos %= size;
  }

  if (0 <= pos && pos < size) {
    return pos;
  }
}

int colourValue(int pixel, int colour) {
  return (pixel >> (colour * COLOUR_BITS)) & COLOUR_MASK;
}

int convolution(__global int *pixels, int xCentre, int yCentre, int *filter,
                int filterSize, int colour, int height, int width) {
  int sum = 0;
  // find the width and height of the filter matrix, which must be square.
  int filterHalf = filterSize / 2;
  for (int filterY = 0; filterY < filterSize; filterY++) {
    int y = wrap(yCentre + filterY - filterHalf, height);
    for (int filterX = 0; filterX < filterSize; filterX++) {
      int x = wrap(xCentre + filterX - filterHalf, width);
      int rgb = pixels[y * width + x];
      int filterVal = filter[filterY * filterSize + filterX];
      sum += colourValue(rgb, colour) * filterVal;
    }
  }
  // System.out.println("convolution(" + xCentre + ", " + yCentre + ") = " +
  // sum);
  return sum;
}

int red(int pixel) { return colourValue(pixel, RED); }

int green(int pixel) { return colourValue(pixel, GREEN); }

int blue(int pixel) { return colourValue(pixel, BLUE); }

int quantizeColour(int colourValue, int numPerChannel) {
  float colour = colourValue / (COLOUR_MASK + 1.0f) * numPerChannel;
  // IMPORTANT NOTE: due to the different implemention of the "round" funciton
  // in OpenCL, you need to use 0.49999f instead of 0.5f in your kernel code
  int discrete = round(colour - 0.5f);
  if (0 <= discrete && discrete < COLOUR_MASK) {
    int newColour = discrete * COLOUR_MASK / (numPerChannel - 1);
    if (0 <= newColour && newColour <= COLOUR_MASK) {
      return newColour;
    }
  }
}

// ************************** KERNELS **************************

__kernel void gaussianBlur(__global int *pixels, __global int *newPixels,
                           const int width, const int height) {
  int index = get_global_id(0);
  int x = index % width; // Gives column
  int y = index / width; // Gives row

  int red = clamp(convolution(pixels, x, y, GAUSSIAN_FILTER, GAUSSIAN_SIZE, RED,
                              height, width) /
                  GAUSSIAN_SUM);
  int green = clamp(convolution(pixels, x, y, GAUSSIAN_FILTER, GAUSSIAN_SIZE,
                                GREEN, height, width) /
                    GAUSSIAN_SUM);
  int blue = clamp(convolution(pixels, x, y, GAUSSIAN_FILTER, GAUSSIAN_SIZE,
                               BLUE, height, width) /
                   GAUSSIAN_SUM);
  newPixels[index] = createPixel(red, green, blue);
}

__kernel void sobelEdgeDetect(__global int *pixels, __global int *newPixels,
                              const int width, const int height,
                              const int edgeThreshold) {
  int index = get_global_id(0);
  int x = index % width; // Gives column
  int y = index / width; // Gives row
  int BLACK = 0;
  int WHITE = createPixel(255, 255, 255);

  int redVertical = convolution(pixels, x, y, SOBEL_VERTICAL_FILTER, SOBEL_SIZE,
                                RED, height, width);
  int greenVertical = convolution(pixels, x, y, SOBEL_VERTICAL_FILTER,
                                  SOBEL_SIZE, GREEN, height, width);
  int blueVertical = convolution(pixels, x, y, SOBEL_VERTICAL_FILTER,
                                 SOBEL_SIZE, BLUE, height, width);
  int redHorizontal = convolution(pixels, x, y, SOBEL_HORIZONTAL_FILTER,
                                  SOBEL_SIZE, RED, height, width);
  int greenHorizontal = convolution(pixels, x, y, SOBEL_HORIZONTAL_FILTER,
                                    SOBEL_SIZE, GREEN, height, width);
  int blueHorizontal = convolution(pixels, x, y, SOBEL_HORIZONTAL_FILTER,
                                   SOBEL_SIZE, BLUE, height, width);
  int verticalGradient =
      abs(redVertical) + abs(greenVertical) + abs(blueVertical);
  int horizontalGradient =
      abs(redHorizontal) + abs(greenHorizontal) + abs(blueHorizontal);
  // we could take use sqrt(vertGrad^2 + horizGrad^2), but simple addition
  // catches most edges.

  int totalGradient = verticalGradient + horizontalGradient;
  newPixels[y * width + x] = totalGradient >= edgeThreshold
                                 ? BLACK
                                 : WHITE; // we colour the edges black
}

__kernel void reduceColours(__global int *oldPixels, __global int *newPixels,
                            const int width, const int height,
                            const int numColours) {
  int index = get_global_id(0);
  int x = index % width; // Gives column
  int y = index / width; // Gives row

  int rgb = oldPixels[y * width + x];
  int newRed = quantizeColour(red(rgb), numColours);
  int newGreen = quantizeColour(green(rgb), numColours);
  int newBlue = quantizeColour(blue(rgb), numColours);
  int newRGB = createPixel(newRed, newGreen, newBlue);
  newPixels[y * width + x] = newRGB;
}

__kernel void mergeMask(__global int *maskPixels, __global int *photoPixels,
                        __global int *newPixels, const int maskColour,
                        const int width) {
  int index = get_global_id(0);
  if (maskPixels[index] == maskColour) {
    newPixels[index] = photoPixels[index];
  } else {
    newPixels[index] = maskPixels[index];
  }
}
