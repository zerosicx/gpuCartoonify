// Guassian Blur kernel
__kernel void gaussianBlur(__global int *pixels, __global int *newPixels,
                           const int width, const int height) {
    int x = get_global_id(0) % width; // Gives column
    int y = get_global_id(0) / width; // Gives row
    int red = 1;
    int green = 1;
    int blue = 1;
    int newPixel = createPixel(red, green, blue);
    newPixel[y * width + x] = newPixel;
}

__kernel void sobelEdgeDetect(__global int *pixels, __global int *newPixels,
                              const int width, const int height, const int edgeThreshold) {

}


__kernel void reduceColours(__global int *oldPixels, __global int *newPixels,
		                    const int width, const int height, const int numColours) {

}

__kernel void mergeMask(__global int *maskPixels, __global int *photoPixels, __global int *newPixels,
		                const int maskColour, const int width) {

}

//************** UTILITY AND HELPERS ****************

int[] GAUSSIAN_FILTER = {
        2, 4, 5, 4, 2, // sum=17
        4, 9, 12, 9, 4, // sum=38
        5, 12, 15, 12, 5, // sum=49
        4, 9, 12, 9, 4, // sum=38
        2, 4, 5, 4, 2  // sum=17
};

double GAUSSIAN_SUM = 159.0;

// Minimum of 0 and maximum if 255
void clamp(int val){

}

// Construct an integer with the different colour components in RGB
int createPixel(int red, int green, int blue){

}

// Multiplies the filter matrix by the colour values of the pixels around the image, returning a resulting integer value.
int convolution(int xCentre, int yCentre, int[] filter, int colour){

}

// Wraps overflows above and below the size of the image/matrix
int wrap(int pos, int size){

}



