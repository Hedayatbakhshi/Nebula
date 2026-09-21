#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float cornerRadius;
    float edgeWidth;
    float refraction;
    float aberration;
    float blurAmount;
    float specular;
    float glassAlpha;
    float bevel;
    float saturation;
    float rimLight;
    float innerShadow;
    float useMask;
    vec2 rectOrigin;
    vec2 rectSize;
    vec2 screenSize;
    vec4 tintColor;
    vec4 srcCrop;
};

layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D shapeMask;

float sdRoundRect(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

vec2 screenUV(vec2 px) {
    return (rectOrigin + px) / screenSize * srcCrop.xy + srcCrop.zw;
}

vec3 tap(vec2 px) {
    return texture(source, screenUV(px)).rgb;
}

vec3 sampleBlur(vec2 px, float radius) {
    if (radius < 0.5)
        return tap(px);

    float ro = radius;
    float ri = radius * 0.5;

    vec3 acc = tap(px) * 2.0;

    acc += tap(px + vec2( 0.000,  1.000) * ro);
    acc += tap(px + vec2( 0.866,  0.500) * ro);
    acc += tap(px + vec2( 0.866, -0.500) * ro);
    acc += tap(px + vec2( 0.000, -1.000) * ro);
    acc += tap(px + vec2(-0.866, -0.500) * ro);
    acc += tap(px + vec2(-0.866,  0.500) * ro);

    acc += tap(px + vec2( 0.500,  0.866) * ri) * 1.5;
    acc += tap(px + vec2( 1.000,  0.000) * ri) * 1.5;
    acc += tap(px + vec2( 0.500, -0.866) * ri) * 1.5;
    acc += tap(px + vec2(-0.500, -0.866) * ri) * 1.5;
    acc += tap(px + vec2(-1.000,  0.000) * ri) * 1.5;
    acc += tap(px + vec2(-0.500,  0.866) * ri) * 1.5;

    return acc / 17.0;
}

float maskAt(vec2 uv) {
    return texture(shapeMask, uv).a;
}

void main() {
    vec2 px = qt_TexCoord0 * rectSize;
    vec2 halfSize = rectSize * 0.5;

    float band;
    vec2 grad;
    float cover;
    float alphaMask;

    if (useMask > 0.5) {
        vec2 uv = qt_TexCoord0;
        vec2 stepUV = vec2(edgeWidth * 0.6) / max(rectSize, vec2(1.0));
        float m = maskAt(uv);

        float s0 = maskAt(uv + vec2( 1.000,  0.000) * stepUV);
        float s1 = maskAt(uv + vec2( 0.707,  0.707) * stepUV);
        float s2 = maskAt(uv + vec2( 0.000,  1.000) * stepUV);
        float s3 = maskAt(uv + vec2(-0.707,  0.707) * stepUV);
        float s4 = maskAt(uv + vec2(-1.000,  0.000) * stepUV);
        float s5 = maskAt(uv + vec2(-0.707, -0.707) * stepUV);
        float s6 = maskAt(uv + vec2( 0.000, -1.000) * stepUV);
        float s7 = maskAt(uv + vec2( 0.707, -0.707) * stepUV);

        float t0 = maskAt(uv + vec2( 0.924,  0.383) * stepUV * 0.5);
        float t1 = maskAt(uv + vec2( 0.383,  0.924) * stepUV * 0.5);
        float t2 = maskAt(uv + vec2(-0.383,  0.924) * stepUV * 0.5);
        float t3 = maskAt(uv + vec2(-0.924,  0.383) * stepUV * 0.5);
        float t4 = maskAt(uv + vec2(-0.924, -0.383) * stepUV * 0.5);
        float t5 = maskAt(uv + vec2(-0.383, -0.924) * stepUV * 0.5);
        float t6 = maskAt(uv + vec2( 0.383, -0.924) * stepUV * 0.5);
        float t7 = maskAt(uv + vec2( 0.924, -0.383) * stepUV * 0.5);

        cover = (m + s0 + s1 + s2 + s3 + s4 + s5 + s6 + s7
                   + t0 + t1 + t2 + t3 + t4 + t5 + t6 + t7) / 17.0;
        if (cover < 0.001) {
            fragColor = vec4(0.0);
            return;
        }

        vec2 g = vec2( 1.000,  0.000) * (m - s0)
               + vec2( 0.707,  0.707) * (m - s1)
               + vec2( 0.000,  1.000) * (m - s2)
               + vec2(-0.707,  0.707) * (m - s3)
               + vec2(-1.000,  0.000) * (m - s4)
               + vec2(-0.707, -0.707) * (m - s5)
               + vec2( 0.000, -1.000) * (m - s6)
               + vec2( 0.707, -0.707) * (m - s7)
               + vec2( 0.924,  0.383) * (m - t0)
               + vec2( 0.383,  0.924) * (m - t1)
               + vec2(-0.383,  0.924) * (m - t2)
               + vec2(-0.924,  0.383) * (m - t3)
               + vec2(-0.924, -0.383) * (m - t4)
               + vec2(-0.383, -0.924) * (m - t5)
               + vec2( 0.383, -0.924) * (m - t6)
               + vec2( 0.924, -0.383) * (m - t7);

        grad = normalize(g + vec2(1e-6));
        band = clamp((cover - 0.5) * 2.0, 0.0, 1.0);
        alphaMask = smoothstep(0.35, 0.65, m);
    } else {
        vec2 p = px - halfSize;
        float r = min(cornerRadius, min(halfSize.x, halfSize.y));
        float d = sdRoundRect(p, halfSize, r);

        float e = 1.5;
        vec2 g = vec2(
            sdRoundRect(p + vec2(e, 0.0), halfSize, r) - sdRoundRect(p - vec2(e, 0.0), halfSize, r),
            sdRoundRect(p + vec2(0.0, e), halfSize, r) - sdRoundRect(p - vec2(0.0, e), halfSize, r)
        );
        grad = normalize(g + vec2(1e-6));
        band = clamp(-d / max(edgeWidth, 1.0), 0.0, 1.0);

        float aa = fwidth(d) + 0.5;
        cover = 1.0 - smoothstep(-aa, aa, d);
        alphaMask = cover;
    }

    float lens = sqrt(max(0.0, 1.0 - band * band));
    float curve = mix(pow(1.0 - band, 1.6), lens, clamp(bevel, 0.0, 1.0));

    vec2 disp = grad * curve * refraction;
    vec2 caOff = grad * curve * aberration;

    vec3 col;
    col.r = sampleBlur(px + disp + caOff, blurAmount).r;
    col.g = sampleBlur(px + disp,         blurAmount).g;
    col.b = sampleBlur(px + disp - caOff, blurAmount).b;

    float grey = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(grey), col, saturation);

    vec3 n = normalize(vec3(grad * curve, 0.6));
    vec3 lightDir = normalize(vec3(-0.6, 0.75, 0.55));
    float ndl = dot(n, lightDir);

    float spec = pow(max(ndl, 0.0), 12.0);
    float rim = smoothstep(0.0, 0.9, curve);
    col += spec * specular * rim * 1.4;

    float edgeLine = smoothstep(0.72, 1.0, curve);
    col += edgeLine * rimLight * max(ndl, 0.0);
    col *= 1.0 - edgeLine * innerShadow * max(-ndl, 0.0);

    col = mix(col, tintColor.rgb, tintColor.a);

    float a = clamp(glassAlpha, 0.0, 1.0) * clamp(alphaMask, 0.0, 1.0);
    fragColor = vec4(col * a, a) * qt_Opacity;
}
