// Invert colors shader
// Known to have some quirks with some frames, example: when exiting an application,animations, and some blur effects
// https://github.com/HyDE-Project/HyDE/pull/656
// TODO: Fix the quirkiness of this shader, it is not a priority right now!!!

/*
To override this parameters create a file named './invert-colors.inc'
We only need to match the file name and use 'inc' to incdicate that
this is an "include" file
Example:
┌────────────────────────────────────────────────────────────────────────────┐
│                                                                            │
│ // file: ./invert-colors.inc                                               │
│ // float: 0.0:No effect, 1.0: Invert colors                                │
│ #define INVERT_COLORS_INTENSITY 1.0                                        │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
*/

#ifndef INVERT_COLORS_INTENSITY
#define INVERT_COLORS_INTENSITY 1.0// Default fallback value
#endif

#version 300 es
precision highp float;
in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

// Intensity of color inversion (1.0 = full inversion, 0.0 = no inversion)
const float INTENSITY=INVERT_COLORS_INTENSITY;

void main(){
    vec4 pixColor=texture(tex,v_texcoord);
    
    // Apply inversion with intensity factor
    vec3 invertedColor=mix(pixColor.rgb,1.-pixColor.rgb,INTENSITY);
    fragColor=vec4(invertedColor,pixColor.a);
}
