#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    float progress;
    float mode;
    vec2 origin;
    vec2 dir;
};

layout(binding = 1) uniform sampler2D fromTex;
layout(binding = 2) uniform sampler2D toTex;

const float EDGE = 56.0;
const float WAVE_AMP = 34.0;
const float WAVE_LEN = 260.0;
const float TAU = 6.28318530718;

float farCorner(vec2 o) {
    vec2 s = itemSize;
    return max(max(length(o), length(o - vec2(s.x, 0.0))),
               max(length(o - vec2(0.0, s.y)), length(o - s)));
}

void main() {
    vec2 p = qt_TexCoord0 * itemSize;
    float m;

    if (mode < 0.5) {
        m = progress;
    } else if (mode < 2.5) {
        float s = dot(p, dir);
        float pad = EDGE;
        if (mode > 1.5) {
            vec2 perp = vec2(-dir.y, dir.x);
            s += sin(dot(p, perp) / WAVE_LEN * TAU) * WAVE_AMP;
            pad += WAVE_AMP;
        }
        vec2 c = itemSize;
        float lo = min(min(0.0, dot(vec2(c.x, 0.0), dir)), min(dot(vec2(0.0, c.y), dir), dot(c, dir)));
        float hi = max(max(0.0, dot(vec2(c.x, 0.0), dir)), max(dot(vec2(0.0, c.y), dir), dot(c, dir)));
        float front = mix(lo - pad, hi + pad, progress);
        m = 1.0 - smoothstep(front - EDGE, front, s);
    } else if (mode < 3.5) {
        float r = mix(-EDGE, farCorner(origin) + EDGE, progress);
        m = 1.0 - smoothstep(r - EDGE, r, distance(p, origin));
    } else {
        float r = mix(farCorner(origin) + EDGE, -EDGE, progress);
        m = smoothstep(r - EDGE, r, distance(p, origin));
    }

    fragColor = mix(texture(fromTex, qt_TexCoord0), texture(toTex, qt_TexCoord0), clamp(m, 0.0, 1.0)) * qt_Opacity;
}
