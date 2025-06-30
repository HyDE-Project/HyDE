/* 
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ This is a blank shader to disable hyprland shaders.                     │
  └─────────────────────────────────────────────────────────────────────────┘
 */

#version 300 es
precision mediump float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;

void main() {
    fragColor = texture(tex, v_texcoord);
}