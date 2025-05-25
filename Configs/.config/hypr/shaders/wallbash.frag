// Wallbash Shader for Hyprland - Applies a color tint to background blur
//  by: khing

// Dev notes:
// This shader applies a color tint to Hyprland's background blur,
// allowing you to match the blur color with your system theme.
// It works well with transparency to create a consistent look across apps.

//!source=$XDG_CACHE_HOME/hyde/wallbash/colors.inc


/* 
To override this parameters create a file named './wallbash.inc'
We only need to match the file name and use 'inc' to incdicate that
 this is an "include" file
 Example: 

  ┌────────────────────────────────────────────────────────────────────────────┐
  │ //file ./wallbash.inc                                                      │
  │ // wallbash color to use                                                   │
  │ #define WALLBASH_COLOR wallbash_pry1                                       │
  └────────────────────────────────────────────────────────────────────────────┘
 */

precision highp float;
varying vec2 v_texcoord;
uniform sampler2D tex;

// Set RGB values as a vector (0-255 for each component)
// Example: vec3(255,100,50) for a reddish-orange color
// This is automatically divided by 255.0 to convert to 0.0-1.0 range

// Color as a string representation for easier editing
// FORMAT: "R,G,B" (values from 0-255)
#ifndef WALLBASH_COLOR
    #define WALLBASH_COLOR wallbash_pry1 // accepts r,g,b values
#endif

#ifndef WALLBASH_TINT_OPACITY
    #define WALLBASH_TINT_OPACITY 0.2 // Default fallback value
#endif
#ifndef WALLBASH_PRESERVE_BRIGHTNESS
    #define WALLBASH_PRESERVE_BRIGHTNESS 0.8 // Default fallback value
#endif

// Parse the color string into a vec3
// You cannot directly use the string, this is just for documentation
const vec3 COLOR = vec3(WALLBASH_COLOR) / 255.0;

// Set the opacity/strength of the tint (0.0 to 1.0)
// 0.0 = no tint, 1.0 = solid color
const float TINT_OPACITY = WALLBASH_TINT_OPACITY;  // Increased to make effect more visible

// Preserve brightness (0.0 to 1.0)
// Higher values maintain the original brightness of the background
// Lower values allow the tint color's brightness to have more effect
const float PRESERVE_BRIGHTNESS = WALLBASH_PRESERVE_BRIGHTNESS;


// Get luminance (brightness) value of a color
float getLuminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
    // Get the original pixel color
    vec4 pixColor = texture2D(tex, v_texcoord);
    vec3 originalColor = pixColor.rgb;
    
    // Get the tint color
    vec3 tintColor = COLOR;
    
    // Get luminance of the original color
    float originalLuminance = getLuminance(originalColor);
    
    // Create a luminance-preserving version of our tint
    // by combining the tint color with the original luminance
    vec3 luminancePreservedTint;
    if (PRESERVE_BRIGHTNESS > 0.0) {
        // Create a grayscale version with original brightness
        vec3 grayWithOriginalLuminance = vec3(originalLuminance);
        
        // Mix the tint color with grayscale that has original luminance
        luminancePreservedTint = mix(tintColor, grayWithOriginalLuminance, PRESERVE_BRIGHTNESS);
    } else {
        luminancePreservedTint = tintColor;
    }
    
    // Apply the tint based on the opacity setting
    vec3 result = mix(originalColor, luminancePreservedTint, TINT_OPACITY);
    
    // Final color with original alpha
    gl_FragColor = vec4(result, pixColor.a);
}
