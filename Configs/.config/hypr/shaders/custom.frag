// Hyde Shader for Hyprland - Combined shader with all effects
// Mix and match effects by changing the define values below
//  by: khing


/* 
To override these parameters create a file named './custom.inc'
We only need to match the file name and use 'inc' to indicate that
this is an "include" file
Example:

  ┌────────────────────────────────────────────────────────────────────────────┐
  │ // file: ./custom.inc                                                      │
  │ // Enable/disable flags for shader effects                                 │
  │ // integer: 0:Disabled, 1:Enabled                                          │
  │ #define BLUE_LIGHT_FILTER_ENABLED 1                                        │
  │ #define VIBRANCE_ENABLED 0                                                 │
  │ #define GRAYSCALE_ENABLED 0                                                │
  │ #define INVERT_COLORS_ENABLED 0                                            │
  │ #define COLOR_VISION_ENABLED 0                                             │
  │                                                                            │
  │ // Blue Light Filter parameters                                            │
  │ // float: Color temperature in Kelvin (lower = warmer/more orange)         │
  │ #define BLUE_LIGHT_FILTER_TEMPERATURE 3000.0                               │
  │ // float: Intensity of the filter (0.0-1.0)                                │
  │ #define BLUE_LIGHT_FILTER_INTENSITY 0.4                                    │
  │                                                                            │
  │ // Vibrance parameters                                                     │
  │ // float: Vibrance level (-1.0 to 1.0, positive increases vibrance)        │
  │ #define VIBRANCE_INTENSITY 0.3                                             │
  │ // float: Balance (0.0 to 1.0, higher preserves skin tones more)           │
  │ #define SHADER_VIBRANCE_SKIN_TONE_PROTECTION 0.75                          │
  │                                                                            │
  │ // Grayscale parameters                                                    │
  │ // integer: Grayscale modes                                                │
  │ #define GRAYSCALE_LUMINOSITY 0                                             │
  │ #define GRAYSCALE_LIGHTNESS 1                                              │
  │ #define GRAYSCALE_AVERAGE 2                                                │
  │ // integer: Luminosity weight standards                                    │
  │ #define GRAYSCALE_LUMINOSITY_PAL 0                                         │
  │ #define GRAYSCALE_LUMINOSITY_HDR 2                                         │
  │ #define GRAYSCALE_LUMINOSITY_HDT 1                                         │
  │                                                                            │
  │ // Invert Colors parameters                                                │
  │ // float: Intensity of color inversion (0.0-1.0)                           │
  │ #define INVERT_COLORS_INTENSITY 1.0                                        │
  │                                                                            │
  │ // Color Vision parameters                                                 │
  │ // integer: 0:Normal, 1:Protanopia, 2:Deuteranopia, 3:Tritanopia           │
  │ #define COLOR_VISION_MODE 0                                                │
  │ // float: Intensity of color vision effect (0.0-1.0)                       │
  │ #define COLOR_VISION_INTENSITY 0.0                                         │
  │                                                                            │
  └────────────────────────────────────────────────────────────────────────────┘
 */

// Enable/disable flags for shader effects
#ifndef BLUE_LIGHT_FILTER_ENABLED
#define BLUE_LIGHT_FILTER_ENABLED 0// Set to 1 to enable the blue light filter effect
#endif
#ifndef VIBRANCE_ENABLED
#define VIBRANCE_ENABLED 0// Set to 1 to enable the vibrance effect
#endif
#ifndef GRAYSCALE_ENABLED
#define GRAYSCALE_ENABLED 0// Set to 1 to enable grayscale effect
#endif
#ifndef INVERT_COLORS_ENABLED
#define INVERT_COLORS_ENABLED 0// Set to 1 to enable color inversion
#endif
#ifndef COLOR_VISION_ENABLED
#define COLOR_VISION_ENABLED true// Set to 1 to enable color vision deficiency simulation
#endif

// Blue Light Filter defines
#ifndef BLUE_LIGHT_FILTER_TEMPERATURE
#define BLUE_LIGHT_FILTER_TEMPERATURE 3000.0// Color temperature in Kelvin (lower = warmer)
#endif
#ifndef BLUE_LIGHT_FILTER_INTENSITY
#define BLUE_LIGHT_FILTER_INTENSITY 0.0// Intensity of the filter (0.0-1.0)
#endif

// Vibrance defines
#ifndef VIBRANCE_INTENSITY
#define VIBRANCE_INTENSITY 0.3// Vibrance level: -1.0 to 1.0
#endif
#ifndef SHADER_VIBRANCE_SKIN_TONE_PROTECTION
#define SHADER_VIBRANCE_SKIN_TONE_PROTECTION 0.75// Balance: 0.0 to 1.0
#endif

// Grayscale defines
#ifndef GRAYSCALE_LUMINOSITY
#define GRAYSCALE_LUMINOSITY 0// Grayscale mode: LUMINOSITY
#endif
#ifndef GRAYSCALE_LIGHTNESS
#define GRAYSCALE_LIGHTNESS 1// Grayscale mode: LIGHTNESS
#endif
#ifndef GRAYSCALE_AVERAGE
#define GRAYSCALE_AVERAGE 2// Grayscale mode: AVERAGE
#endif
#ifndef GRAYSCALE_LUMINOSITY_PAL
#define GRAYSCALE_LUMINOSITY_PAL 0// PAL TV standard luminosity weights
#endif
#ifndef GRAYSCALE_LUMINOSITY_HDR
#define GRAYSCALE_LUMINOSITY_HDR 2// HDR standard luminosity weights
#endif
#ifndef GRAYSCALE_LUMINOSITY_HDT
#define GRAYSCALE_LUMINOSITY_HDT 1// HDT standard luminosity weights
#endif

// Invert Colors defines
#ifndef INVERT_COLORS_INTENSITY
#define INVERT_COLORS_INTENSITY 1.0// Intensity of color inversion (1.0 = full)
#endif

// Color Vision defines
#ifndef COLOR_VISION_MODE
#define COLOR_VISION_MODE 0// Color vision mode
#endif
#ifndef COLOR_VISION_INTENSITY
#define COLOR_VISION_INTENSITY 0.0// Intensity of color vision effect (0.0-1.0)
#endif

#version 300 es
precision highp float;
in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

// ======== Blue Light Filter Functions ========
#if BLUE_LIGHT_FILTER_ENABLED==1
const float BLUE_LIGHT_TEMPERATURE=BLUE_LIGHT_FILTER_TEMPERATURE;
const float BLUE_LIGHT_INTENSITY=BLUE_LIGHT_FILTER_INTENSITY;
const float LuminancePreservationFactor=1.;

// function from https://www.shadertoy.com/view/4sc3D7
// valid from 1000 to 40000 K (and additionally 0 for pure full white)
vec3 colorTemperatureToRGB(const in float TEMPERATURE){
    // values from: http://blenderartists.org/forum/showthread.php?270332-OSL-Goodness&p=2268693&viewfull=1#post2268693
    mat3 m=(TEMPERATURE<=6500.)?mat3(vec3(0.,-2902.1955373783176,-8257.7997278925690),
    vec3(0.,1669.5803561666639,2575.2827530017594),
    vec3(1.,1.3302673723350029,1.8993753891711275))
    :mat3(vec3(1745.0425298314172,1216.6168361476490,-8257.7997278925690),
    vec3(-2666.3474220535695,-2173.1012343082230,2575.2827530017594),
    vec3(.55995389139931482,.70381203140554553,1.8993753891711275));
    return mix(clamp(vec3(m[0]/(vec3(clamp(TEMPERATURE,1000.,40000.))+m[1])+m[2]),vec3(0.),vec3(1.)),
    vec3(1.),smoothstep(1000.,0.,TEMPERATURE));
}

vec3 applyBlueLight(vec3 color){
    color*=mix(1.,dot(color,vec3(.2126,.7152,.0722))/max(dot(color,vec3(.2126,.7152,.0722)),1e-5),
LuminancePreservationFactor);

return mix(color,color*colorTemperatureToRGB(BLUE_LIGHT_TEMPERATURE),BLUE_LIGHT_INTENSITY);
}
#endif

// ======== Vibrance Functions ========
#if VIBRANCE_ENABLED==1
const float VIBRANCE=VIBRANCE_INTENSITY;
const float SKIN_TONE_PROTECTION=SHADER_VIBRANCE_SKIN_TONE_PROTECTION;

// Detect luminance (brightness) of a pixel
float getLuminance(vec3 color){
return dot(color,vec3(.2126,.7152,.0722));
}

// Detect if a color is likely to be a skin tone
float skinToneLikelihood(vec3 color){
// Simple skin tone detection based on common RGB ratios in skin
float r=color.r;
float g=color.g;
float b=color.b;

// Check for common skin tone characteristics
// Skin typically has higher red and green than blue
bool skinCondition1=r>g&&g>b;

// Simplified skin tone detection based on ranges
float skinCondition2=0.;
if(r>=.4&&r<=.85&&g>=.2&&g<=.7&&b>=.1&&b<=.5){
    skinCondition2=1.;
}

return float(skinCondition1)*skinCondition2;
}

// Calculate saturation of a color
float getSaturation(vec3 color){
float minVal=min(min(color.r,color.g),color.b);
float maxVal=max(max(color.r,color.g),color.b);

return(maxVal==0.)?0.:(maxVal-minVal)/maxVal;
}

vec3 applyVibrance(vec3 color){
if(VIBRANCE==0.)return color;

// Calculate base saturation level
float sat=getSaturation(color);

// Detect if the pixel is likely a skin tone
float skinFactor=skinToneLikelihood(color);

// Calculate adjusted vibrance based on skin tone protection
float adjustedVibrance=VIBRANCE*(1.-skinFactor*SKIN_TONE_PROTECTION);

// Calculate max RGB value
float maxRGB=max(color.r,max(color.g,color.b));

// Calculate average RGB value
float avgRGB=(color.r+color.g+color.b)/3.;

// Calculate a blend coefficient based on max and avg RGB values
float blendCoeff=(adjustedVibrance>0.)?
(1.-pow(sat,5.))*.6*adjustedVibrance:
sat*-adjustedVibrance;

// Calculate the color with adjusted saturation
vec3 saturatedColor=color*maxRGB/(avgRGB+.0001);

// Blend between the original and saturated color
return mix(color,saturatedColor,blendCoeff);
}
#endif

// ======== Grayscale Functions ========
#if GRAYSCALE_ENABLED==1
// Enum for type of grayscale conversion
const int LUMINOSITY_MODE=GRAYSCALE_LUMINOSITY;
const int LIGHTNESS_MODE=GRAYSCALE_LIGHTNESS;
const int AVERAGE_MODE=GRAYSCALE_AVERAGE;

// Type of grayscale conversion
const int Type=LUMINOSITY_MODE;

// Enum for selecting luma coefficients
const int PAL=GRAYSCALE_LUMINOSITY_PAL;
const int HDTV=GRAYSCALE_LUMINOSITY_HDT;
const int HDR=GRAYSCALE_LUMINOSITY_HDR;

// Formula used to calculate relative luminance
const int LuminosityType=HDTV;

vec3 applyGrayscale(vec3 color){
float gray;
if(Type==LUMINOSITY_MODE){
    // https://en.wikipedia.org/wiki/Grayscale#Luma_coding_in_video_systems
    if(LuminosityType==PAL){
        gray=dot(color,vec3(.299,.587,.114));
    }else if(LuminosityType==HDTV){
        gray=dot(color,vec3(.2126,.7152,.0722));
    }else if(LuminosityType==HDR){
        gray=dot(color,vec3(.2627,.6780,.0593));
    }
}else if(Type==LIGHTNESS_MODE){
    float maxPixColor=max(color.r,max(color.g,color.b));
    float minPixColor=min(color.r,min(color.g,color.b));
    gray=(maxPixColor+minPixColor)/2.;
}else if(Type==AVERAGE_MODE){
    gray=(color.r+color.g+color.b)/3.;
}

return vec3(gray);
}
#endif

// ======== Invert Colors Functions ========
#if INVERT_COLORS_ENABLED==1
const float INVERT_INTENSITY=INVERT_COLORS_INTENSITY;

vec3 applyInvert(vec3 color){
return mix(color,1.-color,INVERT_INTENSITY);
}
#endif

// ======== Color Vision Functions ========
#if COLOR_VISION_ENABLED==1
const int CV_MODE=COLOR_VISION_MODE;
const float CV_INTENSITY=COLOR_VISION_INTENSITY;

// Constants for color vision deficiency simulation
const float protanopia_r=2.02344;
const float protanopia_g=-2.52581;

const float deuteranopia_r=.494207;
const float deuteranopia_g=1.24827;

const float tritanopia_r=-.395913;
const float tritanopia_g=.801109;

// RGB to LMS conversion matrix
const mat3 RGB2LMS=mat3(
17.8824,43.5161,4.11935,
3.45565,27.1554,3.86714,
.0299566,.184309,1.46709
);

// LMS to RGB conversion matrix
const mat3 LMS2RGB=mat3(
.0809444479,-.130504409,.116721066,
-.0102485335,.0540193266,-.113614708,
-.000365296938,-.00412161469,.693511405
);

vec3 applyColorVision(vec3 color){
// Convert from RGB to LMS color space (Long, Medium, Short cone response)
vec3 lms=RGB2LMS*color;

// Apply CVD transformation based on selected mode
mat3 m;
if(CV_MODE==0){// Normal vision (no transformation)
    m=mat3(
        1.,0.,0.,
        0.,1.,0.,
        0.,0.,1.
    );
}else if(CV_MODE==1){// Protanopia (red-deficient)
    m=mat3(
        0.,protanopia_r,protanopia_g,
        0.,1.,0.,
        0.,0.,1.
    );
}else if(CV_MODE==2){// Deuteranopia (green-deficient)
    m=mat3(
        1.,0.,0.,
        deuteranopia_r,0.,deuteranopia_g,
        0.,0.,1.
    );
}else if(CV_MODE==3){// Tritanopia (blue-deficient)
    m=mat3(
        1.,0.,0.,
        0.,1.,0.,
        tritanopia_r,tritanopia_g,0.
    );
}

// Apply the transformation
vec3 lmsTransformed=m*lms;

// Convert back to RGB
vec3 colorTransformed=LMS2RGB*lmsTransformed;

// Mix between original and transformed based on intensity
return mix(color,colorTransformed,CV_INTENSITY);
}
#endif

void main(){
// Get original pixel color
vec4 pixColor=texture(tex,v_texcoord);
vec3 color=pixColor.rgb;

// Apply effects in sequence based on enable flags
#if BLUE_LIGHT_FILTER_ENABLED==1
color=applyBlueLight(color);
#endif

#if VIBRANCE_ENABLED==1
color=applyVibrance(color);
#endif

#if GRAYSCALE_ENABLED==1
color=applyGrayscale(color);
#endif

#if INVERT_COLORS_ENABLED==1
color=applyInvert(color);
#endif

#if COLOR_VISION_ENABLED==1
color=applyColorVision(color);
#endif

// Output final color
fragColor=vec4(color,pixColor.a);
}
