//************** UTILITY AND HELPERS ****************

__constant int GAUSSIAN_FILTER[] = {
    2, 4,  5,  4,  2, // sum=17
    4, 9,  12, 9,  4, // sum=38
    5, 12, 15, 12, 5, // sum=49
    4, 9,  12, 9,  4, // sum=38
    2, 4,  5,  4,  2  // sum=17
};

__constant double GAUSSIAN_SUM = 159.0;
__constant int GAUSSIAN_SIZE = 25;
__constant int COLOUR_BITS = 8;
__constant int COLOUR_MASK = (1 << COLOUR_BITS) - 1;
__constant int RED = 2;
__constant int GREEN = 1;
__constant int BLUE = 0;

// Minimum of 0 and maximum if 255
int clamp(double val) {
  int value = (int)(val + 0.5);
  if (value < 0) {
    return 0;
  } else if (value > 255) {
    return 255;
  }
  return value;
}

// Construct an integer with the different colour components in RGB
int createPixel(int red, int green, int blue) {
  // Construct the pixel value
  int pixel = (red << (2 * COLOUR_BITS)) + (green << COLOUR_BITS) + blue;
  return pixel;
}

// Wraps overflows above and below the size of the image/matrix
int wrap(int pos, int size) {
  if (pos < 0) {
    pos = size + (pos % size);
  } else if (pos >= size) {
    pos %= size;
  }
  return pos;
}

int colourValue(int pixel, int colour) {
  return (pixel >> (colour * COLOUR_BITS)) & COLOUR_MASK;
}

// Multiplies the filter matrix by the colour values of the pixels around the
// image, returning a resulting integer value.
// Apply the given N*N filter around the pixel (xCentre, yCentre)
int convolution(__global int *pixels, int xCentre, int yCentre,
                __constant int filter[], int filterSize, int colour, int height,
                int width) {
  int sum = 0;
  const int filterHalf = filterSize / 2;
  for (int filterY = 0; filterY < filterSize; filterY++) {
    int y = wrap(yCentre + filterY - filterHalf, height);
    for (int filterX = 0; filterX < filterSize; filterX++) {
      int x = wrap(xCentre + filterX - filterHalf, width);
      int rgb =
          pixels[y * width + x]; // Assuming pixel function is defined elsewhere
      int filterVal = filter[filterY * filterSize + filterX];
      sum += colourValue(rgb, colour) *
             filterVal; // Assuming colourValue function is defined elsewhere
    }
  }
//     printf("convolution(%d, %d) = %d\n", xCentre, yCentre, sum);
  return sum;
}

__kernel void gaussianBlur(__global int *pixels, __global int *newPixels,
                           const int width, const int height) {
  int index = get_global_id(0);
    printf("%d \n", index);
  int x = index % width; // Gives column
  int y = index / width; // Gives row

  int red = clamp(convolution(pixels, x, y, GAUSSIAN_FILTER, GAUSSIAN_SIZE, RED,
                              width, height) /
                  GAUSSIAN_SUM);
  int green = clamp(convolution(pixels, x, y, GAUSSIAN_FILTER, GAUSSIAN_SIZE,
                                GREEN, width, height) /
                    GAUSSIAN_SUM);
  int blue = clamp(convolution(pixels, x, y, GAUSSIAN_FILTER, GAUSSIAN_SIZE,
                               BLUE, width, height) /
                   GAUSSIAN_SUM);
  //   int pix = createPixel(red, green, blue);
  //   printf(red);
  newPixels[index] = 100;
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
