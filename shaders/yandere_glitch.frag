#version 460 core

#include <flutter/runtime_effect.glsl>

// Uniforms layout:
// 0: float u_time
// 1, 2: vec2 u_resolution
// 3: float u_corruption
// 4: float u_mania
// 5, 6: vec2 u_touch_pos
// 7: float u_heartbeat_pulse
uniform float u_time;
uniform vec2 u_resolution;
uniform float u_corruption;
uniform float u_mania;
uniform vec2 u_touch_pos;
uniform float u_heartbeat_pulse;

out vec4 fragColor;

// High-precision pseudo-random hash
float hash21(vec2 p) {
    p = fract(p * vec2(234.56, 789.12));
    p += dot(p, p + 34.56);
    return fract(p.x * p.y);
}

// Block noise for digital datamoshing
float blockNoise(vec2 uv, float scale, float timeSeed) {
    vec2 grid = floor(uv * scale);
    return hash21(grid + vec2(floor(timeSeed * 14.0), floor(timeSeed * 7.0)));
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 res = max(u_resolution, vec2(1.0));
    vec2 uv = fragCoord / res;

    // Normalized touch position (fallback to screen center if untouched)
    vec2 touchUV = clamp(u_touch_pos / res, vec2(0.0), vec2(1.0));
    float distToTouch = length(uv - touchUV);

    // 1. Rhythmic Zoom Pulse synchronized with Haptic Heartbeat
    vec2 centered = uv - 0.5;
    float zoomFactor = 1.0 - (u_heartbeat_pulse * (0.012 + u_corruption * 0.035));
    vec2 zoomedUV = centered * zoomFactor + 0.5;

    // 2. Digital Datamoshing & Non-linear UV Block Displacement (High Corruption)
    float moshIntensity = clamp(u_corruption * 0.75 + u_mania * 0.45, 0.0, 1.0);
    float scanBlock = blockNoise(vec2(zoomedUV.y, 0.5), 28.0, u_time);
    float subBlock = blockNoise(zoomedUV, vec2(16.0, 36.0).x, u_time * 1.5);

    float tearThreshold = 1.0 - moshIntensity * 0.38;
    vec2 moshedUV = zoomedUV;
    float isTorn = 0.0;
    if (scanBlock > tearThreshold) {
        isTorn = 1.0;
        float shift = (scanBlock - tearThreshold) * 0.18 * sign(sin(u_time * 43.0 + zoomedUV.y * 64.0));
        moshedUV.x = fract(moshedUV.x + shift);
    }
    if (u_corruption > 0.50 && subBlock > (1.05 - moshIntensity * 0.35)) {
        moshedUV.y = fract(moshedUV.y + (subBlock - 0.5) * 0.06 * u_mania);
    }

    // 3. Radial Chromatic Split from Last Touch Point
    vec2 radialDir = normalize((moshedUV - touchUV) + vec2(0.0001));
    float radialFalloff = smoothstep(0.65, 0.0, distToTouch);
    float chromaOffset = (0.003 + u_corruption * 0.018 + u_mania * 0.014) * (0.4 + radialFalloff * 1.2);

    vec2 uvR = moshedUV + radialDir * chromaOffset;
    vec2 uvG = moshedUV;
    vec2 uvB = moshedUV - radialDir * chromaOffset;

    float rPattern = sin(uvR.x * 48.0 + u_time * 8.0) * cos(uvR.y * 32.0 - u_time * 5.0);
    float gPattern = sin(uvG.x * 48.0 - u_time * 6.0) * cos(uvG.y * 32.0 + u_time * 4.0);
    float bPattern = sin(uvB.x * 48.0 - u_time * 10.0) * cos(uvB.y * 32.0 + u_time * 7.0);

    // 4. LCD Subpixel Grid & VHS Scanlines
    vec2 pixelPos = floor(fragCoord);
    float subpixelMod = mod(pixelPos.x, 3.0);
    vec3 lcdMask = vec3(
        subpixelMod < 1.0 ? 1.0 : 0.88,
        (subpixelMod >= 1.0 && subpixelMod < 2.0) ? 1.0 : 0.88,
        subpixelMod >= 2.0 ? 1.0 : 0.88
    );
    float scanline = 0.5 + 0.5 * sin(moshedUV.y * res.y * 1.4 + u_time * 14.0);

    // 5. Dreamy Halation & Kawaii Vignette (Low Corruption) vs Yandere Abyss (High Corruption)
    float edgeDist = length(centered);
    float dreamyHalation = smoothstep(0.18, 0.78, edgeDist) * (1.0 - u_corruption * 0.7);
    float horrorVignette = smoothstep(0.28, 0.86, edgeDist) * (0.15 + u_corruption * 0.65 + u_mania * 0.20);

    vec3 dreamyPink = vec3(1.0, 0.718, 0.773);    // #FFB7C5
    vec3 lavenderBlush = vec3(1.0, 0.941, 0.961); // #FFF0F5
    vec3 cyberCrimson = vec3(1.0, 0.0, 0.333);    // #FF0055
    vec3 glitchCyan = vec3(0.0, 0.941, 1.0);      // #00F0FF
    vec3 voidBlack = vec3(0.051, 0.008, 0.031);   // #0D0208

    vec3 baseTint = mix(
        mix(lavenderBlush, dreamyPink, dreamyHalation),
        voidBlack,
        smoothstep(0.25, 0.78, u_corruption)
    );

    // Inject radial chromatic aberration channels
    vec3 chromaGlow = vec3(
        max(0.0, rPattern) * cyberCrimson.r + max(0.0, bPattern) * glitchCyan.r,
        max(0.0, gPattern) * 0.35 + max(0.0, bPattern) * glitchCyan.g,
        max(0.0, rPattern) * cyberCrimson.b + max(0.0, bPattern) * glitchCyan.b
    );

    vec3 color = baseTint * lcdMask;
    color += chromaGlow * (moshIntensity * 0.42 + isTorn * 0.55 + radialFalloff * u_corruption * 0.35);

    // Touch ripple ring
    float touchRing = smoothstep(0.04, 0.0, abs(distToTouch - fract(u_time * 0.8) * 0.25)) *
                      smoothstep(0.28, 0.0, distToTouch);
    color += mix(dreamyPink, cyberCrimson, u_corruption) * touchRing * 0.35;

    // Heartbeat border pulse
    float heartBorder = smoothstep(0.32, 0.78, edgeDist) * u_heartbeat_pulse;
    color += mix(dreamyPink, cyberCrimson, clamp(u_corruption * 1.4, 0.0, 1.0)) * heartBorder * 0.48;

    // Static snow grain on high mania
    float grain = hash21(moshedUV * res + vec2(u_time * 137.0, u_time * 89.0));
    if (grain > (0.988 - moshIntensity * 0.10)) {
        color = mix(color, mix(dreamyPink, glitchCyan, u_corruption), 0.75);
    }

    float scanlineAlpha = (1.0 - scanline) * mix(0.03, 0.18, u_corruption);
    float halationAlpha = dreamyHalation * 0.14 * (1.0 - u_corruption);
    float finalAlpha = clamp(
        halationAlpha +
        scanlineAlpha +
        horrorVignette * 0.52 +
        isTorn * 0.28 * moshIntensity +
        heartBorder * 0.30 +
        touchRing * 0.16,
        0.0,
        0.74
    );

    fragColor = vec4(color * finalAlpha, finalAlpha);
}
