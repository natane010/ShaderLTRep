Shader "Unlit/SampleRim"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RimColor("Rim Color", Color) = (0,1,1,1)
        _RimPower("Rim Power", Range(0,1)) = 0.4
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 world_pos : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _RimColor;
            float _RimPower;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                //worldposの取得
                o.world_pos = mul(unity_ObjectToWorld, v.vertex).xyz;
                //法線を取得
                o.normalDir = UnityObjectToWorldNormal(v.normal);

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                //カメラのベクトルを計算
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.world_pos.xyz);
                //法線とカメラのベクトルの内積を計算し、補間値を算出
                half rim = 1.0 - saturate(dot(viewDirection, i.normalDir));

                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                col = lerp(col, _RimColor, rim * _RimPower);

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
