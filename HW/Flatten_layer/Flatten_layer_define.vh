/*******************************************************************************
* Layer 2 CNN Configuration Parameters
* Purpose: Define architecture parameters for the second convolutional layer
* Description: Processes feature maps from previous layer with 8 new filters
*******************************************************************************/

parameter   INPUT_CHANNELS         = 4;    // Number of input channels (from previous layer)
parameter   OUTPUT_CHANNELS        = 8;    // Number of output channels. 8 filters
parameter   KERNEL_WIDTH           = 3;    // Kernel width
parameter   KERNEL_HEIGHT          = 3;    // Kernel height
parameter   PADDING_SIZE           = 0;    // No padding
parameter   STRIDE_SIZE            = 1;    // Stride size
parameter   IMAGE_WIDTH            = 14;   // Input feature map width
parameter   IMAGE_HEIGHT           = 14;   // Input feature map height

/*******************************************************************************
* Bitwidth Parameter Definitions
* Purpose: Configure bitwidths for weights, feature maps, biases, and accumulators
* Description: Controls precision and hardware resource usage for CNN computation
*******************************************************************************/

parameter   WEIGHT_BITWIDTH        = 8;    // Weight bitwidth
parameter   FEATURE_BITWIDTH       = 8;    // Input feature map bitwidth
parameter   KERNEL_ACCUM_BITWIDTH  = 20;   // Kernel operation accumulator bitwidth
parameter   CHANNEL_ACCUM_BITWIDTH = 24;   // Channel accumulation accumulator bitwidth
parameter   BIAS_BITWIDTH          = 16;   // Bias bitwidth