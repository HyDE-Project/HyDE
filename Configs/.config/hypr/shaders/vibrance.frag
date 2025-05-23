// Vibrance Shader for Hyprland - Enhances color vibrance while preserving skin tones
//  by: khing

// Dev notes:
// This shader enhances perceived color saturation in a more natural way than
// simple saturation adjustment. It adds vibrance while preserving skin tones
// and avoiding color clipping.



/* 
To override this parameters create a file named './vibrance.inc'
We only need to match the file name and use 'inc' to incdicate that
 this is an "include" file
  
  ┌────────────────────────────────────────────────────────────────────────────┐
  │ //file: ./vibrance.inc                                                     │
  │ // Vibrance level: -1.0 to 1.0                                             │
  │ // Positive values increase vibrance, negative values decrease it          │
  │ #define VIBRANCE_INTENSITY 1.0                                             │
  │                                                                            │
  │ // Balance: 0.0 to 1.0                                                     │
  │ // Controls preservation of skin tones (higher values preserve skin tones  │
  │ more)                                                                      │
  │ #define SHADER_VIBRANCE_SKIN_TONE_PROTECTION 0.75                          │
  │                                                                            │
  └────────────────────────────────────────────────────────────────────────────┘
 */

#ifndef VIBRANCE_INTENSITY
    #define VIBRANCE_INTENSITY 1.0  // Default fallback value
#endif

// Balance: 0.0 to 1.0
// Controls preservation of skin tones (higher values preserve skin tones more)
#ifndef SHADER_VIBRANCE_SKIN_TONE_PROTECTION
    #define SHADER_VIBRANCE_SKIN_TONE_PROTECTION 0.75  // Default fallback value
#endif


precision highp float;
varying vec2 v_texcoord;
uniform sampler2D tex;


const float VIBRANCE = VIBRANCE_INTENSITY; 
const float SKIN_TONE_PROTECTION = SHADER_VIBRANCE_SKIN_TONE_PROTECTION;


// Detect luminance (brightness) of a pixel
// Uses HDTV standard coefficients
float getLuminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

// Detect if a color is likely to be a skin tone
float skinToneLikelihood(vec3 color) {
    // Simple skin tone detection based on common RGB ratios in skin
    float r = color.r;
    float g = color.g;
    float b = color.b;
    
    // Check for common skin tone characteristics
    // Skin typically has higher red and green than blue
    bool skinCondition1 = r > g && g > b;
    
    // Simplified skin tone detection based on ranges
    float skinCondition2 = 0.0;
    if (r >= 0.4 && r <= 0.85 && g >= 0.2 && g <= 0.7 && b >= 0.1 && b <= 0.5) {
        skinCondition2 = 1.0;
    }
    
    return float(skinCondition1) * skinCondition2;
}

// Calculate saturation of a color
float getSaturation(vec3 color) {
    float minVal = min(min(color.r, color.g), color.b);
    float maxVal = max(max(color.r, color.g), color.b);
    
    return (maxVal == 0.0) ? 0.0 : (maxVal - minVal) / maxVal;
}

void main() {
    // Get the pixel color from the texture
    vec4 pixColor = texture2D(tex, v_texcoord);
    vec3 color = pixColor.rgb;
    
    // Early exit if vibrance is zero
    if (VIBRANCE == 0.0) {
        gl_FragColor = pixColor;
        return;
    }
    
    // Calculate current saturation and luminance
    float saturation = getSaturation(color);
    float luma = getLuminance(color);
    
    // Vibrance is similar to saturation but applies more to less saturated colors
    // and less to already well-saturated colors
    float vibranceAmount = (1.0 - saturation) * abs(VIBRANCE);
    float skinProtection = skinToneLikelihood(color) * SKIN_TONE_PROTECTION;
    
    // Apply the vibrance effect
    vec3 result;
    
    if (VIBRANCE > 0.0) {
        // For positive vibrance, we boost colors but protect skin tones
        float adjustedVibrance = vibranceAmount * (1.0 - skinProtection);
        
        // Calculate a more balanced gray value that preserves luminance
        vec3 grayColor = vec3(luma);
        
        // Apply increased vibrance (move away from gray)
        result = mix(grayColor, color, 1.0 + adjustedVibrance);
    } else {
        // For negative vibrance, we reduce the color intensity
        // Lerp toward gray based on vibrance and current saturation
        vec3 grayColor = vec3(luma);
        
        // Apply decreased vibrance (move toward gray)
        result = mix(color, grayColor, vibranceAmount);
    }
    
    // Final color with original alpha
    gl_FragColor = vec4(result, pixColor.a);
}
