// Color Vision Shader for Hyprland - Simulates and compensates for color vision deficiency (CVD)
//  by: khing

/**********************************************************************************************
 *                                        DEV NOTES:                                        *
 *  PLEASE NOTE THAT I DON'T HAVE ANY KNOWLEDGE OF GLSL, SO THIS SHADER MAY NOT BE OPTIMAL. *
 *   I ONLY SEARCHED ONLINE FOR WAYS TO SIMULATE COLOR VISION DEFICIENCY AND DALTONIZATION. *
 *               I ONLY TESTED THIS USING AN ANDROID APP CALLED "CVSIMULATOR".              *
 *             IF YOU HAVE ANY SUGGESTIONS FOR IMPROVEMENTS, PLEASE LET ME KNOW!            *
 **********************************************************************************************/


/* 
To override this parameters create a file named './color-vision.inc'
We only need to match the file name and use 'inc' to incdicate that
 this is an "include" file
 Example: 
  ┌────────────────────────────────────────────────────────────────────────────┐
  │  //file: ./color-vision.inc                                                │
  │  // integer: 0:Normal vision, 1:Protanopia, 2:Deuteranopia, 3:Tritanopia   │
  │  #define COLOR_VISION_MODE 1                                               │
  │  // float: 0.0:No effect, -1.0 daltonization, 1.0: CVD simulation          │
  │  #define COLOR_VISION_INTENSITY 0.5                                        │
  │                                                                            │
  └────────────────────────────────────────────────────────────────────────────┘
 */


#ifndef COLOR_VISION_MODE
    #define COLOR_VISION_MODE 0 // Default fallback value
#endif
#ifndef COLOR_VISION_INTENSITY
    #define COLOR_VISION_INTENSITY 0.0 // Default fallback value
#endif

/* 
  ┌─────────────────────────────────────────────────────────────────────────┐
 !│ DO NOT EDIT THE FOLLOWING LINES                                         │
  └─────────────────────────────────────────────────────────────────────────┘
 */

precision highp float;
varying vec2 v_texcoord;
uniform sampler2D tex;


const int MODE = COLOR_VISION_MODE;
const float INTENSITY = COLOR_VISION_INTENSITY;



// Constants for color vision deficiency simulation
const float protanopia_r = 2.02344;
const float protanopia_g = -2.52581;

const float deuteranopia_r = 0.494207;
const float deuteranopia_g = 1.24827;

const float tritanopia_r = -0.395913;
const float tritanopia_g = 0.801109;



// RGB to LMS conversion matrix
const mat3 RGB2LMS = mat3(
    17.8824, 43.5161, 4.11935,
    3.45565, 27.1554, 3.86714,
    0.0299566, 0.184309, 1.46709
);

// LMS to RGB conversion matrix
const mat3 LMS2RGB = mat3(
    0.0809444479, -0.130504409, 0.116721066,
    -0.0102485335, 0.0540193266, -0.113614708,
    -0.000365296938, -0.00412161469, 0.693511405
);

// Simulate color vision deficiency based on LMS color space transformations
vec3 simulateColorVisionDeficiency(vec3 color) {
    // Convert from RGB to LMS color space (Long, Medium, Short cone response)
    vec3 lms = RGB2LMS * color;
    
    // Apply CVD transformation based on selected mode
    mat3 m;
    if(MODE == 0) {        // Normal vision (no transformation)
        m = mat3(
            1.0, 0.0, 0.0,
            0.0, 1.0, 0.0,
            0.0, 0.0, 1.0
        );
    } else if(MODE == 1) { // Protanopia (red-deficient)
        m = mat3(
            0.0, protanopia_r, protanopia_g,
            0.0, 1.0, 0.0,
            0.0, 0.0, 1.0
        );
    } else if(MODE == 2) { // Deuteranopia (green-deficient)
        m = mat3(
            1.0, 0.0, 0.0,
            deuteranopia_r, 0.0, deuteranopia_g,
            0.0, 0.0, 1.0
        );
    } else {               // Tritanopia (blue-deficient)
        m = mat3(
            1.0, 0.0, 0.0,
            0.0, 1.0, 0.0,
            tritanopia_r, tritanopia_g, 0.0
        );
    }
    
    // Transform back to RGB color space
    return LMS2RGB * (m * lms);
}

// Apply daltonization to enhance color differences for CVD viewers
vec3 daltonize(vec3 color, vec3 simulation) {
    // Calculate the error between original and simulated colors
    vec3 error = color - simulation;
    
    // Redistribute the error to enhance visibility
    vec3 correction;
    if (MODE == 0) { // Normal vision - no correction needed
        correction = vec3(0.0, 0.0, 0.0);
    } else if (MODE == 1) { // Protanopia - shift errors in red to blue and green
        correction = vec3(0.0, error.r * 0.7, error.r * 0.3);
    } else if (MODE == 2) { // Deuteranopia - shift errors in green to red and blue
        correction = vec3(error.g * 0.7, 0.0, error.g * 0.3);
    } else { // Tritanopia - shift errors in blue to red and green
        correction = vec3(error.b * 0.5, error.b * 0.5, 0.0);
    }
    
    // Apply correction
    return color + correction;
}

void main() {
    // Sample the texture at the current fragment's texture coordinates
    vec4 pixColor = texture2D(tex, v_texcoord);
    vec3 color = pixColor.rgb;
    
    // No effect needed for normal vision with no intensity
    if (MODE == 0 && INTENSITY == 0.0) {
        gl_FragColor = pixColor;
        return;
    }
    
    // Simulate color vision deficiency based on the selected mode
    vec3 simulated = simulateColorVisionDeficiency(color);
    
    // Optional: Apply daltonization (color correction) if intensity is negative
    // This helps make colors more distinguishable for users with CVD
    vec3 corrected = daltonize(color, simulated);
    
    vec3 result;
    
    // Special handling for normal vision mode
    if (MODE == 0) {
        // For normal vision, positive intensity increases saturation
        // and negative intensity decreases saturation (towards grayscale)
        if (INTENSITY >= 0.0) {
            // Increase saturation
            vec3 luminance = vec3(dot(color, vec3(0.2126, 0.7152, 0.0722)));
            result = mix(color, mix(luminance, color * 1.5, 1.0), INTENSITY);
        } else {
            // Decrease saturation (towards grayscale)
            vec3 luminance = vec3(dot(color, vec3(0.2126, 0.7152, 0.0722)));
            result = mix(color, luminance, -INTENSITY);
        }
    }
    // For color vision deficiency modes
    else if (INTENSITY >= 0.0) {
        // Apply simulation with gradually increasing intensity
        result = mix(color, simulated, INTENSITY);
    } else {
        // Apply daltonization correction with gradually increasing intensity
        result = mix(color, corrected, -INTENSITY);
    }
    
    // Output the final color with the original alpha value
    gl_FragColor = vec4(result, pixColor.a);
}
