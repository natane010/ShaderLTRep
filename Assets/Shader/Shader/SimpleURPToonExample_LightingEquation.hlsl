// Light
#ifndef SimpleURPToonExample_Include
#define SimpleURPToonExample_Include

half3 ShadeGIDefaultMethod(SurfaceData2 surfaceData, LightingData2 lightingData)
{
    half3 averageSH = SampleSH(0);

    return surfaceData.albedo * (_IndirectLightConstColor + averageSH * _IndirectLightMultiplier);   
}

half3 ShadeSingleLightDefaultMethod(SurfaceData2 surfaceData, LightingData2 lightingData, Light light)
{
    half3 N = lightingData.normalWS;
    half3 L = light.direction;
    half3 V = lightingData.viewDirectionWS;
    half3 H = normalize(L+V);

    half NoL = dot(N,L);

    half lightAttenuation = 1;

    lightAttenuation *= lerp(1,light.shadowAttenuation,_ReceiveShadowMappingAmount);

    lightAttenuation *= min(2,light.distanceAttenuation); 

    lightAttenuation *= smoothstep(_CelShadeMidPoint-_CelShadeSoftness,_CelShadeMidPoint+_CelShadeSoftness, NoL);

    lightAttenuation *= _DirectLightMultiplier;

    return surfaceData.albedo * light.color * lightAttenuation;
}

half3 CompositeAllLightResultsDefaultMethod(half3 indirectResult, half3 mainLightResult, half3 additionalLightSumResult, half3 emissionResult)
{
    return indirectResult + mainLightResult + additionalLightSumResult + emissionResult;
}

half3 ShadeGIYourMethod(SurfaceData2 surfaceData, LightingData2 lightingData, Light light)
{
    half3 averageSH = SampleSH(0);

    return surfaceData.shade * (_IndirectLightConstColor + averageSH * _IndirectLightMultiplier);
}
half3 ShadeMainLightYourMethod(SurfaceData2 surfaceData, LightingData2 lightingData, Light light)
{
    half3 N = lightingData.normalWS;
    half3 L = light.direction;
    half3 V = lightingData.viewDirectionWS;
    half3 H = normalize(L + V);

    half NoL = dot(N, L);

    half lightAttenuation = 1;

    lightAttenuation *= lerp(1, light.shadowAttenuation, _ReceiveShadowMappingAmount);
    lightAttenuation *= min(2, light.distanceAttenuation); 

    lightAttenuation *= smoothstep(_CelShadeMidPoint - _CelShadeSoftness, _CelShadeMidPoint + _CelShadeSoftness, NoL);

    lightAttenuation *= _DirectLightMultiplier;

    return light.color * lerp(surfaceData.shade, surfaceData.albedo, lightAttenuation);
}
half3 ShadeAllAdditionalLightsYourMethod(SurfaceData2 surfaceData, LightingData2 lightingData, Light light)
{
    return ShadeSingleLightDefaultMethod(surfaceData, lightingData, light);
}
half3 CompositeAllLightResultsYourMethod(half3 indirectResult, half3 mainLightResult, half3 additionalLightSumResult, half3 emissionResult)
{
    return indirectResult + mainLightResult + additionalLightSumResult + emissionResult;
}

half3 ShadeGI(SurfaceData2 surfaceData, LightingData2 lightingData, Light light)
{
    return ShadeGIYourMethod(surfaceData, lightingData, light);
}
half3 ShadeMainLight(SurfaceData2 surfaceData, LightingData2 lightingData, Light light)
{
    return ShadeMainLightYourMethod(surfaceData, lightingData, light);
}
half3 ShadeAdditionalLight(SurfaceData2 surfaceData, LightingData2 lightingData, Light light)
{
    return ShadeAllAdditionalLightsYourMethod(surfaceData, lightingData, light);
}
half3 CompositeAllLightResults(half3 indirectResult, half3 mainLightResult, half3 additionalLightSumResult, half3 emissionResult)
{
    return CompositeAllLightResultsYourMethod(indirectResult, mainLightResult, additionalLightSumResult, emissionResult);
}

#endif
