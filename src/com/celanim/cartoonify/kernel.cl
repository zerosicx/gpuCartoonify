//************** UTILITY AND HELPERS ****************

 int GAUSSIAN_FILTER[] = {
    2, 4,  5,  4,  2, // sum=17
    4, 9,  12, 9,  4, // sum=38
    5, 12, 15, 12, 5, // sum=49
    4, 9,  12, 9,  4, // sum=38
    2, 4,  5,  4,  2  // sum=17
};

 double GAUSSIAN_SUM = 159.0;
 int GAUSSIAN_SIZE = 5;
 int COLOUR_BITS = 8;
 int COLOUR_MASK = 255;
 int RED = 2;
 int GREEN = 1;
 int BLUE = 0;

// Minimum of 0 and maximum if 255
int clamp(double value) {
  int result = (int) (value + 0.5); // round to nearest integer
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

int convolution(__global int *pixels, int xCentre, int yCentre,
                 int *filter, int filterSize, int colour, int height,
                int width, int index) {
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

__kernel void gaussianBlur(__global int *pixels, __global int *newPixels,
                           const int width, const int height) {
  int index = get_global_id(0);
  int x = index % width; // Gives column
  int y = index / width; // Gives row

  int red = clamp(convolution(pixels, x, y, GAUSSIAN_FILTER, GAUSSIAN_SIZE, RED,
                              height, width, index) /
                  GAUSSIAN_SUM);
  int green = clamp(convolution(pixels, x, y, GAUSSIAN_FILTER, GAUSSIAN_SIZE,
                                GREEN, height, width, index) /
                    GAUSSIAN_SUM);
  int blue = clamp(convolution(pixels, x, y, GAUSSIAN_FILTER, GAUSSIAN_SIZE,
                               BLUE, height, width, index) /
                   GAUSSIAN_SUM);
  newPixels[index] = createPixel(red, green, blue);
}

__kernel void sobelEdgeDetect(__global int *pixels, __global int *newPixels,
                              const int width, const int height,
                              const int edgeThreshold) {}

__kernel void reduceColours(__global int *oldPixels, __global int *newPixels,
                            const int width, const int height,
                            const int numColours) {}

__kernel void mergeMask(__global int *maskPixels, __global int *photoPixels,
                        __global int *newPixels, const int maskColour,
                        const int width) {}
