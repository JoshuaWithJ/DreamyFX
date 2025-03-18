/////////////////////////////////////////////////////////////////////////////////
// - Dreamy Effect - by Joshua
/////////////////////////////////////////////////////////////////////////////////
float2 MotionDir_R = float2(3, 6);  // Blur direction Right
float2 MotionDir_L = float2(3, -6);  // Blur direction Left

float BlurAmount = 0.04;  // Blur intensity

float Flickering_Intensity = 0.2;
float Flickering_Size = 0.02;
float Flickering_DirectionX = 0.2;
float Flickering_DirectionY = 0.3;

float Brightness = 20.0;  // Blur intensity
float Saturation = 0.5;
float ColorThreshold = 5;
/////////////////////////////////////////////////////////////////////////////////

float2 MotionDir = float2(1.5, 1.5);  // Blur direction Alpha Mask

/////////////////////////////////////////////////////////////////////////////////

float time : TIME;
float3	CameraPosition    : POSITION  < string Object = "Camera"; >;
float4x4 WorldViewMatrix			: WORLDVIEW;

/////////////////////////////////////////////////////////////////////////////////
// by Joshua

float4 ClearColor = {0,0,0,0};
float ClearDepth  = 1.0;

float Script : STANDARDSGLOBAL <
	string ScriptOutput = "color";
	string ScriptClass = "scene";
	string ScriptOrder = "postprocess";
> = 0.8;

float2 ViewportSize : VIEWPORTPIXELSIZE;
static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);

texture2D DepthBuffer : RENDERDEPTHSTENCILTARGET <
	string Format = "D24S8";
>;


texture2D ScnMap : RENDERCOLORTARGET <
	float2 ViewportRatio = {1.0f, 1.0f};
	bool AntiAlias = true;
	int MipLevels = 1;
	string Format = "A16B16G16R16F";
>;

sampler2D ScnSamp = sampler_state {
	texture = <ScnMap>;
	MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
    MIPFILTER = LINEAR;
    ADDRESSU  = CLAMP;
    ADDRESSV  = CLAMP;
};
sampler2D ScnSampB = sampler_state {
	texture = <ScnMap>;
	MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
    MIPFILTER = LINEAR;
    ADDRESSU  = CLAMP;
    ADDRESSV  = CLAMP;
};
sampler2D ScnSampC = sampler_state {
	texture = <ScnMap>;
	MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
    MIPFILTER = LINEAR;
    ADDRESSU  = CLAMP;
    ADDRESSV  = CLAMP;
};

texture2D DreamyFXAlphaMask : OFFSCREENRENDERTARGET
<
    string Description = "DreamyFX Alpha Mask RT";
    float4 ClearColor = { 1, 1, 1, 1 };
    float ClearDepth = 1.0;
	int Miplevels = 0;
	string DefaultEffect = "self = hide;"
	    "*= Resources/Alpha - On.fx;";
>;
sampler2D AlphaMaskSampler = sampler_state {
    texture = <DreamyFXAlphaMask>;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
    MIPFILTER = LINEAR;
    ADDRESSU  = CLAMP;
    ADDRESSV  = CLAMP;
};

/////////////////////////////////////////////////////////////////////////////////

texture2D EffTex <
    string ResourceName = "L.png";
>;
sampler EffSampler = sampler_state {
    texture = <EffTex>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = WRAP;
    AddressV  = WRAP;

};

////////////////////////////////////////////////////////////////////////////////////////////////
// CONTROLLER

//ToneMap Controller 
#define CONTROLLER_NAME	"DreamyFX - Controller.pmx"

//Alpha
float Intensity: CONTROLOBJECT < string name = "DreamyFX - Controller.pmx"; string item = "Intensity"; >;

float D_BrightnessP: CONTROLOBJECT < string name = "DreamyFX - Controller.pmx"; string item = "Brightness+"; >;
float D_BrightnessL : CONTROLOBJECT < string name = "DreamyFX - Controller.pmx"; string item = "Brightness-"; >;

float D_SaturationL : CONTROLOBJECT < string name = "DreamyFX - Controller.pmx"; string item = "Saturation-"; >;
float D_SaturationP : CONTROLOBJECT < string name = "DreamyFX - Controller.pmx"; string item = "Saturation+"; >;

float D_ThresholdL : CONTROLOBJECT < string name = "DreamyFX - Controller.pmx"; string item = "Threshold-"; >;
float D_ThresholdP : CONTROLOBJECT < string name = "DreamyFX - Controller.pmx"; string item = "Threshold+"; >;

float D_BlurL : CONTROLOBJECT < string name = "DreamyFX - Controller.pmx"; string item = "Blur+"; >;
float D_BlurP : CONTROLOBJECT < string name = "DreamyFX - Controller.pmx"; string item = "Blur-"; >;

float D_BlurDirL : CONTROLOBJECT < string name = "DreamyFX - Controller.pmx"; string item = "BlurDir-"; >;
float D_BlurDirP : CONTROLOBJECT < string name = "DreamyFX - Controller.pmx"; string item = "BlurDir+"; >;

float D_FlickeringL : CONTROLOBJECT < string name = "DreamyFX - Controller.pmx"; string item = "Flickering-"; >;
float D_FlickeringP : CONTROLOBJECT < string name = "DreamyFX - Controller.pmx"; string item = "Flickering+"; >;

float D_Flick_Intensity : CONTROLOBJECT < string name = "DreamyFX - Controller.pmx"; string item = "Flick_Intensity"; >;

float D_Flick_SizeL : CONTROLOBJECT < string name = "DreamyFX - Controller.pmx"; string item = "Flick_Size-"; >;
float D_Flick_SizeP : CONTROLOBJECT < string name = "DreamyFX - Controller.pmx"; string item = "Flick_Size+"; >;

float D_Light_BounceL : CONTROLOBJECT < string name = "DreamyFX - Controller.pmx"; string item = "Light_Bounce-"; >;
float D_Light_BounceP : CONTROLOBJECT < string name = "DreamyFX - Controller.pmx"; string item = "Light_Bounce+"; >;
float D_Light_Intensity : CONTROLOBJECT < string name = "DreamyFX - Controller.pmx"; string item = "L_B_Intensity"; >;

////////////////////////////////////////////////////////////////////////////////////////////////

float EffectIntensity = 1.0;  // Adjust intensity of the effect
float GetWhiteMask(float3 color)
{
    float distance = length(color - float3(0.0, 0.0, 0.0));
    return 1.0 - saturate(distance / ColorThreshold);
}

/////////////////////////////////////////////////////////////////////////////////
float Exposure    = 1.0;
float Gama = 1.0;
/////////////////////////////////////////////////////////////////////////////////
float2 yccLookup(float x)
{
    float v9 = 1.0;
    v9 *= 1 * Gama;
	v9 += 1;
	
    float samples = 32;
    float scale = 1.0 / samples;
    float i = x * 16 * samples;
    float v11 = exp( -i * scale );
    float v10 = pow( 1.0 - v11, v9 );
    v11 = v10 * 2.0 - 1.0;
    v11 *= v11;
    v11 *= v11;
    v11 *= v11;
    v11 *= v11;
	samples *= Saturation;
	
	
    return float2( v10, v10 * ( samples / i ) * ( 1.0 - v11 ) );
}

float3 ColorToneMapping( float3 c)
{
    float exposure = 1.0;
	
    exposure = 	lerp(exposure, Exposure, exposure);
	
    float4 color;
    color.rgb = c;

    color.y = dot( color.rgb, float3( 0.30, 0.59, 0.11 ) );
    color.rb -= color.y;
    color.yw = yccLookup( color.y * exposure * 0.0625 );
    color.rb *= exposure * color.w;
    color.w = dot( color.rgb, float3( -0.508475, 1.0, -0.186441 ) );
    color.rb += color.y;
    color.g = color.w;    
	return color.rgb;
}

/////////////////////////////////////////////////////////////////////////////////
//Vertex Shader
struct VS_OUTPUT {
	float4 Pos			: POSITION;
	float2 Tex			: TEXCOORD0;
    float4 PPos			: TEXCOORD2;
};

VS_OUTPUT SceneVS( float4 Pos : POSITION, float4 Tex : TEXCOORD0,float4 PPos : TEXCOORD2)
{
	VS_OUTPUT Out = (VS_OUTPUT)0; 
	
	Out.Pos = Pos;
	Out.Tex = Tex + ViewportOffset;
	Out.PPos = Out.Pos;
	
	return Out;
}

/////////////////////////////////////////////////////////////////////////////////
// Pixel Shader

float4 ScenePS(VS_OUTPUT IN) : COLOR0
{

/////////////////////////////////////////////////////////////////////////////////
// Controller Code

	Brightness *= 1 + D_BrightnessP * 10;
	Brightness *= 1 - D_BrightnessL;

	Saturation *= 1 +  D_SaturationP * 5;
	Saturation *= 1 - D_SaturationL;

	ColorThreshold *= 1 + D_ThresholdL * 25;
	ColorThreshold *= 1 - D_ThresholdP;

	BlurAmount *= 1 - D_BlurP;
	BlurAmount *= 1 + D_BlurL;
	
	MotionDir_R += D_BlurDirP * 10;
	MotionDir_R *= 1 - D_BlurDirL;

	Flickering_Intensity *= 1 + -D_Flick_Intensity;

	Flickering_DirectionX += D_FlickeringP;
	Flickering_DirectionY += D_FlickeringP;
	
	Flickering_DirectionX *= 1 - D_FlickeringL;
	Flickering_DirectionY *= 1 - D_FlickeringL;

	Flickering_Size += D_Flick_SizeP;
	Flickering_Size *= 1 - D_Flick_SizeL;

/////////////////////////////////////////////////////////////////////////////////
	//AlphaMask
	float2 RTPos1;
    RTPos1.x				= (IN.PPos.x / IN.PPos.w)*0.5+0.5;
	RTPos1.y				= (-IN.PPos.y / IN.PPos.w)*0.5+0.5;
    float3  AlphaMask = tex2D(AlphaMaskSampler, RTPos1);
	
    float angle = CameraPosition.x * 0.05;
    MotionDir_R *= float2(cos(angle) * 1, sin(1+angle) * 1);
    MotionDir_L *= float2(cos(angle) * 1, sin(1-angle) * 1);
	
    float4 ColorA = tex2D(ScnSamp,IN.Tex);
    float3 ColorB = tex2D(ScnSampB,IN.Tex);
    float3 ColorC = tex2D(ScnSampC,IN.Tex);
	
    float3 FlickeringA = tex2D(EffSampler,IN.Tex * (Flickering_Size) + float2(time * Flickering_DirectionX, time * Flickering_DirectionY) );
	
    float3 FlickeringB = tex2D(EffSampler,IN.Tex * (Flickering_Size) + float2( 0.2 * -time * Flickering_DirectionX, 0.3 * -time * Flickering_DirectionY) );
	
	// BLUR
    const int numSamples = 100;
	
    for (int i = 1; i < numSamples; i++)
    {
        float t = (i / (float)numSamples) - 0.5;
        float2 offset = MotionDir * t * BlurAmount;
		
		float2 UV = IN.Tex + offset;
		
        AlphaMask +=  tex2D(AlphaMaskSampler,UV);
    }
	for (int i = 1; i < numSamples; i++)
    {
        float t = (i / (float)numSamples) - 0.5;
        float2 offset = MotionDir_R * t * BlurAmount;
		
		float3 ColorB_S = 1;
		
		float2 UV = IN.Tex + offset;
		ColorB_S = tex2D(ScnSampB,UV);
		
		float3 sceneStep = step( 0.9 , ColorB_S) ? 1 : 0;
	
		ColorB_S.rgb	= lerp(ColorB_S,sceneStep,1);
		
        ColorB +=  ColorB_S;

    }
	
	for (int i = 1; i < numSamples; i++)
    {
        float t = (i / (float)numSamples) - 0.5;
        float2 offset = MotionDir_L * t * BlurAmount;
		
		float3 ColorC_S = 1;
		
		float2 UV = IN.Tex + offset;
		ColorC_S = tex2D(ScnSampB,UV);
		
		float3 sceneStepC = step( 0.9 , ColorC_S) ? 1 : 0;
		
		ColorC_S.rgb	= lerp(ColorC_S,sceneStepC,1);
		
        ColorC +=  ColorC_S;
    }

    // Average the Color samples
    AlphaMask /= numSamples;
    ColorB /= numSamples;
    ColorC /= numSamples;

	ColorB.rgb *= AlphaMask;
	ColorC.rgb *= AlphaMask;
	
	ColorB = lerp(ColorB, ColorB * clamp(FlickeringA, 0, 1),Flickering_Intensity);
	ColorC = lerp(ColorC, ColorC * clamp(FlickeringB, 0, 1),Flickering_Intensity);
	
    float maskB = GetWhiteMask(ColorB);
    float maskC = GetWhiteMask(ColorC);
	
    float3 effectColor = float3(0.0, 0.0, 0.0) * EffectIntensity;

    ColorB = lerp(ColorB, effectColor, maskB);
    ColorC = lerp(ColorC, effectColor, maskC);
	
	float3 BloomBlend = saturate(ColorB.rgb + ColorC.rgb) * Brightness; 
	
	BloomBlend = clamp(BloomBlend,0,1000);
	
	float LightBounceSpeed = 0;
	
	
	LightBounceSpeed += D_Light_BounceP * 100;
	LightBounceSpeed *= 1 - D_Light_BounceL;
	
	float LightBounce = (sin(time * LightBounceSpeed) + 1) * 0.5;
	
	BloomBlend = lerp(BloomBlend, BloomBlend * LightBounce, 0 + D_Light_Intensity);
	
	float3 scene_toneB		= ColorToneMapping(BloomBlend.rgb);
	BloomBlend.rgb	= lerp(BloomBlend.rgb,scene_toneB,1);
	
	ColorA.rgb = lerp(ColorA, ColorA + BloomBlend, 1 - Intensity);
	
	ColorA.a = 1;
    return lerp(ColorA, ColorA, ColorA);
}

/////////////////////////////////////////////////////////////////////////////////
technique RTT <
	string Script = 
		
		"RenderColorTarget0=ScnMap;"
		"RenderDepthStencilTarget=DepthBuffer;"
		"ClearSetColor=ClearColor;"
		"ClearSetDepth=ClearDepth;"
		"Clear=Color;"
		"Clear=Depth;"
		"ScriptExternal=Color;"
		
		"RenderColorTarget0=;"
		"RenderDepthStencilTarget=;"
		"ClearSetColor=ClearColor;"
		"ClearSetDepth=ClearDepth;"
		"Clear=Color;"
		"Clear=Depth;"
		"Pass=RT;"
		;
	
> {
	pass RT < string Script= "Draw=Buffer;"; > {
		AlphaBlendEnable = false; AlphaTestEnable = false;
		ZEnable = false; ZWriteEnable = false;
		VertexShader = compile vs_3_0 SceneVS();
        PixelShader = compile ps_3_0 ScenePS();
	}
}
/////////////////////////////////////////////////////////////////////////////////
