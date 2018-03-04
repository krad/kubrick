#include <metal_stdlib>
using namespace metal;

kernel void verticalCenter(texture2d<float, access::sample> input [[texture(0)]],
                           texture2d<float, access::write> output [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]])
{
    const uint dstMiddle = output.get_height() / 2;
    const uint srcMiddle = input.get_height() / 2;
    const uint2 loc      = uint2(gid.x, (gid.y + dstMiddle) - srcMiddle);
    
    const float4 color   = input.read(gid);
    output.write(color, loc);
}

kernel void horizontalCenter(texture2d<float, access::sample> input [[texture(0)]],
                             texture2d<float, access::write> output [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]])
{
    const uint dstMiddle = output.get_width() / 2;
    const uint srcMiddle = input.get_width() / 2;
    const uint2 loc      = uint2((gid.x + dstMiddle) - srcMiddle, gid.y);
    
    const float4 color   = input.read(gid);
    output.write(color, loc);
}

kernel void flip(texture2d<float, access::sample> input [[texture(0)]],
                 texture2d<float, access::write> output [[texture(1)]],
                 uint2 gid [[thread_position_in_grid]])
{
    float4 color = input.read(gid);
    gid.y        = input.get_height() - gid.y;
    output.write(color, gid);
}



kernel void passthrough(texture2d<float, access::sample> input [[texture(0)]],
                        texture2d<float, access::write> output [[texture(1)]],
                        uint2 gid [[thread_position_in_grid]])
{
    const float4 color   = input.read(gid);
    output.write(color, gid);
}
