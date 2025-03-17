/*******************************************************************************
* Parameter Definitions
* Purpose: Configure CNN module dimensions and bitwidths
* Description: Defines image, kernel, and channel sizes as well as bitwidths
*******************************************************************************/

`define   INPUT_CHANNELS         1    // Number of input channels
`define   OUTPUT_CHANNELS        4    // Number of output channels. 4 filters
`define   KERNEL_WIDTH           3    // Kernel width
`define   KERNEL_HEIGHT          3    // Kernel height
`define   PADDING_SIZE           1    // Padding size
`define   STRIDE_SIZE            1    // Stride size
`define   IMAGE_WIDTH            28   // Input image width
`define   IMAGE_HEIGHT           28   // Input image height
`define   PADDED_WIDTH           30   // `IMAGE_WIDTH + 2*`PADDING_SIZE;
`define   PADDED_HEIGHT          30   // `IMAGE_HEIGHT + 2*`PADDING_SIZE;
/*******************************************************************************
* Bitwidth Parameter Definitions
* Purpose: Configure bitwidths for weights, feature maps, biases, and accumulators
* Description: Controls precision and hardware resource usage for CNN computation
*******************************************************************************/

`define   WEIGHT_BITWIDTH         8    // Weight bitwidth
`define   FEATURE_BITWIDTH        8    // Input feature map bitwidth
`define   KERNEL_MUL_BITWIDTH     16   // WEIGHT * FEATURE
`define   KERNEL_ACCUM_BITWIDTH   19   // Kernel operation accumulator bitwidth
`define   CHANNEL_ACCUM_BITWIDTH  24   // Channel accumulation accumulator bitwidth
`define   BIAS_BITWIDTH           16   // Bias bitwidth