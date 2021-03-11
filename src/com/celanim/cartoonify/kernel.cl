// Guassian Blur kernel
__kernel void gaussianBlur(__global int *pixels, __global int *newPixels,
                           const int width, const int height) {

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

