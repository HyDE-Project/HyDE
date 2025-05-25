/* 
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ This is a blank shader to disable hyprland shaders.                     │
  └─────────────────────────────────────────────────────────────────────────┘
 */

precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
    gl_FragColor = texture2D(tex, v_texcoord);
}
