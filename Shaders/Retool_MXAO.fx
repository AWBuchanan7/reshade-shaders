//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade 3.0 effect file
// visit facebook.com/MartyMcModding for news/updates
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Ambient Obscurance with Indirect Lighting "MXAO" 3.4.3 by Marty McFly
// CC BY-NC-ND 3.0 licensed.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Preprocessor Settings
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#ifndef MXAO_MIPLEVEL_AO
 #define MXAO_MIPLEVEL_AO		0	//[0 to 2]      Miplevel of AO texture. 0 = fullscreen, 1 = 1/2 screen width/height, 2 = 1/4 screen width/height and so forth. Best results: IL MipLevel = AO MipLevel + 2
#endif

#ifndef MXAO_MIPLEVEL_IL
 #define MXAO_MIPLEVEL_IL		2	//[0 to 4]      Miplevel of IL texture. 0 = fullscreen, 1 = 1/2 screen width/height, 2 = 1/4 screen width/height and so forth.
#endif

#ifndef MXAO_ENABLE_IL
 #define MXAO_ENABLE_IL			0	//[0 or 1]	Enables Indirect Lighting calculation. Will cause a major fps hit.
#endif

#ifndef MXAO_SMOOTHNORMALS
 #define MXAO_SMOOTHNORMALS             0       //[0 or 1]      This feature makes low poly surfaces smoother, especially useful on older games.
#endif

#ifndef MXAO_TWO_LAYER
 #define MXAO_TWO_LAYER                 0       //[0 or 1]      Splits MXAO into two separate layers that allow for both large and fine AO.
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// UI variables
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform int MXAO_GLOBAL_SAMPLE_QUALITY_PRESET <
	ui_type = "combo";
        ui_label = "Sample Quality";
	ui_items = "Very Low\0Low\0Medium\0High\0Very High\0Ultra\0Maximum\0";
	ui_tooltip = "Global quality control, main performance knob. Higher radii might require higher quality.";
> = 2;

uniform float MXAO_SAMPLE_RADIUS <
	ui_type = "drag";
	ui_min = 0.5; ui_max = 20.0;
        ui_label = "Sample Radius";
	ui_tooltip = "Sample radius of MXAO, higher means more large-scale occlusion with less fine-scale details.";
> = 2.5;

uniform float MXAO_SAMPLE_NORMAL_BIAS <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.8;
        ui_label = "Normal Bias";
	ui_tooltip = "Occlusion Cone bias to reduce self-occlusion of surfaces that have a low angle to each other.";
> = 0.2;

uniform float MXAO_GLOBAL_RENDER_SCALE <
	ui_type = "drag";
        ui_label = "Render Size Scale";
	ui_min = 0.50; ui_max = 1.00;
        ui_tooltip = "Factor of MXAO resolution, lower values greatly reduce performance overhead but decrease quality.\n1.0 = MXAO is computed in original resolution\n0.5 = MXAO is computed in 1/2 width 1/2 height of original resolution\n...";
> = 1.0;

uniform float MXAO_SSAO_AMOUNT <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 4.00;
        ui_label = "Ambient Occlusion Amount";
	ui_tooltip = "Intensity of AO effect. Can cause pitch black clipping if set too high.";
> = 1.00;

#if(MXAO_ENABLE_IL != 0)
        uniform float MXAO_SSIL_AMOUNT <
        	ui_type = "drag";
        	ui_min = 0.00; ui_max = 12.00;
                ui_label = "Indirect Lighting Amount";
        	ui_tooltip = "Intensity of IL effect. Can cause overexposured white spots if set too high.";
        > = 4.00;

        uniform float MXAO_SSIL_SATURATION <
        	ui_type = "drag";
        	ui_min = 0.00; ui_max = 3.00;
                ui_label = "Indirect Lighting Saturation";
        	ui_tooltip = "Controls color saturation of IL effect.";
        > = 1.00;
#endif

#if (MXAO_TWO_LAYER != 0)
        uniform float MXAO_SAMPLE_RADIUS_SECONDARY <
           	ui_type = "drag";
           	ui_min = 0.1; ui_max = 1.00;
                   ui_label = "Fine AO Scale";
           	ui_tooltip = "Multiplier of Sample Radius for fine geometry. A setting of 0.5 scans the geometry at half the radius of the main AO.";
        > = 0.2;

        uniform float MXAO_AMOUNT_FINE <
             ui_type = "drag";
             ui_min = 0.00; ui_max = 1.00;
             ui_label = "Fine AO intensity multiplier";
             ui_tooltip = "Intensity of small scale AO / IL.";
        > = 1.0;

        uniform float MXAO_AMOUNT_COARSE <
             ui_type = "drag";
             ui_min = 0.00; ui_max = 1.00;
             ui_label = "Coarse AO intensity multiplier";
             ui_tooltip = "Intensity of large scale AO / IL.";
        > = 1.0;
#endif

uniform int MXAO_DEBUG_VIEW_ENABLE <
	ui_type = "combo";
        ui_label = "Enable Debug View";
	ui_items = "None\0AO/IL channel\0Culling Mask\0";
	ui_tooltip = "Different debug outputs";
> = 0;

uniform int MXAO_BLEND_TYPE <
	ui_type = "drag";
	ui_min = 0; ui_max = 2;
        ui_label = "Blending Mode";
	ui_tooltip = "Different blending modes for merging AO/IL with original color.\0Blending mode 0 matches formula of MXAO 2.0 and older.";
> = 0;

uniform float MXAO_FADE_DEPTH_START <
	ui_type = "drag";
        ui_label = "Fade Out Start";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Distance where MXAO starts to fade out. 0.0 = camera, 1.0 = sky. Must be less than Fade Out End.";
> = 0.05;

uniform float MXAO_FADE_DEPTH_END <
	ui_type = "drag";
        ui_label = "Fade Out End";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Distance where MXAO completely fades out. 0.0 = camera, 1.0 = sky. Must be greater than Fade Out Start.";
> = 0.4;

uniform float Dither_Bit <
	ui_type = "drag";
	ui_min = 1; ui_max = 15;
	ui_label = "Dither Bit";
	ui_tooltip = "Dither is an intentionally applied form of noise used to randomize quantization error, preventing banding in images.";
> = 7.5;

uniform int Depth_Map <
	ui_type = "combo";
	ui_items = "Normal\0Normal Reversed\0Normal Offset\0Normal Reversed Offset\0Raw\0Raw Reverse\0Debug\0";
	ui_label = "Custom Depth Map";
	ui_tooltip = "Pick your Depth Map.";
> = 0;

uniform float Depth_Map_Adjust <
	ui_type = "drag";
	ui_min = 0.25; ui_max = 100.0;
	ui_label = "Depth Map Adjustment";
	ui_tooltip = "Adjust the depth map and sharpness.";
> = 5.0;

uniform float Offset <
	ui_type = "drag";
	ui_min = 0; ui_max = 1.0;
	ui_label = "Offset";
	ui_tooltip = "Offset is for the Special Depth Map Only";
> = 0.375;

uniform bool Depth_Map_Flip <
	ui_label = "Depth Map Flip";
	ui_tooltip = "Flip the depth map if it is upside down.";
> = false;

uniform float2 Image_Position_Adjust<
	ui_type = "drag";
	ui_min = -4096.0; ui_max = 4096.0;
	ui_label = "Image Position Adjust";
	ui_tooltip = "Adjust the Image Postion if it's off by a bit. Default is Zero.";
> = float2(0.0,0.0);
	
uniform float2 Horizontal_Vertical_Resize <
	ui_type = "drag";
	ui_min = 0.125; ui_max = 2;
	ui_label = "Horizontal & Vertical";
	ui_tooltip = "Adjust Horizontal and Vertical Resize. Default is 1.0.";
> = float2(1.0,1.0);

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Textures, Samplers
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

texture2D MXAO_ColorTex 	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RGBA8; MipLevels = 3+MXAO_MIPLEVEL_IL;};
texture2D MXAO_DepthTex 	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = R16F;  MipLevels = 3+MXAO_MIPLEVEL_AO;};
texture2D MXAO_NormalTex	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RGBA8; MipLevels = 3+MXAO_MIPLEVEL_IL;};
texture2D MXAO_CullingTex	{ Width = BUFFER_WIDTH/8; Height = BUFFER_HEIGHT/8; Format = R8; };

sampler2D sMXAO_ColorTex	{ Texture = MXAO_ColorTex;	};
sampler2D sMXAO_DepthTex	{ Texture = MXAO_DepthTex;	};
sampler2D sMXAO_NormalTex	{ Texture = MXAO_NormalTex;	};
sampler2D sMXAO_CullingTex	{ Texture = MXAO_CullingTex;	};

/////////////////////////////////////////////D3D Starts Here/////////////////////////////////////////////////////////////////

texture DepthBufferTex : DEPTH;

sampler DepthBuffer 
	{ 
		Texture = DepthBufferTex; 
	};
		
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)

float4 zBuffer(in float2 texcoord : TEXCOORD0)    
{
		float4 Out;
		float texX = texcoord.x + Image_Position_Adjust.x * pix.x;
		float texY = texcoord.y + Image_Position_Adjust.y * pix.y;	
		float midV = (Horizontal_Vertical_Resize.y-1)*(BUFFER_HEIGHT*0.5)*pix.y;		
		float midH = (Horizontal_Vertical_Resize.x-1)*(BUFFER_WIDTH*0.5)*pix.x;			
		texcoord = float2((texX*Horizontal_Vertical_Resize.x)-midH,(texY*Horizontal_Vertical_Resize.y)-midV);	
		
		if (Depth_Map_Flip)
			texcoord.y =  1 - texcoord.y;
			
		float zBuffer = tex2D(DepthBuffer, texcoord).r; //Depth Buffer

		//Conversions to linear space.....
		//Near & Far Adjustment
		float Near = 0.125/Depth_Map_Adjust; //Division Depth Map Adjust - Near
		float Far = 1; //Far Adjustment
		float DA = Depth_Map_Adjust*2; //Depth Map Adjust - Near
				
		//Raw Z Offset
		float Z = min(1,pow(abs(exp(zBuffer)*Offset),2));
		float ZR = min(1,pow(abs(exp(zBuffer)*Offset),50));
		
		//0. Normal
		float Normal = Far * Near / (Far + zBuffer * (Near - Far));
		
		//1. Reverse
		float NormalReverse = Far * Near / (Near + zBuffer * (Far - Near));
		
		//2. Offset Normal
		float OffsetNormal = Far * Near / (Far + Z * (Near - Far));
		
		//3. Offset Reverse
		float OffsetReverse = Far * Near / (Near + ZR * (Far - Near));
		
		//4. Raw Buffer
		float Raw = min(1,pow(abs(zBuffer),DA));
		
		//5. Raw Buffer Reverse
		float RawReverse = max(1,pow(abs(zBuffer - 1.0),DA));
		
		float DM,DM0,DM1,DM2,DM3;
		
		if (Depth_Map == 0)
		{
		DM = Normal;
		}		
		else if (Depth_Map == 1)
		{
		DM = NormalReverse;
		}
		else if (Depth_Map == 2)
		{
		DM = OffsetNormal;
		}
		else if (Depth_Map == 3)
		{
		DM = OffsetReverse;
		}
		else if (Depth_Map == 4)
		{
		DM = Raw;
		}
		else if (Depth_Map == 5)
		{
		DM = RawReverse;
		}
		else
		{
		DM0 = Normal;
		DM1 = NormalReverse;
		DM2 = OffsetNormal;
		DM3 = OffsetReverse;
		}
	
	// Dither for DepthBuffer adapted from gedosato ramdom dither https://github.com/PeterTh/gedosato/blob/master/pack/assets/dx9/deband.fx
	// I noticed in some games the depth buffer started to have banding so this is used to remove that.
			
	float DB  = Dither_Bit;
	float noise = frac(sin(dot(texcoord, float2(12.9898, 78.233))) * 43758.5453 * 1);
	float dither_shift = (1.0 / (pow(2,DB) - 1.0));
	float dither_shift_half = (dither_shift * 0.5);
	dither_shift = dither_shift * noise - dither_shift_half;
	DM += -dither_shift;
	DM += dither_shift;
	DM += -dither_shift;
	
	// Dither End
	
	if (Depth_Map == 6)
	{
	Out = float4(DM0,DM1,DM2,DM3);
	}
	else
	{
	Out = DM.xxxx;
	}	
		
	return saturate(Out);	
}

////////////////////////////////////////////////////////Logo/////////////////////////////////////////////////////////////////////////
uniform float timer < source = "timer"; >;
float4 Out(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 Color;
	float Top = texcoord.x < 0.5 ? zBuffer(float2(texcoord.x*2,texcoord.y*2)).x : zBuffer(float2(texcoord.x*2-1 , texcoord.y*2)).y;
	float Bottom = texcoord.x < 0.5 ?   zBuffer(float2(texcoord.x*2 , texcoord.y*2-1)).z :  zBuffer(float2(texcoord.x*2-1,texcoord.y*2-1)).w;
	
	if (Depth_Map == 6)
	{
		Color = texcoord.y < 0.5 ? Top.xxxx : Bottom.xxxx;
	}
	else
	{
		Color = zBuffer(texcoord).xxxx;
	}
	
	float PosX = 0.5*BUFFER_WIDTH*pix.x,PosY = 0.5*BUFFER_HEIGHT*pix.y;	
	float4 Done,Website,D,E,P,T,H,Three,DD,Dot,I,N,F,O;
	
	if(timer <= 10000)
	{
	//DEPTH
	//D
	float PosXD = -0.035+PosX, offsetD = 0.001;
	float4 OneD = all( abs(float2( texcoord.x -PosXD, texcoord.y-PosY)) < float2(0.0025,0.009));
	float4 TwoD = all( abs(float2( texcoord.x -PosXD-offsetD, texcoord.y-PosY)) < float2(0.0025,0.007));
	D = OneD-TwoD;
	
	//E
	float PosXE = -0.028+PosX, offsetE = 0.0005;
	float4 OneE = all( abs(float2( texcoord.x -PosXE, texcoord.y-PosY)) < float2(0.003,0.009));
	float4 TwoE = all( abs(float2( texcoord.x -PosXE-offsetE, texcoord.y-PosY)) < float2(0.0025,0.007));
	float4 ThreeE = all( abs(float2( texcoord.x -PosXE, texcoord.y-PosY)) < float2(0.003,0.001));
	E = (OneE-TwoE)+ThreeE;
	
	//P
	float PosXP = -0.0215+PosX, PosYP = -0.0025+PosY, offsetP = 0.001, offsetP1 = 0.002;
	float4 OneP = all( abs(float2( texcoord.x -PosXP, texcoord.y-PosYP)) < float2(0.0025,0.009*0.682));
	float4 TwoP = all( abs(float2( texcoord.x -PosXP-offsetP, texcoord.y-PosYP)) < float2(0.0025,0.007*0.682));
	float4 ThreeP = all( abs(float2( texcoord.x -PosXP+offsetP1, texcoord.y-PosY)) < float2(0.0005,0.009));
	P = (OneP-TwoP) + ThreeP;

	//T
	float PosXT = -0.014+PosX, PosYT = -0.008+PosY;
	float4 OneT = all( abs(float2( texcoord.x -PosXT, texcoord.y-PosYT)) < float2(0.003,0.001));
	float4 TwoT = all( abs(float2( texcoord.x -PosXT, texcoord.y-PosY)) < float2(0.000625,0.009));
	T = OneT+TwoT;
	
	//H
	float PosXH = -0.0071+PosX;
	float4 OneH = all( abs(float2( texcoord.x -PosXH, texcoord.y-PosY)) < float2(0.002,0.001));
	float4 TwoH = all( abs(float2( texcoord.x -PosXH, texcoord.y-PosY)) < float2(0.002,0.009));
	float4 ThreeH = all( abs(float2( texcoord.x -PosXH, texcoord.y-PosY)) < float2(0.003,0.009));
	H = (OneH-TwoH)+ThreeH;
	
	//Three
	float offsetFive = 0.001, PosX3 = -0.001+PosX;
	float4 OneThree = all( abs(float2( texcoord.x -PosX3, texcoord.y-PosY)) < float2(0.002,0.009));
	float4 TwoThree = all( abs(float2( texcoord.x -PosX3 - offsetFive, texcoord.y-PosY)) < float2(0.003,0.007));
	float4 ThreeThree = all( abs(float2( texcoord.x -PosX3, texcoord.y-PosY)) < float2(0.002,0.001));
	Three = (OneThree-TwoThree)+ThreeThree;
	
	//DD
	float PosXDD = 0.006+PosX, offsetDD = 0.001;	
	float4 OneDD = all( abs(float2( texcoord.x -PosXDD, texcoord.y-PosY)) < float2(0.0025,0.009));
	float4 TwoDD = all( abs(float2( texcoord.x -PosXDD-offsetDD, texcoord.y-PosY)) < float2(0.0025,0.007));
	DD = OneDD-TwoDD;
	
	//Dot
	float PosXDot = 0.011+PosX, PosYDot = 0.008+PosY;		
	float4 OneDot = all( abs(float2( texcoord.x -PosXDot, texcoord.y-PosYDot)) < float2(0.00075,0.0015));
	Dot = OneDot;
	
	//INFO
	//I
	float PosXI = 0.0155+PosX, PosYI = 0.004+PosY, PosYII = 0.008+PosY;
	float4 OneI = all( abs(float2( texcoord.x - PosXI, texcoord.y - PosY)) < float2(0.003,0.001));
	float4 TwoI = all( abs(float2( texcoord.x - PosXI, texcoord.y - PosYI)) < float2(0.000625,0.005));
	float4 ThreeI = all( abs(float2( texcoord.x - PosXI, texcoord.y - PosYII)) < float2(0.003,0.001));
	I = OneI+TwoI+ThreeI;
	
	//N
	float PosXN = 0.0225+PosX, PosYN = 0.005+PosY,offsetN = -0.001;
	float4 OneN = all( abs(float2( texcoord.x - PosXN, texcoord.y - PosYN)) < float2(0.002,0.004));
	float4 TwoN = all( abs(float2( texcoord.x - PosXN, texcoord.y - PosYN - offsetN)) < float2(0.003,0.005));
	N = OneN-TwoN;
	
	//F
	float PosXF = 0.029+PosX, PosYF = 0.004+PosY, offsetF = 0.0005, offsetF1 = 0.001;
	float4 OneF = all( abs(float2( texcoord.x -PosXF-offsetF, texcoord.y-PosYF-offsetF1)) < float2(0.002,0.004));
	float4 TwoF = all( abs(float2( texcoord.x -PosXF, texcoord.y-PosYF)) < float2(0.0025,0.005));
	float4 ThreeF = all( abs(float2( texcoord.x -PosXF, texcoord.y-PosYF)) < float2(0.0015,0.00075));
	F = (OneF-TwoF)+ThreeF;
	
	//O
	float PosXO = 0.035+PosX, PosYO = 0.004+PosY;
	float4 OneO = all( abs(float2( texcoord.x -PosXO, texcoord.y-PosYO)) < float2(0.003,0.005));
	float4 TwoO = all( abs(float2( texcoord.x -PosXO, texcoord.y-PosYO)) < float2(0.002,0.003));
	O = OneO-TwoO;
	}
	
	Website = D+E+P+T+H+Three+DD+Dot+I+N+F+O ? float4(1.0,1.0,1.0,1) : Color;
	
	if(timer >= 10000)
	{
	Done = Color;
	}
	else
	{
	Done = Website;
	}

	return Done;
}


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Vertex Shader
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

struct MXAO_VSOUT
{
	float4              position    : SV_Position;
        float2              texcoord    : TEXCOORD0;
        float2              scaledcoord : TEXCOORD1;
        float   	    samples     : TEXCOORD2;
        float3              uvtoviewADD : TEXCOORD4;
        float3              uvtoviewMUL : TEXCOORD5;
};

MXAO_VSOUT VS_MXAO(in uint id : SV_VertexID)
{
        MXAO_VSOUT MXAO;

        MXAO.texcoord.x = (id == 2) ? 2.0 : 0.0;
        MXAO.texcoord.y = (id == 1) ? 2.0 : 0.0;
        MXAO.scaledcoord.xy = MXAO.texcoord.xy / MXAO_GLOBAL_RENDER_SCALE;
        MXAO.position = float4(MXAO.texcoord.xy * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);

        MXAO.samples   = 8;

        if(     MXAO_GLOBAL_SAMPLE_QUALITY_PRESET == 0) { MXAO.samples = 4;     }
        else if(MXAO_GLOBAL_SAMPLE_QUALITY_PRESET == 1) { MXAO.samples = 8;     }
        else if(MXAO_GLOBAL_SAMPLE_QUALITY_PRESET == 2) { MXAO.samples = 16;    }
        else if(MXAO_GLOBAL_SAMPLE_QUALITY_PRESET == 3) { MXAO.samples = 24;    }
        else if(MXAO_GLOBAL_SAMPLE_QUALITY_PRESET == 4) { MXAO.samples = 32;    }
        else if(MXAO_GLOBAL_SAMPLE_QUALITY_PRESET == 5) { MXAO.samples = 64;    }
        else if(MXAO_GLOBAL_SAMPLE_QUALITY_PRESET == 6) { MXAO.samples = 255;   }

        MXAO.uvtoviewADD = float3(-1.0,-1.0,1.0);
        MXAO.uvtoviewMUL = float3(2.0,2.0,0.0);
      //uncomment to enable perspective-correct position recontruction. Minor difference for common FoV's
        static const float FOV = 70.0; //vertical FoV

        MXAO.uvtoviewADD = float3(-tan(radians(FOV * 0.5)).xx,1.0);
        MXAO.uvtoviewADD.y *= BUFFER_WIDTH * BUFFER_RCP_HEIGHT;
        MXAO.uvtoviewMUL = float3(-2.0 * MXAO.uvtoviewADD.xy,0.0);

        return MXAO;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Functions
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float GetLinearDepth(in float2 coords)
{
	float4 pos = float4(coords * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	return Out(pos, coords);
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float3 GetPosition(in float2 coords, in MXAO_VSOUT MXAO)
{
        return (coords.xyx * MXAO.uvtoviewMUL + MXAO.uvtoviewADD) * GetLinearDepth(coords.xy) * RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float3 GetPositionLOD(in float2 coords, in MXAO_VSOUT MXAO, in int mipLevel)
{
        return (coords.xyx * MXAO.uvtoviewMUL + MXAO.uvtoviewADD) * tex2Dlod(sMXAO_DepthTex, float4(coords.xy,0,mipLevel)).x;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void GetBlurWeight(in float4 tempKey, in float4 centerKey, in float surfacealignment, inout float weight)
{
        float depthdiff = abs(tempKey.w - centerKey.w);
        float normaldiff = saturate(1.0 - dot(tempKey.xyz,centerKey.xyz));

        weight = saturate(0.15 / surfacealignment - depthdiff) * saturate(0.65 - normaldiff); 
        weight = saturate(weight * 4.0) * 2.0;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void GetBlurKeyAndSample(in float2 texcoord, in float inputscale, in sampler inputsampler, inout float4 tempsample, inout float4 key)
{
        float4 lodcoord = float4(texcoord.xy,0,0);
        tempsample = tex2Dlod(inputsampler,lodcoord * inputscale);
        key = float4(tex2Dlod(sMXAO_NormalTex,lodcoord).xyz*2-1, tex2Dlod(sMXAO_DepthTex,lodcoord).x);
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float4 BlurFilter(in MXAO_VSOUT MXAO, in sampler inputsampler, in float inputscale, in float radius, in int blursteps)
{
        float4 tempsample;
	float4 centerkey, tempkey;
	float  centerweight = 1.0, tempweight;
	float4 blurcoord = 0.0;

        GetBlurKeyAndSample(MXAO.texcoord.xy,inputscale,inputsampler,tempsample,centerkey);
	float surfacealignment = saturate(-dot(centerkey.xyz,normalize(float3(MXAO.texcoord.xy*2.0-1.0,1.0)*centerkey.w)));

        #if(MXAO_ENABLE_IL != 0)
         #define BLUR_COMP_SWIZZLE xyzw
        #else
         #define BLUR_COMP_SWIZZLE w
        #endif

        float4 blurSum = tempsample.BLUR_COMP_SWIZZLE;
        float2 blurOffsets[8] = {float2(1.5,0.5),float2(-1.5,-0.5),float2(-0.5,1.5),float2(0.5,-1.5),float2(1.5,2.5),float2(-1.5,-2.5),float2(-2.5,1.5),float2(2.5,-1.5)};

        [loop]
        for(int iStep = 0; iStep < blursteps; iStep++)
        {
                float2 sampleCoord = MXAO.texcoord.xy + blurOffsets[iStep] * ReShade::PixelSize * radius / inputscale; 

                GetBlurKeyAndSample(sampleCoord, inputscale, inputsampler, tempsample, tempkey);
                GetBlurWeight(tempkey, centerkey, surfacealignment, tempweight);

                blurSum += tempsample.BLUR_COMP_SWIZZLE * tempweight;
                centerweight  += tempweight;
        }

        blurSum.BLUR_COMP_SWIZZLE /= centerweight;

        #if(MXAO_ENABLE_IL == 0)
                blurSum.xyz = centerkey.xyz*0.5+0.5;
        #endif

        return blurSum;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void SetupAOParameters(in MXAO_VSOUT MXAO, in float3 P, in float layerID, out float scaledRadius, out float falloffFactor)
{
        scaledRadius  = 0.25 * MXAO_SAMPLE_RADIUS / (MXAO.samples * (P.z + 2.0));
        falloffFactor = -1.0/(MXAO_SAMPLE_RADIUS * MXAO_SAMPLE_RADIUS);

        #if(MXAO_TWO_LAYER != 0)
                scaledRadius  *= lerp(1.0,MXAO_SAMPLE_RADIUS_SECONDARY,layerID);
                falloffFactor *= lerp(1.0,1.0/(MXAO_SAMPLE_RADIUS_SECONDARY*MXAO_SAMPLE_RADIUS_SECONDARY),layerID);
        #endif
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void TesselateNormals(inout float3 N, in float3 P, in MXAO_VSOUT MXAO)
{
        float2 searchRadiusScaled = 0.018 / P.z * float2(1.0,ReShade::AspectRatio);
        float3 likelyFace[4] = {N,N,N,N};

        for(int iDirection=0; iDirection < 4; iDirection++)
        {
                float2 cdir;
                sincos(6.28318548 * 0.25 * iDirection,cdir.y,cdir.x);
                for(int i=1; i<=5; i++)
                {
                        float cSearchRadius = exp2(i);
                        float2 cOffset = MXAO.scaledcoord.xy + cdir * cSearchRadius * searchRadiusScaled;

                        float3 cN = tex2Dlod(sMXAO_NormalTex,float4(cOffset,0,0)).xyz * 2.0 - 1.0;
                        float3 cP = GetPositionLOD(cOffset.xy,MXAO,0);

                        float3 cDelta = cP - P;
                        float validWeightDistance = saturate(1.0 - dot(cDelta,cDelta) * 20.0 / cSearchRadius);
                        float Angle = dot(N.xyz,cN.xyz);
                        float validWeightAngle = smoothstep(0.3,0.98,Angle) * smoothstep(1.0,0.98,Angle); //only take normals into account that are NOT equal to the current normal.

                        float validWeight = saturate(3.0 * validWeightDistance * validWeightAngle / cSearchRadius);

                        likelyFace[iDirection] = lerp(likelyFace[iDirection],cN.xyz, validWeight);
                }
        }

        N = normalize(likelyFace[0] + likelyFace[1] + likelyFace[2] + likelyFace[3]);
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

bool GetCullingMask(in MXAO_VSOUT MXAO)
{
        float4 cOffsets = float4(ReShade::PixelSize.xy,-ReShade::PixelSize.xy) * 8;
        float cullingArea = tex2D(sMXAO_CullingTex, MXAO.scaledcoord.xy + cOffsets.xy).x;
        cullingArea      += tex2D(sMXAO_CullingTex, MXAO.scaledcoord.xy + cOffsets.zy).x;
        cullingArea      += tex2D(sMXAO_CullingTex, MXAO.scaledcoord.xy + cOffsets.xw).x;
        cullingArea      += tex2D(sMXAO_CullingTex, MXAO.scaledcoord.xy + cOffsets.zw).x;
        return cullingArea  > 0.000001;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Pixel Shaders
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void PS_InputBufferSetup(in MXAO_VSOUT MXAO, out float4 color : SV_Target0, out float4 depth : SV_Target1, out float4 normal : SV_Target2)
{
        float3 offs = float3(ReShade::PixelSize.xy,0);

	float3 f 	 =       GetPosition(MXAO.texcoord.xy, MXAO);
	float3 gradx1 	 = - f + GetPosition(MXAO.texcoord.xy + offs.xz, MXAO);
	float3 gradx2 	 =   f - GetPosition(MXAO.texcoord.xy - offs.xz, MXAO);
	float3 grady1 	 = - f + GetPosition(MXAO.texcoord.xy + offs.zy, MXAO);
	float3 grady2 	 =   f - GetPosition(MXAO.texcoord.xy - offs.zy, MXAO);

	gradx1 = lerp(gradx1, gradx2, abs(gradx1.z) > abs(gradx2.z));
	grady1 = lerp(grady1, grady2, abs(grady1.z) > abs(grady2.z));

	normal          = float4(normalize(cross(grady1,gradx1)) * 0.5 + 0.5,0.0);
        color 		= tex2D(ReShade::BackBuffer, MXAO.texcoord.xy);
	depth 		= GetLinearDepth(MXAO.texcoord.xy)*RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void PS_Culling(in MXAO_VSOUT MXAO, out float4 color : SV_Target0)
{
        color = 0.0;
        MXAO.scaledcoord.xy = MXAO.texcoord.xy;
        MXAO.samples = clamp(MXAO.samples, 8, 32);

	float3 P             = GetPositionLOD(MXAO.scaledcoord.xy, MXAO, 0);
        float3 N             = tex2D(sMXAO_NormalTex, MXAO.scaledcoord.xy).xyz * 2.0 - 1.0;

	P += N * P.z / RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;

        float scaledRadius;
        float falloffFactor;
        SetupAOParameters(MXAO, P, 0, scaledRadius, falloffFactor);

        float randStep = dot(floor(MXAO.position.xy % 4 + 0.1),int2(1,4)) + 1;
        randStep *= 0.0625;

        float2 sampleUV, Dir;
        sincos(38.39941 * randStep, Dir.x, Dir.y); 

        Dir *= scaledRadius;       

        [loop]
        for(int iSample=0; iSample < MXAO.samples; iSample++)
        {                
                sampleUV = MXAO.scaledcoord.xy + Dir.xy * float2(1.0, ReShade::AspectRatio) * (iSample + randStep);   
                Dir.xy = mul(Dir.xy, float2x2(0.76465,-0.64444,0.64444,0.76465));             

                float sampleMIP = saturate(scaledRadius * iSample * 20.0) * 3.0;

        	float3 V 		= -P + GetPositionLOD(sampleUV, MXAO, sampleMIP + MXAO_MIPLEVEL_AO);
                float  VdotV            = dot(V, V);
                float  VdotN            = dot(V, N) * rsqrt(VdotV);

                float fAO = saturate(1.0 + falloffFactor * VdotV) * saturate(VdotN - MXAO_SAMPLE_NORMAL_BIAS * 0.5);
		color.w += fAO;
        }

        color = color.w;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void PS_StencilSetup(in MXAO_VSOUT MXAO, out float4 color : SV_Target0)
{
        if(    GetLinearDepth(MXAO.scaledcoord.xy) >= MXAO_FADE_DEPTH_END
            || 0.25 * 0.5 * MXAO_SAMPLE_RADIUS / (tex2D(sMXAO_DepthTex,MXAO.scaledcoord.xy).x + 2.0) * BUFFER_HEIGHT < 1.0
            || MXAO.scaledcoord.x > 1.0
            || MXAO.scaledcoord.y > 1.0
            || !GetCullingMask(MXAO)        
            ) discard;

        color = 1.0;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void PS_AmbientObscurance(in MXAO_VSOUT MXAO, out float4 color : SV_Target0)
{
        color = 0.0;

	float3 P             = GetPositionLOD(MXAO.scaledcoord.xy, MXAO, 0);
        float3 N             = tex2D(sMXAO_NormalTex, MXAO.scaledcoord.xy).xyz * 2.0 - 1.0;
        float  layerID       = (MXAO.position.x + MXAO.position.y) % 2.0;

        #if(MXAO_SMOOTHNORMALS != 0)
                TesselateNormals(N, P, MXAO);
        #endif

	P += N * P.z / RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;

        float scaledRadius;
        float falloffFactor;
        SetupAOParameters(MXAO, P, layerID, scaledRadius, falloffFactor);

        float randStep = dot(floor(MXAO.position.xy % 4 + 0.1),int2(1,4)) + 1;
        randStep *= 0.0625;

        float2 sampleUV, Dir;
        sincos(38.39941 * randStep, Dir.x, Dir.y); 

        Dir *= scaledRadius;       

        [loop]
        for(int iSample=0; iSample < MXAO.samples; iSample++)
        {                
                sampleUV = MXAO.scaledcoord.xy + Dir.xy * float2(1.0, ReShade::AspectRatio) * (iSample + randStep);   
                Dir.xy = mul(Dir.xy, float2x2(0.76465,-0.64444,0.64444,0.76465));             

                float sampleMIP = saturate(scaledRadius * iSample * 20.0) * 3.0;

        	float3 V 		= -P + GetPositionLOD(sampleUV, MXAO, sampleMIP + MXAO_MIPLEVEL_AO);
                float  VdotV            = dot(V, V);
                float  VdotN            = dot(V, N) * rsqrt(VdotV);

                float fAO = saturate(1.0 + falloffFactor * VdotV) * saturate(VdotN - MXAO_SAMPLE_NORMAL_BIAS);

        	#if(MXAO_ENABLE_IL != 0)
                        if(fAO > 0.1)
                        {
        			float3 fIL = tex2Dlod(sMXAO_ColorTex, float4(sampleUV,0,sampleMIP + MXAO_MIPLEVEL_IL)).xyz;
        			float3 tN = tex2Dlod(sMXAO_NormalTex, float4(sampleUV,0,sampleMIP + MXAO_MIPLEVEL_IL)).xyz * 2.0 - 1.0;
        			fIL = fIL - fIL*saturate(dot(V,tN)*rsqrt(VdotV)*2.0);
                                color += float4(fIL*fAO,fAO - fAO * dot(fIL,0.333));
                        }
		#else
			color.w += fAO;
		#endif
        }

        color = saturate(color/((1.0-MXAO_SAMPLE_NORMAL_BIAS)*MXAO.samples));
        color = sqrt(color); //AO denoise

        #if(MXAO_TWO_LAYER != 0)
                color = pow(color,1.0 / lerp(MXAO_AMOUNT_COARSE, MXAO_AMOUNT_FINE, layerID));
        #endif
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void PS_BlurX(in MXAO_VSOUT MXAO, out float4 color : SV_Target0)
{
        color = BlurFilter(MXAO, ReShade::BackBuffer, MXAO_GLOBAL_RENDER_SCALE, 1.0, 8);
}

void PS_BlurYandCombine(MXAO_VSOUT MXAO, out float4 color : SV_Target0)
{
        float4 aoil = BlurFilter(MXAO, ReShade::BackBuffer, 1.0, 0.75/MXAO_GLOBAL_RENDER_SCALE, 4);
        aoil *= aoil; //AO denoise

	color                   = tex2D(sMXAO_ColorTex, MXAO.texcoord.xy);

        float scenedepth        = GetLinearDepth(MXAO.texcoord.xy);
        float3 lumcoeff         = float3(0.2126, 0.7152, 0.0722);
        float colorgray         = dot(color.rgb,lumcoeff);
        float blendfact         = 1.0 - colorgray;

        #if(MXAO_ENABLE_IL != 0)
	        aoil.xyz  = lerp(dot(aoil.xyz,lumcoeff),aoil.xyz, MXAO_SSIL_SATURATION) * MXAO_SSIL_AMOUNT * 4.0;
        #else
                aoil.xyz = 0.0;
        #endif

	aoil.w  = 1.0-pow(1.0-aoil.w, MXAO_SSAO_AMOUNT*4.0);
        aoil    = lerp(aoil,0.0,smoothstep(MXAO_FADE_DEPTH_START, MXAO_FADE_DEPTH_END, scenedepth * float4(2.0,2.0,2.0,1.0)));

        if(MXAO_BLEND_TYPE == 0)
        {
                color.rgb -= (aoil.www - aoil.xyz) * blendfact * color.rgb;
        }
        else if(MXAO_BLEND_TYPE == 1)
        {
                color.rgb = color.rgb * saturate(1.0 - aoil.www * blendfact * 1.2) + aoil.xyz * blendfact * colorgray * 2.0;
        }
        else if(MXAO_BLEND_TYPE == 2)
        {
                float colordiff = saturate(2.0 * distance(normalize(color.rgb + 1e-6),normalize(aoil.rgb + 1e-6)));
                color.rgb = color.rgb + aoil.rgb * lerp(color.rgb, dot(color.rgb, 0.3333), colordiff) * blendfact * blendfact * 4.0;
                color.rgb = color.rgb * (1.0 - aoil.www * (1.0 - dot(color.rgb, lumcoeff)));
        }
	else if(MXAO_BLEND_TYPE == 3)
        {
                color.rgb = pow(color.rgb,2.2);
		color.rgb -= (aoil.www - aoil.xyz) * color.rgb;
		color.rgb = pow(color.rgb,1.0/2.2);
        }

        color.rgb = saturate(color.rgb);

	if(MXAO_DEBUG_VIEW_ENABLE == 1) //can't move this into ternary as one is preprocessor def and the other is a uniform
	{
                color.rgb = max(0.0,1.0 - aoil.www + aoil.xyz);
                color.rgb *= (MXAO_ENABLE_IL != 0) ? 0.5 : 1.0;
                 //color.rgb *= GetCullingMask(MXAO);
	}
        else if(MXAO_DEBUG_VIEW_ENABLE == 2)
        {
                color.rgb = GetCullingMask(MXAO);
        }

	color.a = 1.0;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Technique
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

technique MXAO
{

        pass
	{
		VertexShader = VS_MXAO;
		PixelShader  = PS_InputBufferSetup;
		RenderTarget0 = MXAO_ColorTex;
		RenderTarget1 = MXAO_DepthTex;
		RenderTarget2 = MXAO_NormalTex;
	}
        pass
	{
		VertexShader = VS_MXAO;
		PixelShader  = PS_Culling;
		RenderTarget = MXAO_CullingTex;
	}
        pass
        {
                VertexShader = VS_MXAO;
		PixelShader  = PS_StencilSetup;
                /*Render Target is Backbuffer*/
                ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass = REPLACE;
                StencilRef = 1;
        }
        pass
        {
                VertexShader = VS_MXAO;
                PixelShader  = PS_AmbientObscurance;
                /*Render Target is Backbuffer*/
                ClearRenderTargets = true;
                StencilEnable = true;
                StencilPass = KEEP;
                StencilFunc = EQUAL;
                StencilRef = 1;
        }
        pass
	{
		VertexShader = VS_MXAO;
		PixelShader  = PS_BlurX;
                /*Render Target is Backbuffer*/
	}
	pass
	{
		VertexShader = VS_MXAO;
		PixelShader  = PS_BlurYandCombine;
                /*Render Target is Backbuffer*/
	}
}
