//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
// visit facebook.com/MartyMcModding for news/updates
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Reflective Bumpmapping "RBM" 3.0 beta by Marty McFly. 
// For ReShade 3.X only!
// Copyright © 2008-2016 Marty McFly
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform float fRBM_BlurWidthPixels <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 400.00;
	ui_step = 1;
	ui_tooltip = "Controls how far the reflections spread. If you get repeating artifacts, lower this or raise sample count.";
> = 100.0;

uniform int iRBM_SampleCount <
	ui_type = "drag";
	ui_min = 16; ui_max = 128;
	ui_tooltip = "Controls how many glossy reflection samples are taken. Raise this if you get repeating artifacts. Performance hit.";
> = 32;

uniform float fRBM_ReliefHeight <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 2.00;
	ui_tooltip = "Controls how intensive the relief on surfaces is. 0.0 means mirror-like reflections.";
> = 0.3;

uniform float fRBM_FresnelReflectance <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "The lower this value, the lower the view to surface angle has to be to get significant reflection. 1.0 means every surface has 100% gloss.";
> = 0.3;

uniform float fRBM_FresnelMult <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "Not physically accurate at all: multiplier of reflection intensity at lowest view-surface angle.";
> = 0.5;

uniform float  fRBM_LowerThreshold <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "Anything darker than this does not get reflected at all. Reflection power increases linearly from lower to upper threshold. ";
> = 0.1;

uniform float  fRBM_UpperThreshold <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "Anything brighter than this contributes fully to reflection. Reflection power increases linearly from lower to upper threshold. ";
> = 0.2;

uniform float  fRBM_ColorMask_Red <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "Reflection mult on red surfaces.Lower this to remove reflections from red surfaces.";
> = 1.0;

uniform float  fRBM_ColorMask_Orange <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "Reflection mult on orange surfaces. Lower this to remove reflections from orange surfaces.";
> = 1.0;

uniform float  fRBM_ColorMask_Yellow <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "Reflection mult on yellow surfaces. Lower this to remove reflections from yellow surfaces.";
> = 1.0;

uniform float  fRBM_ColorMask_Green <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "Reflection mult on green surfaces. Lower this to remove reflections from green surfaces.";
> = 1.0;

uniform float  fRBM_ColorMask_Cyan <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "Reflection mult on cyan surfaces. Lower this to remove reflections from cyan surfaces.";
> = 1.0;

uniform float  fRBM_ColorMask_Blue <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "Reflection mult on blue surfaces. Lower this to remove reflections from blue surfaces.";
> = 1.0;

uniform float  fRBM_ColorMask_Magenta <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "Reflection mult on magenta surfaces. Lower this to remove reflections from magenta surfaces.";
> = 1.0;

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
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
float GetLinearDepth(float2 coords)
{
	float4 pos = float4(coords * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	return Out(pos, coords);
}

float3 GetPosition(float2 coords)
{
	float EyeDepth = GetLinearDepth(coords.xy)*RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
	return float3((coords.xy * 2.0 - 1.0)*EyeDepth,EyeDepth);
}

float3 GetNormalFromDepth(float2 coords) 
{
	float3 centerPos = GetPosition(coords.xy);
	float2 offs = ReShade::PixelSize.xy*1.0;
	float3 ddx1 = GetPosition(coords.xy + float2(offs.x, 0)) - centerPos;
	float3 ddx2 = centerPos - GetPosition(coords.xy + float2(-offs.x, 0));

	float3 ddy1 = GetPosition(coords.xy + float2(0, offs.y)) - centerPos;
	float3 ddy2 = centerPos - GetPosition(coords.xy + float2(0, -offs.y));

	ddx1 = lerp(ddx1, ddx2, abs(ddx1.z) > abs(ddx2.z));
	ddy1 = lerp(ddy1, ddy2, abs(ddy1.z) > abs(ddy2.z));

	float3 normal = cross(ddy1, ddx1);
	
	return normalize(normal);
}

float3 GetNormalFromColor(float2 coords, float2 offset, float scale, float sharpness)
{
	const float3 lumCoeff = float3(0.299,0.587,0.114);

    	float hpx = dot(tex2Dlod(ReShade::BackBuffer, float4(coords + float2(offset.x,0.0),0,0)).xyz,lumCoeff) * scale;
    	float hmx = dot(tex2Dlod(ReShade::BackBuffer, float4(coords - float2(offset.x,0.0),0,0)).xyz,lumCoeff) * scale;
    	float hpy = dot(tex2Dlod(ReShade::BackBuffer, float4(coords + float2(0.0,offset.y),0,0)).xyz,lumCoeff) * scale;
    	float hmy = dot(tex2Dlod(ReShade::BackBuffer, float4(coords - float2(0.0,offset.y),0,0)).xyz,lumCoeff) * scale;

    	float dpx = GetLinearDepth(coords + float2(offset.x,0.0));
    	float dmx = GetLinearDepth(coords - float2(offset.x,0.0));
    	float dpy = GetLinearDepth(coords + float2(0.0,offset.y));
    	float dmy = GetLinearDepth(coords - float2(0.0,offset.y));

	float2 xymult = float2(abs(dmx - dpx), abs(dmy - dpy)) * sharpness; 
	xymult = max(0.0, 1.0 - xymult);
    	
    	float ddx = (hmx - hpx) / (2.0 * offset.x) * xymult.x;
    	float ddy = (hmy - hpy) / (2.0 * offset.y) * xymult.y;
    
    	return normalize(float3(ddx, ddy, 1.0));
}

float3 GetBlendedNormals(float3 n1, float3 n2)
{
	 return normalize(float3(n1.xy*n2.z + n2.xy*n1.z, n1.z*n2.z));
}

float3 RGB2HSV(float3 RGB)
{
    	float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    	float4 p = RGB.g < RGB.b ? float4(RGB.bg, K.wz) : float4(RGB.gb, K.xy);
    	float4 q = RGB.r < p.x ? float4(p.xyw, RGB.r) : float4(RGB.r, p.yzx);

    	float d = q.x - min(q.w, q.y);
    	float e = 1.0e-10;
    	return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 HSV2RGB(float3 HSV)
{
    	float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    	float3 p = abs(frac(HSV.xxx + K.xyz) * 6.0 - K.www);
    	return HSV.z * lerp(K.xxx, saturate(p - K.xxx), HSV.y); //HDR capable
}

float GetHueMask(in float H)	
{
	float SMod = 0.0;
	SMod += fRBM_ColorMask_Red * ( 1.0 - min( 1.0, abs( H / 0.08333333 ) ) );
	SMod += fRBM_ColorMask_Orange * ( 1.0 - min( 1.0, abs( ( 0.08333333 - H ) / ( - 0.08333333 ) ) ) );
	SMod += fRBM_ColorMask_Yellow * ( 1.0 - min( 1.0, abs( ( 0.16666667 - H ) / ( - 0.16666667 ) ) ) );
	SMod += fRBM_ColorMask_Green * ( 1.0 - min( 1.0, abs( ( 0.33333333 - H ) / 0.16666667 ) ) );
	SMod += fRBM_ColorMask_Cyan * ( 1.0 - min( 1.0, abs( ( 0.5 - H ) / 0.16666667 ) ) );
	SMod += fRBM_ColorMask_Blue * ( 1.0 - min( 1.0, abs( ( 0.66666667 - H ) / 0.16666667 ) ) );
	SMod += fRBM_ColorMask_Magenta * ( 1.0 - min( 1.0, abs( ( 0.83333333 - H ) / 0.16666667 ) ) );
	SMod += fRBM_ColorMask_Red * ( 1.0 - min( 1.0, abs( ( 1.0 - H ) / 0.16666667 ) ) );
	return SMod;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void PS_RBM_Gen(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 res : SV_Target0)
{
	float scenedepth 		= GetLinearDepth(texcoord.xy);
	float3 SurfaceNormals 		= GetNormalFromDepth(texcoord.xy).xyz;
	float3 TextureNormals 		= GetNormalFromColor(texcoord.xy, 0.01 * ReShade::PixelSize.xy / scenedepth, 0.0002 / scenedepth + 0.1, 1000.0);
	float3 SceneNormals		= GetBlendedNormals(SurfaceNormals, TextureNormals);
	SceneNormals 			= normalize(lerp(SurfaceNormals,SceneNormals,fRBM_ReliefHeight));
	float3 ScreenSpacePosition 	= GetPosition(texcoord.xy);
	float3 ViewDirection 		= normalize(ScreenSpacePosition.xyz);

	float4 color = tex2D(ReShade::BackBuffer, texcoord.xy);
	float3 bump = 0.0;

	for(float i=1; i<=iRBM_SampleCount; i++)
	{
		float2 currentOffset 	= texcoord.xy + SceneNormals.xy * ReShade::PixelSize.xy * i/(float)iRBM_SampleCount * fRBM_BlurWidthPixels;
		float4 texelSample 	= tex2Dlod(ReShade::BackBuffer, float4(currentOffset,0,0));	
		
		float depthDiff 	= smoothstep(0.005,0.0,scenedepth-GetLinearDepth(currentOffset));
		float colorWeight 	= smoothstep(fRBM_LowerThreshold,fRBM_UpperThreshold+0.00001,dot(texelSample.xyz,float3(0.299,0.587,0.114)));
		bump += lerp(color.xyz,texelSample.xyz,depthDiff*colorWeight);
	}

	bump /= iRBM_SampleCount;

	float cosphi = dot(-ViewDirection, SceneNormals);
	//R0 + (1.0 - R0)*(1.0-cosphi)^5;
	float SchlickReflectance = lerp(pow(1.0-cosphi,5.0), 1.0, fRBM_FresnelReflectance);
	SchlickReflectance = saturate(SchlickReflectance)*fRBM_FresnelMult; // *should* be 0~1 but isn't for some pixels.

	float3 hsvcol = RGB2HSV(color.xyz);
	float colorMask = GetHueMask(hsvcol.x);
	colorMask = lerp(1.0,colorMask, smoothstep(0.0,0.2,hsvcol.y) * smoothstep(0.0,0.1,hsvcol.z));
	color.xyz = lerp(color.xyz,bump.xyz,SchlickReflectance*colorMask);

	res.xyz = color.xyz;
	res.w = 1.0;

}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

technique ReflectiveBumpmapping
{
	pass P1
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_RBM_Gen;
	}
}
