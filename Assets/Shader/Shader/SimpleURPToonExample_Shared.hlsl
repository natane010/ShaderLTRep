// OutLine
#ifndef SimpleURPToonExample_Shared_Include
#define SimpleURPToonExample_Shared_Include
#ifndef _MAIN_LIGHT_SHADOWS
#define _MAIN_LIGHT_SHADOWS
#endif
#ifndef _ADDITIONAL_LIGHTS
#define _ADDITIONAL_LIGHTS
#endif
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float3 positionOS   : POSITION;
    half3 normalOS     : NORMAL;
    half4 tangentOS    : TANGENT;
    float2 uv           : TEXCOORD0;
    //uint instanceId : SV_InstanceID;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv                       : TEXCOORD0;
    float4 positionWSAndFogFactor   : TEXCOORD2; 
    half3 normalWS                 : TEXCOORD3;

#ifdef _MAIN_LIGHT_SHADOWS
    float4 shadowCoord              : TEXCOORD6; 
#endif
    float4 positionCS               : SV_POSITION;
    UNITY_VERTEX_OUTPUT_STEREO
};

sampler2D _MainTex;
sampler2D _ShadeTexture;
sampler2D _EmissionMap;
sampler2D _OutlineWidthTexture;

CBUFFER_START(UnityPerMaterial)

    // base color
    float4 _MainTex_ST;
    half4 _BaseColor;
    float4 _ShadeTexture_ST;
    half4 _ShadeColor;

    // alpha
    float _UseAlphaClipping;
    half _Cutoff;

    //lighting
    half3 _IndirectLightConstColor;
    half _IndirectLightMultiplier;
    half _DirectLightMultiplier;
    half _CelShadeMidPoint;
    half _CelShadeSoftness;

    // shadow mapping
    half _ReceiveShadowMappingAmount;

    //emission
    float _UseEmission;
    half3 _EmissionColor;
    half3 _EmissionMapChannelMask;
    float4 _EmissionMap_ST;

    // outline
    float _OutlineWidth;
    half3 _OutlineColor;
    float4 _OutlineWidthTexture_ST;


CBUFFER_END

half3 _LightDirection;

struct SurfaceData2
{
    half3 albedo;
    half3 shade;
    half  alpha;
    half3 emission;
};
struct LightingData2
{
    half3 normalWS;
    float3 positionWS;
    half3 viewDirectionWS;
    float4 shadowCoord;
};


struct VertexShaderWorkSetting
{
    bool isOutline;
    bool applyShadowBiasFixToHClipPos;
};
VertexShaderWorkSetting GetDefaultVertexShaderWorkSetting()
{
    VertexShaderWorkSetting output;
    output.isOutline = false;
    output.applyShadowBiasFixToHClipPos = false;
    return output;
}


float3 TransformPositionOSToOutlinePositionOS(Attributes input)
{
    float3 outlineNormalOSUnitVector = normalize(input.normalOS); 
    return input.positionOS + outlineNormalOSUnitVector * (_OutlineWidth * 0.002f); 
}

Varyings VertexShaderWork(Attributes input, VertexShaderWorkSetting setting)
{
    Varyings output;

    UNITY_SETUP_INSTANCE_ID(input);
    output.uv = float2(0, 0);
    output.normalWS = float3(0, 0, 0);
    output.positionWSAndFogFactor = float4(0, 0, 0, 0);
#ifdef _MAIN_LIGHT_SHADOWS
    output.shadowCoord = float4(0, 0, 0, 0);
#endif
    output.positionCS = float4(0, 0, 0, 0);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    if(setting.isOutline)
    {
        input.positionOS = TransformPositionOSToOutlinePositionOS(input);
    }

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);

    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

    output.uv = TRANSFORM_TEX(input.uv, _MainTex);

    output.positionWSAndFogFactor = float4(vertexInput.positionWS, fogFactor);
    output.normalWS = vertexNormalInput.normalWS;

#ifdef _MAIN_LIGHT_SHADOWS
    output.shadowCoord = GetShadowCoord(vertexInput);
#endif

    output.positionCS = vertexInput.positionCS;

    if(setting.applyShadowBiasFixToHClipPos)
    {
        float3 positionWS = vertexInput.positionWS;
        float3 normalWS = vertexNormalInput.normalWS;
        float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS - max(0, input.positionOS.y) * _LightDirection, normalWS, _LightDirection));

        #if UNITY_REVERSED_Z
        positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
        #else
        positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
        #endif
        output.positionCS = positionCS;
    } 

    return output;
}

half4 GetFinalBaseColor(Varyings input)
{
    return tex2D(_MainTex, input.uv) * _BaseColor;
}
half4 GetFinalShadeColor(Varyings input)
{
    return tex2D(_ShadeTexture, input.uv) * _ShadeColor;
}
half3 GetFinalEmissionColor(Varyings input)
{
    if(_UseEmission)
    {
        return tex2D(_EmissionMap, input.uv).rgb * _EmissionColor.rgb * _EmissionMapChannelMask;
    }
    return 0;
}
void DoClipTestToTargetAlphaValue(half alpha) 
{
    if(_UseAlphaClipping)
    {   
        clip(alpha - _Cutoff);
    }
}
SurfaceData2 InitializeSurfaceData(Varyings input)
{
    SurfaceData2 output;

    float4 baseColorFinal = GetFinalBaseColor(input);
    float4 shadeColorFinal = GetFinalShadeColor(input);
    output.albedo = baseColorFinal.rgb;
    output.shade = shadeColorFinal.rgb;
    output.alpha = baseColorFinal.a;
    DoClipTestToTargetAlphaValue(output.alpha);

    output.emission = GetFinalEmissionColor(input);

    return output;
}

#include "SimpleURPToonExample_LightingEquation.hlsl"

half3 ShadeAllLights(SurfaceData2 surfaceData, LightingData2 lightingData)
{
    Light mainLight;
#ifdef _MAIN_LIGHT_SHADOWS
    mainLight = GetMainLight(lightingData.shadowCoord);
#else
    mainLight = GetMainLight();
#endif

    half3 indirectResult = ShadeGI(surfaceData, lightingData, mainLight);

    half3 mainLightResult = ShadeMainLight(surfaceData, lightingData, mainLight);
    half3 additionalLightSumResult = 0;

#ifdef _ADDITIONAL_LIGHTS
    int additionalLightsCount = GetAdditionalLightsCount();
    for (int i = 0; i < additionalLightsCount; ++i)
    {
        Light light = GetAdditionalLight(i, lightingData.positionWS);

        additionalLightSumResult += ShadeAdditionalLight(surfaceData, lightingData, light);
    }
#endif
    half3 emissionResult = surfaceData.emission;

    return CompositeAllLightResults(indirectResult, mainLightResult, additionalLightSumResult, emissionResult);
}

half3 ConvertSurfaceColorToOutlineColor(half3 originalSurfaceColor)
{
    return originalSurfaceColor * _OutlineColor;
}

half4 ShadeFinalColor(Varyings input, bool isOutline)
{
    SurfaceData2 surfaceData = InitializeSurfaceData(input);

    LightingData2 lightingData;
    lightingData.positionWS = input.positionWSAndFogFactor.xyz;
    lightingData.viewDirectionWS = SafeNormalize(GetCameraPositionWS() - lightingData.positionWS);  
    lightingData.normalWS = input.normalWS;

#ifdef _MAIN_LIGHT_SHADOWS
    lightingData.shadowCoord = input.shadowCoord;
    half shadowAttenutation = MainLightRealtimeShadow(input.shadowCoord);
#endif
 
    half3 color = ShadeAllLights(surfaceData, lightingData);

    if(isOutline)
    {
        color = ConvertSurfaceColorToOutlineColor(color);

#ifdef _MAIN_LIGHT_SHADOWS
        color = lerp(color, _IndirectLightConstColor * _IndirectLightMultiplier * surfaceData.shade, (1.0 - shadowAttenutation) * _ReceiveShadowMappingAmount);
#endif

        half fogFactor = input.positionWSAndFogFactor.w;
        color = MixFog(color, fogFactor);

        half3 outMask = tex2D(_OutlineWidthTexture, input.uv).rgb;

        half alpha = max(outMask.r, max(outMask.g, outMask.b));

        return half4(color,alpha);
    }
    else
    {
#ifdef _MAIN_LIGHT_SHADOWS
        color = lerp(color, _IndirectLightConstColor * _IndirectLightMultiplier * surfaceData.shade, (1.0 - shadowAttenutation) * _ReceiveShadowMappingAmount);
#endif
        half fogFactor = input.positionWSAndFogFactor.w;
        color = MixFog(color, fogFactor);

        return half4(color,1);
    }

}

half4 BaseColorAlphaClipTest(Varyings input)
{
    DoClipTestToTargetAlphaValue(GetFinalBaseColor(input).a);
    return 0;
}

#endif
