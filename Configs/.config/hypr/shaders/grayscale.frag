/*
 * Grayscale
 */


/* 
To override this parameters create a file named './grayscale.inc'
We only need to match the file name and use 'inc' to incdicate that
 this is an "include" file
 Example: 

  ┌────────────────────────────────────────────────────────────────────────────┐
  │ // file: ./grayscale.inc                                                   │
  │ // integer: 0:PAL, 1:HDTV, 2:HDR                                           │
  │ #define GRAYSCALE_LUMINOSITY_PAL 0                                         │
  │ // integer: 0:HDTV, 1:HDR, 2:HDR                                           │
  │ #define GRAYSCALE_LUMINOSITY_HDR 2                                         │
  │ // integer: 0:HDTV, 1:HDR, 2:HDR                                           │
  │ #define GRAYSCALE_LUMINOSITY_HDT 1                                         │
  │ // integer: 0:No effect, 1:Lightness, 2:Average                            │
  │ #define GRAYSCALE_LIGHTNESS 1                                              │
  │ // integer: 0:No effect, 1:Lightness, 2:Average                            │
  │ #define GRAYSCALE_AVERAGE 2                                                │
  │                                                                            │
  └────────────────────────────────────────────────────────────────────────────┘
 */



#ifndef GRAYSCALE_LUMINOSITY_PAL
    #define GRAYSCALE_LUMINOSITY_PAL 0 // Default fallback value
#endif
#ifndef GRAYSCALE_LUMINOSITY_HDR
    #define GRAYSCALE_LUMINOSITY_HDR 2 // Default fallback value
#endif
#ifndef GRAYSCALE_LUMINOSITY_HDT
    #define GRAYSCALE_LUMINOSITY_HDT 1 // Default fallback value
#endif
#ifndef GRAYSCALE_LIGHTNESS
    #define GRAYSCALE_LIGHTNESS 1 // Default fallback value
#endif
#ifndef GRAYSCALE_AVERAGE       
    #define GRAYSCALE_AVERAGE 2 // Default fallback value
#endif
#ifndef GRAYSCALE_LUMINOSITY
    #define GRAYSCALE_LUMINOSITY 0 // Default fallback value
#endif

#version 300 es
precision highp float;
in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

// Enum for type of grayscale conversion
const int LUMINOSITY =  GRAYSCALE_LUMINOSITY; // Default to LUMINOSITY
const int LIGHTNESS = GRAYSCALE_LIGHTNESS; // Default to LIGHTNESS
const int AVERAGE = GRAYSCALE_AVERAGE; // Default to AVERAGE

/**
 * Type of grayscale conversion.
 */
const int Type = LUMINOSITY; // Default to LUMINOSITY

// Enum for selecting luma coefficients
const int PAL = GRAYSCALE_LUMINOSITY_PAL; // Default to PAL standard
const int HDTV = GRAYSCALE_LUMINOSITY_HDT; // Default to HDTV standard
const int HDR = GRAYSCALE_LUMINOSITY_HDR; // Default to HDR standard

/**
 * Formula used to calculate relative luminance.
 * (Only applies to type = "luminosity".)
 */
const int LuminosityType = HDTV; // Default to HDTV standard

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    float gray;
    if (Type == LUMINOSITY) {
        // https://en.wikipedia.org/wiki/Grayscale#Luma_coding_in_video_systems
        if (LuminosityType == PAL) {
            gray = dot(pixColor.rgb, vec3(0.299, 0.587, 0.114));
        } else if (LuminosityType == HDTV) {
            gray = dot(pixColor.rgb, vec3(0.2126, 0.7152, 0.0722));
        } else if (LuminosityType == HDR) {
            gray = dot(pixColor.rgb, vec3(0.2627, 0.6780, 0.0593));
        }
    } else if (Type == LIGHTNESS) {
        float maxPixColor = max(pixColor.r, max(pixColor.g, pixColor.b));
        float minPixColor = min(pixColor.r, min(pixColor.g, pixColor.b));
        gray = (maxPixColor + minPixColor) / 2.0;
    } else if (Type == AVERAGE) {
        gray = (pixColor.r + pixColor.g + pixColor.b) / 3.0;
    }
    vec3 grayscale = vec3(gray);

    fragColor = vec4(grayscale, pixColor.a);
}
