#version 440
// Liquid glass fragment shader for cartoon-shell.
// Convex "squircle" bevel refraction + chromatic dispersion + frosted blur
// + tint/saturation + specular rim + cursor glow + soft drop shadow.
// Uniform names match the properties declared in components/glass/LiquidGlass.qml.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    vec4 radii;         // top-left, top-right, bottom-right, bottom-left (px)
    vec4 srcRect;       // x, y, w, h of the sampled area, normalised to the backdrop texture
    vec4 sampleBounds;  // x0, y0, x1, y1 valid region of the backdrop (normalised)
    vec4 box;           // centre offset (xy) + half size (zw) of the glass body; zw = 0 -> whole item
    vec4 tintColor;
    vec2 itemSize;
    vec2 cursor;
    float qt_Opacity;
    float tintAmount;
    float bezel;
    float thickness;
    float ior;
    float dispersion;
    float frost;
    float rim;
    float saturation;
    float hover;
    float clear;
    float glassPad;
    float shadowAmt;
    float energy;
    float nest;
    float motion;
};

layout(binding = 1) uniform sampler2D src;

// Signed distance to a rounded rectangle centred on the origin (y grows downwards).
float sdRoundRect(vec2 p, vec2 hs, vec4 r) {
    float rad = (p.x < 0.0) ? ((p.y < 0.0) ? r.x : r.w) : ((p.y < 0.0) ? r.y : r.z);
    rad = min(rad, min(hs.x, hs.y));
    vec2 q = abs(p) - hs + vec2(rad);
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - rad;
}

vec3 grade(vec4 c, vec3 fallback) {
    // Un-premultiply and fade to the tint where the backdrop is not covered (rounded corners).
    vec3 rgb = c.rgb / max(c.a, 0.001);
    return mix(fallback, rgb, smoothstep(0.0, 0.6, c.a));
}

vec3 sampleFrost(vec2 uv, float lod, vec2 lo, vec2 hi, vec3 fallback) {
    vec2 texel = 1.0 / vec2(textureSize(src, 0));
    vec2 o = texel * (exp2(lod) * 0.55);
    vec2 m = texel * 1.5;
    vec2 a = lo + m;
    vec2 b = max(hi - m, a);
    vec4 c = textureLod(src, clamp(uv, a, b), lod) * 0.36;
    c += textureLod(src, clamp(uv + vec2( o.x, 0.0), a, b), lod) * 0.16;
    c += textureLod(src, clamp(uv + vec2(-o.x, 0.0), a, b), lod) * 0.16;
    c += textureLod(src, clamp(uv + vec2(0.0,  o.y), a, b), lod) * 0.16;
    c += textureLod(src, clamp(uv + vec2(0.0, -o.y), a, b), lod) * 0.16;
    return grade(c, fallback);
}

void main() {
    vec2 px = qt_TexCoord0 * itemSize;
    vec2 center = itemSize * 0.5;
    vec2 hs = itemSize * 0.5 - vec2(glassPad);
    if (box.z > 0.0 && box.w > 0.0) {
        center += box.xy;
        hs = box.zw;
    }
    vec2 p = px - center;
    float sd = sdRoundRect(p, hs, radii);

    // ---- soft drop shadow (only in the padding around the glass) -------------------------
    float shadowA = 0.0;
    if (shadowAmt > 0.0 && glassPad > 0.0) {
        float sdo = sdRoundRect(p - vec2(0.0, glassPad * 0.3), hs, radii);
        float f = 1.0 - smoothstep(-glassPad * 0.15, glassPad, sdo);
        shadowA = shadowAmt * 0.34 * f * f;
    }

    float mask = 1.0 - smoothstep(-0.6, 0.6, sd);
    if (mask <= 0.0) {
        fragColor = vec4(0.0, 0.0, 0.0, shadowA) * qt_Opacity;
        return;
    }

    // ---- bevel geometry -------------------------------------------------------------------
    float B = max(bezel, 1.0);
    float d = max(-sd, 0.0);                 // distance inside the glass edge
    float x = clamp(d / B, 0.0, 1.0);

    vec2 e = vec2(1.0, 0.0);
    vec2 g = vec2(sdRoundRect(p + e.xy, hs, radii) - sdRoundRect(p - e.xy, hs, radii),
                  sdRoundRect(p + e.yx, hs, radii) - sdRoundRect(p - e.yx, hs, radii));
    g = g / max(length(g), 1e-4);            // outward 2D normal

    // Convex squircle height profile: h(0)=0 at the rim, h(1)=1 where the bevel ends.
    float omx = 1.0 - x;
    float o4 = omx * omx * omx * omx;
    float h = pow(max(1.0 - o4, 0.0), 0.25);
    float slope = (omx * omx * omx) / pow(max(1.0 - o4, 0.02), 0.75);
    slope = min(slope, 6.0);

    float T = max(thickness, 0.0) * (1.0 - 0.35 * nest);
    vec3 N = normalize(vec3(g * (T / B) * slope, 1.0));
    vec3 R = refract(vec3(0.0, 0.0, -1.0), N, 1.0 / max(ior, 1.01));
    vec2 offs = R.xy / max(-R.z, 0.2) * (T * h);

    // ---- frosted, dispersed sampling ------------------------------------------------------
    float k = dispersion + motion * 0.05;
    float lod = max(frost * mix(1.0, 0.6, clear) + motion * 1.2, 0.0);
    vec2 lo = sampleBounds.xy;
    vec2 hi = sampleBounds.zw;
    vec3 fb = tintColor.rgb;

    vec2 uvR = srcRect.xy + ((px + offs * (1.0 + 2.0 * k)) / itemSize) * srcRect.zw;
    vec2 uvG = srcRect.xy + ((px + offs) / itemSize) * srcRect.zw;
    vec2 uvB = srcRect.xy + ((px + offs * (1.0 - 2.0 * k)) / itemSize) * srcRect.zw;
    vec3 col;
    col.r = sampleFrost(uvR, lod, lo, hi, fb).r;
    col.g = sampleFrost(uvG, lod, lo, hi, fb).g;
    col.b = sampleFrost(uvB, lod, lo, hi, fb).b;

    // ---- colour grading -------------------------------------------------------------------
    float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
    col = mix(vec3(luma), col, saturation);
    col = mix(col, tintColor.rgb, clamp(tintAmount * mix(1.0, 0.5, clear), 0.0, 1.0));

    // ---- specular rim ---------------------------------------------------------------------
    float edgeBand = 1.0 - smoothstep(0.0, B, d);
    float hairline = exp(-d / 1.2);
    vec2 L = normalize(vec2(-0.55, -0.83));
    float litA = pow(max(dot(g, L), 0.0), 1.6);
    float litB = pow(max(dot(g, -L), 0.0), 2.2) * 0.45;
    float spec = (litA + litB) * (hairline + edgeBand * 0.28);
    float rimK = rim * (1.0 - 0.35 * nest) * (1.0 + energy * 0.8);
    col += vec3(spec * rimK);
    col += vec3(hairline * 0.07 * rimK);

    // ---- cursor glow + press energy -------------------------------------------------------
    if (hover > 0.0) {
        float R2 = max(max(itemSize.x, itemSize.y) * 0.45, 60.0);
        float dc = length(px - cursor);
        float glow = exp(-(dc * dc) / (R2 * R2));
        col += vec3(hover * glow * 0.06 * (1.0 + edgeBand * 1.5));
    }
    col += vec3(energy * 0.05);

    col = clamp(col, 0.0, 1.0);

    // composite glass over its shadow (premultiplied alpha)
    vec4 glass = vec4(col * mask, mask);
    vec4 outc = glass + vec4(0.0, 0.0, 0.0, shadowA) * (1.0 - mask);
    fragColor = outc * qt_Opacity;
}
