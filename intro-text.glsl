float circle(vec2 p, float radius, float softness) {
    float result = length(p);
    result = smoothstep(radius, radius + softness, result);

    return result;
}

float circle(vec2 p, float radius) {
    return circle(p, radius, 0.005);
}

float rect(vec2 p, vec2 dimensions, float softness) {
    p /= dimensions;

    float result = max(abs(p.x), abs(p.y));

    result = smoothstep(0.5, 0.5 + softness, result);

    return result;
}

float rect(vec2 p, vec2 dimensions) {
    return rect(p, dimensions, 0.0075);
}

float mask(float direction) {
    return 1.0 - smoothstep(0.0, 0.005, direction);
}

float rightHalfCircle(vec2 p, float radius) {
    return max(mask(p.x), circle(p, radius));
}

float leftHalfCircle(vec2 p, float radius) {
    return max(1.0 - mask(p.x), circle(p, radius));
}

float upHalfCircle(vec2 p, float radius) {
    return max(mask(p.y), circle(p, radius));
}

float downHalfCircle(vec2 p, float radius) {
    return max(1.0 - mask(p.y), circle(p, radius));
}

float r(vec2 p) {
    float result = 10000.0;

    result = min(result, circle(p - vec2(0.27, 0.25), 0.124));
    result = min(result, rect(p, vec2(0.25, 0.75)));

    return result;
}

float o(vec2 p) {
    float result = 10000.0;
    result = min(result, circle(p, 0.25));
    return result;
}

float h(vec2 p) {
    float result = 10000.0;
    result = min(result, rect(p - vec2(1.1, 0.025), vec2(0.25, 0.8)));
    result = min(result, rightHalfCircle(p - vec2(1.24, -0.15), 0.25));
    result = min(result, rect(p - vec2(1.3675, -0.34), vec2(0.2475, 0.45)));
    return result;
}

float t(vec2 p) {
    float result = 10000.0;
    result = min(result, rect(p - vec2(1.85, 0.0), vec2(0.25, 0.75)));
    result = min(result, upHalfCircle(p - vec2(1.58, 0.15), 0.124));
    return result;
}

float i(vec2 p) {
    float result = 10000.0;

    result = min(result, rect(p, vec2(0.25, 0.5)));
    result = min(result, downHalfCircle(p - vec2(0.0, 0.55), 0.124));

    return result;
}

float e(vec2 p) {
    float result = 10000.0;

    result = min(result, upHalfCircle(p - vec2(0.0, 0.0), 0.25));
    result = min(result, max(1.0 - mask(p.x - 0.025), downHalfCircle(p - vec2(0.0, - 0.015), 0.25)));

    return result;
}

float m(vec2 p) {
    float result = 10000.0;

    result = min(result, rect(p - vec2(0.0, -0.075), vec2(0.25, 0.6)));
    result = min(result, rightHalfCircle(p - vec2(0.145, -0.12), 0.25));
    result = min(result, rect(p - vec2(0.2725, -0.25), vec2(0.246, 0.25)));
    result = min(result, rightHalfCircle(p - vec2(0.415, -0.22), 0.25));
    result = min(result, rect(p - vec2(0.542, -0.35), vec2(0.246, 0.25)));

    return result;
}

float y(vec2 p) {
    float result = 10000.0;

    result = min(result, leftHalfCircle(p - vec2(0.115, 0.025), 0.25));
    result = min(result, rect(p - vec2(-0.006, 0.15), vec2(0.246, 0.25)));

    result = min(result, leftHalfCircle(p - vec2(0.395, -0.01), 0.25));
    result = min(result, rightHalfCircle(p - vec2(0.145, -0.242), 0.25));
    result = min(result, rect(p - vec2(0.03, -0.368), vec2(0.246, 0.25)));

    return result;
}

float c(vec2 p) {
    float result = 10000.0;

    result = min(result, leftHalfCircle(p - vec2(0.0, 0.0), 0.25));

    return result;
}

float l(vec2 p) {
    float result = 10000.0;

    result = min(result, rect(p - vec2(0.0, 0.03), vec2(0.25, 0.75)));

    return result;
}

float u(vec2 p) {
    float result = 10000.0;

    result = min(result, leftHalfCircle(p - vec2(0.0, 0.0), 0.25));
    result = min(result, rightHalfCircle(p - vec2(0.025, 0.0), 0.25));

    result = min(result, rect(p - vec2(-0.13, 0.125), vec2(0.246, 0.25)));
    result = min(result, rect(p - vec2(0.155, 0.125), vec2(0.246, 0.25)));

    return result;
}

float b(vec2 p) {
    float result = 10000.0;

    result = min(result, rect(p - vec2(-0.13, 0.125), vec2(0.25, 0.75)));
    result = min(result, rightHalfCircle(p - vec2(0.025, 0.0), 0.25));

    return result;
}

float rohtie(vec2 p) {
    p.x -= 0.125;

    p /= 0.415;

    //p.x += sin(p.y * mod(-iGlobalTime * 0.25, 1.0) * 50.0 + iGlobalTime) * 0.25;

    float result = 10000.0;

    result = min(result, r(p - vec2(0.05, 0.0)));
    result = min(result, o(p - vec2(0.65, -0.075)));
    result = min(result, h(p - vec2(0.05, 0.0)));
    result = min(result, t(p - vec2(0.0, 0.0)));
    result = min(result, i(p - vec2(2.25, -0.125)));
    result = min(result, e(p - vec2(2.77, -0.075)));

    return result;
}

float mycelium(vec2 p) {
    p.x += 0.215;

    p /= 0.35;

    float result = 10000.0;

    result = min(result, m(p - vec2(-1.55, 0.0)));
    result = min(result, y(p - vec2(-0.65, -0.125)));
    result = min(result, c(p - vec2(0.1, -0.125)));
    result = min(result, e(p - vec2(0.45, -0.125)));
    result = min(result, l(p - vec2(0.9, -0.125)));
    result = min(result, i(p - vec2(1.25, -0.125)));
    result = min(result, u(p - vec2(1.75, -0.125)));
    result = min(result, m(p - vec2(2.25, 0.0)));

    return result;
}

float by(vec2 p) {
    p /= 0.25;

    float result = 10000.0;

    result = min(result, b(p - vec2(-0.25, 0.0)));
    result = min(result, y(p - vec2(0.25, 0.0)));

    return result;
}

float text(vec2 p) {
    float time = mod(iGlobalTime * 0.25, 6.0);
    float result = 0.0;

    float blank = length(p);

    float a, b;

    float mycelium = mycelium(p  - vec2(0.0, 0.05));
    float by = by(p);
    float rohtie = rohtie(p - vec2(-0.75, 0.0));

    float mixTime = mod(time, 1.0);

    if (time < 1.0) {
        a = blank;
        b = mycelium;
    }
    else if (time < 2.0) {
        a = mycelium;
        b = by;
    }
    else if (time < 3.0) {
        a = by;
        b = rohtie;
    }
    else if (time < 5.0) {
        mixTime = mod(time, 3.0);
        a = rohtie;
        b = blank;
    }

    result = 1.0 - mix(a, b, mixTime);

    return result;
}

void mainImage( out vec4 o, in vec2 p ) {
    p /= iResolution.xy;
    p -= 0.5;
    p.x *= iResolution.x / iResolution.y;

    float result = text(p);

    o.rgb = (
        result * vec3(0.15 + abs(p.x), 0.75 + p.y, (1.0 + p.y) * 0.5)
        + (1.0 - result) * vec3((0.75 + p.y) * 0.6, 0.0, abs(p.x) * 0.25)
        + length(p) * vec3(0.75, 0.25, 1.0) * 0.15
    );

    o.rgb += text(p) * 0.4;

    p.x += texture(iChannel0, (p.yy + 0.25) / 1.5).r;
    o.r += text(p);
}
