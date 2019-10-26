---
title: "Cuda - Things to check"
tag:
  - code
  - cuda
  - c++
---

## Tips

<https://devblogs.nvidia.com/cuda-pro-tip-occupancy-api-simplifies-launch-configuration>

{% highlight cpp %}
#include <stdio.h>
#include <cuda_occupancy.h>

__global__ void MyKernel(int *array, int arrayCount) 
{ 
  int idx = threadIdx.x + blockIdx.x * blockDim.x; 
  if (idx < arrayCount) 
  { 
    array[idx] *= array[idx]; 
  } 
} 

void launchMyKernel(int *array, int arrayCount) 
{ 
  int blockSize;   // The launch configurator returned block size 
  int minGridSize; // The minimum grid size needed to achieve the 
                   // maximum occupancy for a full device launch 
  int gridSize;    // The actual grid size needed, based on input size 

  cudaOccupancyMaxPotentialBlockSize( &minGridSize, &blockSize, 
                                      MyKernel, 0, 0); 
  // Round up according to array size 
  gridSize = (arrayCount + blockSize - 1) / blockSize; 

  MyKernel<<< gridSize, blockSize >>>(array, arrayCount); 

  cudaDeviceSynchronize(); 

  // calculate theoretical occupancy
  int maxActiveBlocks;
  cudaOccupancyMaxActiveBlocksPerMultiprocessor( &maxActiveBlocks, 
                                                 MyKernel, blockSize, 
                                                 0);

  int device;
  cudaDeviceProp props;
  cudaGetDevice(&device);
  cudaGetDeviceProperties(&props, device);

  float occupancy = (maxActiveBlocks * blockSize / props.warpSize) / 
                    (float)(props.maxThreadsPerMultiProcessor / 
                            props.warpSize);

  printf("Launched blocks of size %d. Theoretical occupancy: %f\n", 
         blockSize, occupancy);
}
{% endhighlight %}

## C++ wrappers

<https://github.com/eyalroz/cuda-api-wrappers>


## NVRTC

### NVRTC and MDL

<http://on-demand.gputechconf.com/gtc/2017/presentation/s7185-roettger-mank-leveraging-nvrtc-optix-shaders-mdl-materials.pdf>

### YAGAL (Yet Another GPGPU Library)

<https://projekter.aau.dk/projekter/files/281555597/master.pdf>


## NVProf

### Floating point precision

To check if double precision computation are done, we can use the following options with *nvprof*

```
nvprof --metrics inst_fp_32,inst_fp_64 <exe>
```
