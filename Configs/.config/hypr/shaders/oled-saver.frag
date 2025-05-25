// Credit: https://github.com/mklan/hyproled/blob/main/hyproled
// LICENSE: BSD-3-Clause

/*
To override these parameters, create a file named './oled.inc'
We only need to match the file name and use 'inc' to indicate that
this is an "include" file.
┌────────────────────────────────────────────────────────────────────────────┐
│ //file: ./oled.inc                                                         │
│ // OLED Protection Shader Parameters                                       │
│                                                                            │
│ // OLED_MONITOR: -1 for all monitors, or set to a specific monitor index   │
│ #define OLED_MONITOR -1                                                    │
│                                                                            │
│ // OLED_FILL_COLOR: Fill color for checker pattern (vec4 RGBA, 0-1 range)  │
│ // Example: Black = vec4(0.,0.,0.,1.), White = vec4(1.,1.,1.,1.)       │
│ #define OLED_FILL_COLOR vec4(0.,0.,0.,1.)                                │
│                                                                            │
│ // OLED_SWAP_INTERVAL: Swap interval in seconds (recommended: 5–10)        │
│ #define OLED_SWAP_INTERVAL 10.0                                            │
│                                                                            │
│ // OLED_PIXEL_SIZE: Size of each checker square (1.0 = 1px, higher =       │
│ bigger)                                                                    │
│ #define OLED_PIXEL_SIZE 1.0                                                │
│                                                                            │
│ // Optional: Swap pattern logic (uncomment to invert logic)                │
│ // #define OLED_SWAP_PIXELS                                                │
│                                                                            │
│ // Optional: Restrict effect to area (vec4(x, y, w, h)), in px             │
│ // #define OLED_AREA 0.,0.,1920.,1080.                                     │
│                                                                            │
│ // Optional: Invert area logic (uncomment to invert area mask)             │
│ // #define OLED_INVERT_AREA                                                │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
*/

#ifndef OLED_MONITOR
#define OLED_MONITOR-1
#endif

#ifndef OLED_FILL_COLOR
#define OLED_FILL_COLOR vec4(0.,0.,0.,1.)
#endif

#ifndef OLED_SWAP_INTERVAL
#define OLED_SWAP_INTERVAL 10.0// Interval in seconds
#endif

#ifndef OLED_PIXEL_SIZE
#define OLED_PIXEL_SIZE 1.
#endif

precision highp float;
varying vec2 v_texcoord;
uniform sampler2D tex;
uniform int wl_output;
uniform float time;

void main(){
    vec4 originalColor=texture2D(tex,v_texcoord);
    
    // If OLED_MONITOR is -1, always enable effect. Otherwise, only for matching monitor.
    if(OLED_MONITOR!=-1&&wl_output!=OLED_MONITOR){
        gl_FragColor=originalColor;
        return;
    }
    
    vec2 fragCoord=gl_FragCoord.xy;
    
    // Animation: swap pattern every OLED_SWAP_INTERVAL seconds
    bool swapPhase=mod(floor(time/OLED_SWAP_INTERVAL),2.)==1.;
    float checkerX=floor(fragCoord.x/OLED_PIXEL_SIZE);
    float checkerY=floor(fragCoord.y/OLED_PIXEL_SIZE);
    bool isEvenPixel=mod(checkerX+checkerY,2.)==0.;
    
    #ifdef OLED_SWAP_PIXELS
    vec4 color=(swapPhase?(isEvenPixel?originalColor:OLED_FILL_COLOR)
    :(isEvenPixel?OLED_FILL_COLOR:originalColor));
    #else
    vec4 color=(swapPhase?(isEvenPixel?OLED_FILL_COLOR:originalColor)
    :(isEvenPixel?originalColor:OLED_FILL_COLOR));
    #endif
    
    #ifdef OLED_AREA
    const vec4 area=vec4(OLED_AREA);
    bool inArea=fragCoord.x>=area.x&&fragCoord.x<=(area.x+area.z)&&
    fragCoord.y>=area.y&&fragCoord.y<=(area.y+area.w);
    #ifdef OLED_INVERT_AREA
    gl_FragColor=inArea?originalColor:color;
    #else
    gl_FragColor=inArea?color:originalColor;
    #endif
    #else
    gl_FragColor=color;
    #endif
}