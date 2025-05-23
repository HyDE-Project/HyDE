// Paper/e-ink effect shader for Hyprland
// Simulates a grayscale e-ink display with optional quantization and paper grain
// Author: khing

/*
To override these parameters, create a file named './paper.inc'
Use 'inc' to indicate that this is an "include" file for custom defines.

┌─────────────────────────────────────────────────────────────────────────┐
│ //file: ./paper.inc                                                     │
│ // PAPER_GRAYSCALE: Grayscale strength (0.0 = none, 1.0 = full,         │
│ default: 1.0)                                                           │
│ // #define PAPER_GRAYSCALE 1.0                                          │
│ // PAPER_CONTRAST: Contrast adjustment (default: 1.1)                   │
│ // #define PAPER_CONTRAST 1.1                                           │
│ // PAPER_BRIGHTNESS: Brightness adjustment (default: 0.0)               │
│ // #define PAPER_BRIGHTNESS 0.0                                         │
│ // PAPER_SEPIA: Sepia intensity (0.0 = off, 1.0 = full sepia, default:  │
│ 0.0)                                                                    │
│ // #define PAPER_SEPIA 0.0                                              │
│ // PAPER_GRAIN: Paper grain strength (default: 0.7)                     │
│ // #define PAPER_GRAIN 0.7                                              │
│ //                                                                      │
│ // This shader uses quantization and a subtle paper grain effect for a  │
│ // readable e-ink look. Dithering is not used.                          │
└─────────────────────────────────────────────────────────────────────────┘
*/

#ifndef PAPER_GRAYSCALE
#define PAPER_GRAYSCALE 0.
#endif
#ifndef PAPER_CONTRAST
#define PAPER_CONTRAST 1.
#endif
#ifndef PAPER_BRIGHTNESS
#define PAPER_BRIGHTNESS 0.
#endif
#ifndef PAPER_SEPIA
#define PAPER_SEPIA 0.
#endif
#ifndef PAPER_GRAIN
#define PAPER_GRAIN 0.7
#endif

precision highp float;
varying vec2 v_texcoord;
uniform sampler2D tex;

// Paper grain texture (simple random noise)
float paper_grain(vec2 uv){
    float grain=fract(sin(dot(uv*800.,vec2(12.9898,78.233)))*43758.5453);
    return grain*.12-.06;// Range: [-0.06, +0.06]
}

// Convert color to sepia tone
vec3 to_sepia(vec3 color){
    float r=dot(color,vec3(.393,.769,.189));
    float g=dot(color,vec3(.349,.686,.168));
    float b=dot(color,vec3(.272,.534,.131));
    return vec3(r,g,b);
}

void main(){
    vec4 pixColor=texture2D(tex,v_texcoord);
    float gray=dot(pixColor.rgb,vec3(.299,.587,.114));
    vec3 colorResult;
    if(PAPER_GRAYSCALE<0.){
        // Boost color vibrance for negative values
        float vibrance=-PAPER_GRAYSCALE;
        float avg=(pixColor.r+pixColor.g+pixColor.b)/3.;
        colorResult=pixColor.rgb+(pixColor.rgb-vec3(avg))*vibrance;
        colorResult=clamp(colorResult,0.,1.);
    }else{
        // Blend between color and grayscale
        colorResult=mix(pixColor.rgb,vec3(gray),PAPER_GRAYSCALE);
    }
    // Apply contrast and brightness
    colorResult=colorResult*PAPER_CONTRAST+PAPER_BRIGHTNESS;
    colorResult=clamp(colorResult,0.,1.);
    // Sepia intensity (blend between original and sepia)
    colorResult=mix(colorResult,to_sepia(colorResult),PAPER_SEPIA);
    // Add paper grain texture
    float grain=paper_grain(v_texcoord);
    colorResult=clamp(colorResult+grain*PAPER_GRAIN,0.,1.);
    // Minimal highlight compression: just cap the max gray value to avoid pure white
    colorResult=min(colorResult,vec3(.88));
    gl_FragColor=vec4(colorResult,pixColor.a);
}
