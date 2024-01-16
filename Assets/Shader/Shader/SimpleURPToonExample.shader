Shader "TToon/SimpleURPToonExample"
{
    Properties
    {
        [Header(Base Color)]
        [MainColor]_BaseColor("_BaseColor", Color) = (1,1,1,1)
        [MainTexture]_MainTex("_MainTex", 2D) = "white" {}
        [Header(Shade Color)]
        [MainColor]_ShadeColor("_ShadeColor", Color) = (0.1,0.1,0.1,1)
        [MainTexture]_ShadeTexture("_ShadeTexture", 2D) = "white" {}

        [Header(Alpha)]
        [Toggle]_UseAlphaClipping("_UseAlphaClipping", Float) = 1
        _Cutoff("_Cutoff (Alpha Cutoff)", Range(0.0, 1.0)) = 0.1
        _VColBlendMode("_VColBlendMode, ", Range(0,1)) = 0

        [Header(Lighting)]
        _IndirectLightConstColor("_IndirectLightConstColor", Color) = (0.0,0.0,0.0,1)
        _IndirectLightMultiplier("_IndirectLightMultiplier", Range(0,1)) = 0.1
        _DirectLightMultiplier("_DirectLightMultiplier", Range(0,1)) = 1.0
        _CelShadeMidPoint("_CelShadeMidPoint", Range(-1,1)) = 0.3
        _CelShadeSoftness("_CelShadeSoftness", Range(0,1)) = 0.1

        [Header(Shadow mapping)]
        _ReceiveShadowMappingAmount("_ReceiveShadowMappingAmount", Range(0,1)) = 0.5

        [Header(Emission)]
        [Toggle]_UseEmission("_UseEmission (on/off completely)", Float) = 1
        [HDR] _EmissionColor("_EmissionColor", Color) = (0,0,0)
        _EmissionMap("_EmissionMap", 2D) = "white" {}
        _EmissionMapChannelMask("_EmissionMapChannelMask", Vector) = (1,1,1,1)

        [Header(Outline)]
        _OutlineWidth("_OutlineWidth (Object Space)", Range(0, 10)) = 0.0
        _OutlineColor("_OutlineColor", Color) = (0.0,0.0,0.0,1)
        [NoScaleOffset] _OutlineWidthTexture ("Outline Width Tex", 2D) = "white" {}
        
        [Header(Culling)]
        [KeywordEnum(None, Front, Back)] _Cull("Culling", Int) = 0
    }
    SubShader
    {       
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {               
            Name "Forward Rendering"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            Cull[_Cull]
            HLSLPROGRAM
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            // Unity defined keywords
            #pragma multi_compile_fog
            #include "SimpleURPToonExample_Shared.hlsl"

            #pragma vertex BaseColorPassVertex
            #pragma fragment BaseColorPassFragment

            Varyings BaseColorPassVertex(Attributes input)
            {
                VertexShaderWorkSetting setting = GetDefaultVertexShaderWorkSetting();

                return VertexShaderWork(input, setting);
            }

            half4 BaseColorPassFragment(Varyings input) : SV_TARGET
            {
                return ShadeFinalColor(input, false);
            }

            ENDHLSL
        }
        // OutLine
        Pass 
        {
            Name "Outline"
            
            Cull Front

            HLSLPROGRAM

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog

            #include "SimpleURPToonExample_Shared.hlsl"

            #pragma vertex OutlinePassVertex
            #pragma fragment OutlinePassFragment

            Varyings OutlinePassVertex(Attributes input)
            {
                VertexShaderWorkSetting setting = GetDefaultVertexShaderWorkSetting();
                setting.isOutline = true;

                return VertexShaderWork(input, setting);
            }

            half4 OutlinePassFragment(Varyings input) : SV_TARGET
            {
                return ShadeFinalColor(input, true);
            }

            ENDHLSL
        }
        // ShadowCaster
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}
            ColorMask 0

            HLSLPROGRAM

            #pragma vertex ShadowCasterPassVertex
            #pragma fragment ShadowCasterPassFragment

            #include "SimpleURPToonExample_Shared.hlsl"

            Varyings ShadowCasterPassVertex(Attributes input)
            {
                VertexShaderWorkSetting setting = GetDefaultVertexShaderWorkSetting();

                setting.isOutline = false; 
                setting.applyShadowBiasFixToHClipPos = true;

                return VertexShaderWork(input, setting);
            }

            half4 ShadowCasterPassFragment(Varyings input) : SV_TARGET
            {
                return BaseColorAlphaClipTest(input);
            }

            ENDHLSL
        }
        // DepthOnly
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}
            Cull[_Cull]
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex DepthOnlyPassVertex
            #pragma fragment DepthOnlyPassFragment

            #include "SimpleURPToonExample_Shared.hlsl"
            Varyings DepthOnlyPassVertex(Attributes input)
            {
                VertexShaderWorkSetting setting = GetDefaultVertexShaderWorkSetting();

                setting.isOutline = true;

                return VertexShaderWork(input, setting);
            }

            half4 DepthOnlyPassFragment(Varyings input) : SV_TARGET
            {
                return BaseColorAlphaClipTest(input);
            }

            ENDHLSL
        }
        // GBuffer
        Pass
        {
            Name "GBuffer"
            Tags {"LightMode" = "UniversalGBuffer" }

            ZWrite [_ZWrite]
            ZTest LEqual
            Cull [_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ _SPECGLOSSMAP _SPECULAR_COLOR
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_LAYERS

            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
            #pragma multi_compile_fragment _ _RENDER_PASS_ENABLED

            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex LitPassVertexSimple
            #pragma fragment LitPassFragmentSimple
            #define BUMP_SCALE_NOT_SUPPORTED 1

            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitGBufferPass.hlsl"
            ENDHLSL
        }
    }
}
