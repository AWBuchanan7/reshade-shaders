///////////////////////////////////////////////////////////////////
// This effect works like a one-side DoF for distance haze, which slightly
// blurs far away elements. A normal DoF has a focus point and blurs using
// two planes. 
//
// It works by first blurring the screen buffer using 2-pass block blur and
// then blending the blurred result into the screen buffer based on depth
// it uses depth-difference for extra weight in the blur method so edges
// of high-contrasting lines with high depth diffence don't bleed.
///////////////////////////////////////////////////////////////////
// By Otis / Infuse Project
///////////////////////////////////////////////////////////////////

uniform float EffectStrength <
	ui_type = "drag";
	ui_min = 0.0; ui_max=1.0;
	ui_tooltip = "The strength of the effect. Range from 0.0, which means no effect, till 1.0 which means pixels are 100% blurred based on depth.";
> = 0.9;
uniform float3 FogColor <
	ui_type= "color";
	ui_tooltip = "Color of the fog, in (red , green, blue)";
> = float3(0.8,0.8,0.8);
uniform float FogStart <
	ui_type = "drag";
	ui_min = 0.0; ui_max=1.0;
	ui_tooltip = "Start of the fog. 0.0 is at the camera, 1.0 is at the horizon, 0.5 is halfway towards the horizon. Before this point no fog will appear.";
> = 0.2;
uniform float FogFactor <
	ui_type = "drag";
	ui_min = 0.0; ui_max=1.0;
	ui_tooltip = "The amount of fog added to the scene. 0.0 is no fog, 1.0 is the strongest fog possible.";
> = 0.2;

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

#include "Reshade.fxh"

float GetLinearDepth(in float2 coords)
{
	float4 pos = float4(coords * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	return Out(pos, coords);
}

//////////////////////////////////////
// textures
//////////////////////////////////////
texture   Otis_FragmentBuffer1 	{ Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8;};	
texture   Otis_FragmentBuffer2 	{ Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8;};	

//////////////////////////////////////
// samplers
//////////////////////////////////////
sampler2D Otis_SamplerFragmentBuffer2 { Texture = Otis_FragmentBuffer2; };
sampler2D Otis_SamplerFragmentBuffer1 {	Texture = Otis_FragmentBuffer1; };

//////////////////////////////////////
// code
//////////////////////////////////////
float CalculateWeight(float distanceFromSource, float sourceDepth, float neighborDepth)
{
	return (1.0 - abs(sourceDepth - neighborDepth)) * (1/distanceFromSource) * neighborDepth;
}

void PS_Otis_DEH_BlockBlurHorizontal(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD, out float4 outFragment : SV_Target0)
{
	float4 color = tex2D(ReShade::BackBuffer, texcoord);
	float colorDepth = GetLinearDepth(texcoord).r;
	float n = 1.0f;

	[loop]
	for(float i = 1; i < 5; ++i) 
	{
		float2 sourceCoords = texcoord + float2(i * ReShade::PixelSize.x, 0.0);
		float weight = CalculateWeight(i, colorDepth, GetLinearDepth(sourceCoords).r);
		color += (tex2D(ReShade::BackBuffer, sourceCoords) * weight);
		n+=weight;
		
		sourceCoords = texcoord - float2(i * ReShade::PixelSize.x, 0.0);
		weight = CalculateWeight(i, colorDepth, GetLinearDepth(sourceCoords).r);
		color += (tex2D(ReShade::BackBuffer, sourceCoords) * weight);
		n+=weight;
	}
	outFragment = color/n;
}

void PS_Otis_DEH_BlockBlurVertical(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD, out float4 outFragment : SV_Target0)
{
	float4 color = tex2D(Otis_SamplerFragmentBuffer1, texcoord);
	float colorDepth = GetLinearDepth(texcoord).r;
	float n=1.0f;
	
	[loop]
	for(float j = 1; j < 5; ++j) 
	{
		float2 sourceCoords = texcoord + float2(0.0, j * ReShade::PixelSize.y);
		float weight = CalculateWeight(j, colorDepth, GetLinearDepth(sourceCoords).r);
		color += (tex2D(Otis_SamplerFragmentBuffer1, sourceCoords) * weight);
		n+=weight;

		sourceCoords = texcoord - float2(0.0, j * ReShade::PixelSize.y);
		weight = CalculateWeight(j, colorDepth, GetLinearDepth(sourceCoords).r);
		color += (tex2D(Otis_SamplerFragmentBuffer1, sourceCoords) * weight);
		n+=weight;
	}
	outFragment = color/n;
}

void PS_Otis_DEH_BlendBlurWithNormalBuffer(float4 vpos: SV_Position, float2 texcoord: TEXCOORD, out float4 fragment: SV_Target0)
{
	float depth = GetLinearDepth(texcoord).r;
	float4 blendedFragment = lerp(tex2D(ReShade::BackBuffer, texcoord), tex2D(Otis_SamplerFragmentBuffer2, texcoord), clamp(depth  * EffectStrength, 0.0, 1.0)); 
	float yFactor = clamp(texcoord.y > 0.5 ? 1-((texcoord.y-0.5)*2.0) : texcoord.y * 2.0, 0, 1);
	fragment = lerp(blendedFragment, float4(FogColor, blendedFragment.r), clamp((depth-FogStart) * yFactor * FogFactor, 0.0, 1.0));
}

technique DepthHaze
{
	// 3 passes. First 2 passes blur screenbuffer into Otis_FragmentBuffer2 using 2 pass block blur with 10 samples each (so 2 passes needed)
	// 3rd pass blends blurred fragments based on depth with screenbuffer.
	pass Otis_DEH_Pass0
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Otis_DEH_BlockBlurHorizontal;
		RenderTarget = Otis_FragmentBuffer1;
	}

	pass Otis_DEH_Pass1
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Otis_DEH_BlockBlurVertical;
		RenderTarget = Otis_FragmentBuffer2;
	}
	
	pass Otis_DEH_Pass2
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Otis_DEH_BlendBlurWithNormalBuffer;
	}
}
