//
//  MatrixMultiply.metal
//  MatrixMultiply
//
//  Created by fadi on 13/07/2021.
//

#include <metal_stdlib>

#include "constants.h"

using namespace metal;


kernel void FUNCTION_NAME(device const float *matrix1 [[buffer(MATRIX_1_POSITION)]],
                          device const float *matrix2 [[buffer(MATRIX_2_POSITION)]],
                          device float *result [[buffer(RESULT_MATRIX_POSITION)]],
                          device const uint32_t *sizes [[buffer(SIZES_POSITION)]],
                          uint2 gid [[thread_position_in_grid]]) {
    float sum = 0.0f;
    uint32_t matrix1Width = sizes[0];
    uint32_t matrix1Height = sizes[1];
    uint32_t matrix2Width = sizes[2];
    uint32_t matrix2Height = sizes[3];
    uint xxx = gid[0];
    uint yyy = gid[1];
    if ((xxx >= matrix2Width) || (yyy >= matrix1Height)) {
        return;
    }
    for(uint i=0;i<matrix1Width;i++)
    {
//        sum = yyy; //matrix1[(y * matrix1Width) + x];
        
//        sum += ((matrix1[(yyy * matrix1Width) + i]) * (matrix2[(i * matrix2Width) + xxx]));
        //        sum += (matrix1[(xxx * matrix1Width) + i]);
        //        sum += (matrix2[(i * matrix2Width) + yyy]);
        sum += ((matrix1[(yyy * matrix1Width) + i]) * (matrix2[(i * matrix2Width) + xxx]));
    }
    
    result[(yyy * matrix2Width) + xxx] = sum;
}
