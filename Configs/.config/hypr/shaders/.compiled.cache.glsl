#version 320 es
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
uniform float time;
uniform float overallAlpha;

out vec4 fragColor;

// Define waybar area (adjust these values to match your waybar position and size)
// Example: Top bar that's 30 pixels tall
const float waybarTop = 0.0;
const float waybarBottom = 40.0 / 1080.0; // 30px converted to 0-1 range
const float waybarLeft = 0.0;
const float waybarRight = 1.0;

// Offset to move the visual effect up in the waybar
const vec2 visualOffset = vec2(0.0, 0.5); // This offset is defined but not directly used in mainImage

// Converted "Ionize" by @XorDev - https://x.com/XorDev/status/1921224922166104360
void mainImage(out vec4 O, in vec2 I) {
    // Apply offset to position the visual center in the waybar
    I.y += 500.0; // Move the view up to make sphere visible in waybar

    //Time for waves and coloring
    float t = time * 0.2, // Slow down animation a bit
    //Raymarch iterator
    i = 0.0,
    //Raymarch depth
    z = 0.0,
    //Raymarch step distance
    d = 0.0,
    //Signed distance for coloring
    s = 0.0;

    //Clear fragcolor and raymarch loop 100 times
    O = vec4(0.0);
    for (; i++ < 100.0; ) {
        //Raymarch sample point
        vec3 p = z * normalize(vec3(I+I, 0.0) - vec3(1920.0, 1080.0, 1080.0)),
        //Vector for undistorted coordinates
        v;
        //Shift camera back 7 units (originally 9)
        p.z += 7.0; // Using the value from the previous modification
        //Save coordinates
        v = p;
        //Apply turbulence waves
        for (d = 1.0; d < 9.0; d += d) {
            p += 0.5 * sin(p.yzx * d + t) / d;
        }
        //Distance to gyroid
        s = dot(cos(p), sin(p / 0.7).yzx);
        d = 0.2 * (0.01 + abs(s) - min(d = 6.0 - length(v), -d * 0.1));
        z += d;
        //Coloring and glow attenuation
        O += (cos(s / 0.1 + z + t + vec4(2.0, 4.0, 5.0, 0.0)) + 1.2) / d / z;
    }
    //Tanh tonemapping with increased brightness and transparency for dark areas
    O = tanh(O / 1500.0);

    // Make dark areas transparent based on luminance
    float luminance = (O.r + O.g + O.b) / 3.0;
    O.a = smoothstep(0.05, 0.2, luminance); // Alpha based on luminance
}

void main() {
    vec2 uv = v_texcoord * vec2(1920.0, 1080.0); // Scale texcoords to pixel coords
    vec4 screenColor = texture(tex, v_texcoord);

    // Check if current pixel is in waybar area
    bool inWaybar = v_texcoord.y >= waybarTop && v_texcoord.y <= waybarBottom &&
                    v_texcoord.x >= waybarLeft && v_texcoord.x <= waybarRight;

    if (inWaybar) {
        // Apply shader effect only in waybar area
        vec4 shaderColor;
        mainImage(shaderColor, uv);

        // Use a default value for overallAlpha if it's 0.0 or not set correctly
        // This helps ensure something is visible even if the uniform isn't configured.
        float effectiveAlpha = (overallAlpha == 0.0) ? 0.2 : overallAlpha; // MODIFIED: Add a fallback

        // Blend with screen texture using the shader's alpha scaled by effectiveAlpha
        fragColor = mix(screenColor, vec4(shaderColor.rgb, 1.0), shaderColor.a * effectiveAlpha); // MODIFIED: Use effectiveAlpha
    } else {
        // Keep original screen content outside waybar area
        fragColor = screenColor;
    }
}
