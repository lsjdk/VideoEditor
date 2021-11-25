//
//  shader.metal
//  ParticleAdjuster
//
//  Created by chioacm on 2021/11/9.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOutput {
   float4 position [[position]];
   float2 textureCoord;
};


vertex VertexOutput vertexShader(uint vid [[vertex_id]],
                                 const constant float4 *vertexArray [[buffer(0)]]
                                 ){
   float4 curtVertex = vertexArray[vid];
   VertexOutput out;
   out.position = float4(curtVertex.x , curtVertex.y , 0 , 1);
   out.textureCoord = float2(curtVertex.z , curtVertex.w);
   return out;
}



// 滤色
float4 screenBlend(float4 under, float4 over) {
   float3 uRGB = under.rgb;
   float ua = under.a;
   float3 oRGB = over.rgb;
   float oa = over.a;
   float3 rgb = oRGB + uRGB - oRGB * uRGB;
   float a = oa + ua - oa * ua;
   return float4(rgb, a);
}

// 饱和度
float4 saturationFunc(float4 color, float degree) {
   float3 luminanceWeighting = float3(0.2125, 0.7154, 0.0721);
   float luminance = dot(color.rgb, luminanceWeighting);
   float3 greyScaleColor = float3(luminance);
   return float4(mix(greyScaleColor, color.rgb, degree), color.a);
}
float3 saturationFunc(float3 color, float degree) {
   float3 luminanceWeighting = float3(0.2125, 0.7154, 0.0721);
   float luminance = dot(color.rgb, luminanceWeighting);
   float3 greyScaleColor = float3(luminance);
   return mix(greyScaleColor, color.rgb, degree);
}


// 对比度
float4 contrastFunc(float4 color, float degree) {
   return float4(color.rgb * pow(2.0, degree), color.a);
}
float3 contrastFunc(float3 color, float degree) {
   return color.rgb * pow(2.0, degree);
}
// 亮度
float4 brightnessFunc(float4 color, float degree) {
   return float4(((color.rgb - float3(0.5)) * degree + float3(0.5)), color.a);
}
float3 brightnessFunc(float3 color, float degree) {
   return (color.rgb - float3(0.5)) * degree + float3(0.5);
}

// gamma
float3 gammaFunc(float3 color, float gamma) {
   return pow(color.rgb, float3(1.0/gamma));
}

fragment float4 fragmentShader(VertexOutput in [[stage_in]],
                               constant float &saturation [[buffer(0)]],
                               constant float &contrast [[buffer(1)]],
                               constant float &brightness [[buffer(2)]],
                               constant float &gamma [[buffer(3)]],
                               constant float &alpha [[buffer(4)]],
                               constant bool &add [[buffer(5)]],
                               texture2d<float> colorTexture [[texture(0)]],
                               sampler tureSampler [[sampler(0)]]
                               ){
   float4 color = colorTexture.sample(tureSampler, in.textureCoord);
   
   float ma = max3(color.r, color.g, color.b);

   
   float3 mc = add ? float3(1.0 - ma) + color.rgb : color.rgb;

   float3 gammaColor = gammaFunc(mc, gamma);

   float3 cs = saturationFunc(gammaColor, saturation);
   float3 cc = contrastFunc(cs, contrast);
   float3 cb = brightnessFunc(cc, brightness);
   
   return float4(cb, ma * alpha);
}







fragment float4 fragment_towShader( VertexOutput in [[ stage_in ]],
                                   texture2d<float> colorTexture0 [[texture(0)]],
                                   texture2d<float> colorTexture1 [[texture(1)]],
                                   sampler tureSampler [[sampler(0)]]
                                   ){
   
   
   float4 color0 = colorTexture0.sample(tureSampler, in.textureCoord);
   float4 color1 = colorTexture1.sample(tureSampler, in.textureCoord);
   
   float4 finalColor = float4(color0.x*0.2 + color1.x*0.8,
                              color0.y + color1.y*0.8,
                              color0.z + color1.z*0.8,
                              color0.x < 0.5 ? 0.0 : 1.0);
   
   return finalColor;
   
}
