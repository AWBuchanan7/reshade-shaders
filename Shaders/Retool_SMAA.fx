/**
 *                  _______  ___  ___       ___           ___
 *                 /       ||   \/   |     /   \         /   \
 *                |   (---- |  \  /  |    /  ^  \       /  ^  \
 *                 \   \    |  |\/|  |   /  /_\  \     /  /_\  \
 *              ----)   |   |  |  |  |  /  _____  \   /  _____  \
 *             |_______/    |__|  |__| /__/     \__\ /__/     \__\
 *
 *                               E N H A N C E D
 *       S U B P I X E L   M O R P H O L O G I C A L   A N T I A L I A S I N G
 *
 *                               for ReShade 3.0
 */

//------------------- Preprocessor Settings -------------------

#ifndef SMAA_PREDICATION
 #define SMAA_PREDICATION		0      //[0 or 1] Enables predication which uses BOTH the color and the depth texture for edge detection to more accurately detect edges.
#endif

//----------------------- UI Variables ------------------------
uniform int EdgeDetectionType <
	ui_type = "combo";
	ui_items = "Luminance edge detection\0Color edge detection\0Depth edge detection\0";
	ui_label = "Edge Detection Type";
> = 1;

uniform float EdgeDetectionThreshold <
	ui_type = "drag";
	ui_min = 0.05; ui_max = 0.20; ui_step = 0.01;
	ui_tooltip = "Edge detection threshold. If SMAA misses some edges try lowering this slightly.";
	ui_label = "Edge Detection Threshold";
> = 0.10;

uniform int MaxSearchSteps <
	ui_type = "drag";
	ui_min = 0; ui_max = 112;
	ui_label = "Max Search Steps";
	ui_tooltip = "Determines the radius SMAA will search for aliased edges.";
> = 98;

uniform int MaxSearchStepsDiagonal <
	ui_type = "drag";
	ui_min = 0; ui_max = 20;
	ui_label = "Max Search Steps Diagonal";
	ui_tooltip = "Determines the radius SMAA will search for diagonal aliased edges";
> = 16;

uniform int CornerRounding <
	ui_type = "drag";
	ui_min = 0; ui_max = 100;
	ui_label = "Corner Rounding";
	ui_tooltip = "Determines the percent of anti-aliasing to apply to corners.";
> = 0;

#if SMAA_PREDICATION
uniform float PredicationThreshold <
	ui_type = "drag";
	ui_min = 0.005; ui_max = 1.00; ui_step = 0.01;
	ui_tooltip = "Threshold to be used in the additional predication buffer.";
	ui_label = "Predication Threshold";
> = 0.01;

uniform float PredicationScale <
	ui_type = "drag";
	ui_min = 0; ui_max = 8;
	ui_tooltip = "How much to scale the global threshold used for luma or color edge.";
	ui_label = "Predication Scale";
> = 0.2;

uniform float PredicationStrength <
	ui_type = "drag";
	ui_min = 0; ui_max = 4;
	ui_tooltip = "How much to locally decrease the threshold.";
	ui_label = "Predication Strength";
> = 0.4;
#endif

uniform int DebugOutput <
	ui_type = "combo";
	ui_items = "None\0'edgesTex' buffer\0'blendTex' buffer\0";
	ui_label = "Debug Output";
> = false;

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

/////////////////////////TEXTURES / INTERNAL PARAMETERS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////TEXTURES / INTERNAL PARAMETERS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#if bADOF_ImageGrainEnable
texture texNoise < source = "mcnoise.png"; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler SamplerNoise { Texture = texNoise; };
#endif
#if bADOF_ShapeTextureEnable
texture texMask < source = "mcmask.png"; > { Width = iADOF_ShapeTextureSize; Height = iADOF_ShapeTextureSize; Format = R8; };
sampler SamplerMask { Texture = texMask; };
#endif

#define DOF_RENDERRESMULT 0.6

texture texHDR1 { Width = BUFFER_WIDTH * DOF_RENDERRESMULT; Height = BUFFER_HEIGHT * DOF_RENDERRESMULT; Format = RGBA8; };
texture texHDR2 { Width = BUFFER_WIDTH * DOF_RENDERRESMULT; Height = BUFFER_HEIGHT * DOF_RENDERRESMULT; Format = RGBA8; }; 
sampler SamplerHDR1 { Texture = texHDR1; };
sampler SamplerHDR2 { Texture = texHDR2; };

/////////////////////////FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

float GetLinearDepth(in float2 coords)
{
	float4 pos = float4(coords * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	return Out(pos, coords);
}

#define SMAA_RT_METRICS float4(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT, BUFFER_WIDTH, BUFFER_HEIGHT)
#define SMAA_CUSTOM_SL 1
#define SMAA_PRESET_CUSTOM 1

#define SMAA_THRESHOLD EdgeDetectionThreshold
#define SMAA_MAX_SEARCH_STEPS MaxSearchSteps
#define SMAA_MAX_SEARCH_STEPS_DIAG MaxSearchStepsDiagonal
#define SMAA_CORNER_ROUNDING CornerRounding

#if SMAA_PREDICATION
#define SMAA_PREDICATION_THRESHOLD PredicationThreshold
#define SMAA_PREDICATION_SCALE PredicationScale
#define SMAA_PREDICATION_STRENGTH PredicationStrength
#endif

#define predicationSampler depthLinearSampler//ReShade::DepthBuffer
#define SMAATexture2D(tex) sampler tex
#define SMAATexturePass2D(tex) tex
#define SMAASampleLevelZero(tex, coord) tex2Dlod(tex, float4(coord, coord))
#define SMAASampleLevelZeroPoint(tex, coord) SMAASampleLevelZero(tex, coord)
#define SMAASampleLevelZeroOffset(tex, coord, offset) tex2Dlodoffset(tex, float4(coord, coord), offset)
#define SMAASample(tex, coord) tex2D(tex, coord)
#define SMAASamplePoint(tex, coord) SMAASample(tex, coord)
#define SMAASampleOffset(tex, coord, offset) tex2Doffset(tex, coord, offset)
#define SMAA_BRANCH [branch]
#define SMAA_FLATTEN [flatten]

#if (__RENDERER__ == 0xb000 || __RENDERER__ == 0xb100)
	#define SMAAGather(tex, coord) tex2Dgather(tex, coord, 0)
#endif

#include "Retool_SMAA.fxh"
#include "ReShade.fxh"

// Textures

texture depthTex 	
{ 
	Width = BUFFER_WIDTH;   
	Height = BUFFER_HEIGHT;   
	Format = R16F;  
};

texture edgesTex
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RG8;
};
texture blendTex
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA8;
};

texture areaTex < source = "AreaTex.dds"; >
{
	Width = 160;
	Height = 560;
	Format = RG8;
};
texture searchTex < source = "SearchTex.dds"; >
{
	Width = 64;
	Height = 16;
	Format = R8;
};

// Samplers

sampler depthLinearSampler
{
	Texture = depthTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};

sampler colorGammaSampler
{
	Texture = ReShade::BackBufferTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Point; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler colorLinearSampler
{
	Texture = ReShade::BackBufferTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Point; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = true;
};
sampler edgesSampler
{
	Texture = edgesTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler blendSampler
{
	Texture = blendTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler areaSampler
{
	Texture = areaTex;
	AddressU = Clamp; AddressV = Clamp; AddressW = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler searchSampler
{
	Texture = searchTex;
	AddressU = Clamp; AddressV = Clamp; AddressW = Clamp;
	MipFilter = Point; MinFilter = Point; MagFilter = Point;
	SRGBTexture = false;
};

// Vertex shaders

void SMAAEdgeDetectionWrapVS(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float4 offset[3] : TEXCOORD1)
{
	PostProcessVS(id, position, texcoord);
	SMAAEdgeDetectionVS(texcoord, offset);
}
void SMAABlendingWeightCalculationWrapVS(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float2 pixcoord : TEXCOORD1,
	out float4 offset[3] : TEXCOORD2)
{
	PostProcessVS(id, position, texcoord);
	SMAABlendingWeightCalculationVS(texcoord, pixcoord, offset);
}
void SMAANeighborhoodBlendingWrapVS(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float4 offset : TEXCOORD1)
{
	PostProcessVS(id, position, texcoord);
	SMAANeighborhoodBlendingVS(texcoord, offset);
}

// Pixel shaders

float SMAADepthLinearizationPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0) : SV_Target
{
	return GetLinearDepth(texcoord.xy);
}

float2 SMAAEdgeDetectionWrapPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float4 offset[3] : TEXCOORD1) : SV_Target
{
	if (EdgeDetectionType == 0)
		return SMAALumaEdgeDetectionPS(texcoord, offset, colorGammaSampler
	#if SMAA_PREDICATION
		,predicationSampler
	#endif
	);
	if (EdgeDetectionType == 2)
		return SMAADepthEdgeDetectionPS(texcoord, offset, depthLinearSampler/*ReShade::DepthBuffer*/);

	return SMAAColorEdgeDetectionPS(texcoord, offset, colorGammaSampler
	#if SMAA_PREDICATION
		,predicationSampler
	#endif
	);
}
float4 SMAABlendingWeightCalculationWrapPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float2 pixcoord : TEXCOORD1,
	float4 offset[3] : TEXCOORD2) : SV_Target
{
	return SMAABlendingWeightCalculationPS(texcoord, pixcoord, offset, edgesSampler, areaSampler, searchSampler, 0.0);
}

float3 SMAANeighborhoodBlendingWrapPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float4 offset : TEXCOORD1) : SV_Target
{
	if (DebugOutput == 1)
		return tex2D(edgesSampler, texcoord).rgb;
	if (DebugOutput == 2)
		return tex2D(blendSampler, texcoord).rgb;

	return SMAANeighborhoodBlendingPS(texcoord, offset, colorLinearSampler, blendSampler).rgb;
}

// Rendering passes

technique SMAA
{
	pass LinearizeDepthPass
	{
		VertexShader = PostProcessVS;
		PixelShader  = SMAADepthLinearizationPS;
		RenderTarget = depthTex;
	}
	pass EdgeDetectionPass
	{
		VertexShader = SMAAEdgeDetectionWrapVS;
		PixelShader = SMAAEdgeDetectionWrapPS;
		RenderTarget = edgesTex;
		ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass = REPLACE;
		StencilRef = 1;
	}
	pass BlendWeightCalculationPass
	{
		VertexShader = SMAABlendingWeightCalculationWrapVS;
		PixelShader = SMAABlendingWeightCalculationWrapPS;
		RenderTarget = blendTex;
		ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass = KEEP;
		StencilFunc = EQUAL;
		StencilRef = 1;
	}
	pass NeighborhoodBlendingPass
	{
		VertexShader = SMAANeighborhoodBlendingWrapVS;
		PixelShader = SMAANeighborhoodBlendingWrapPS;
		StencilEnable = false;
		SRGBWriteEnable = true;
	}
}
