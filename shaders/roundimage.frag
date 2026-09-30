#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    vec2 imageSize;
    float radius;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 img = max(imageSize, vec2(1.0));
    float s = max(itemSize.x / img.x, itemSize.y / img.y);
    vec2 vis = itemSize / (img * s);
    vec2 uv = (1.0 - vis) * 0.5 + qt_TexCoord0 * vis;

    vec2 p = qt_TexCoord0 * itemSize;
    vec2 half_ = itemSize * 0.5;
    float r = min(radius, min(half_.x, half_.y));
    vec2 q = abs(p - half_) - (half_ - vec2(r));
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
    float a = 1.0 - smoothstep(-0.75, 0.75, d);

    fragColor = texture(source, uv) * a * qt_Opacity;
}
