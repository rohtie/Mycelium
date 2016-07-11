struct Material {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

Material defaultMaterial = Material(
    vec3(1.25, 0.41, 0.15),
    vec3(2.7, 1.0, 0.95),
    vec3(1.0)
);
Material hatMaterial = Material(
    vec3(0.5, 0.0, 0.0),
    vec3(0.75, 0.5, 0.0),
    vec3(1.0)
);
Material stemMaterial = Material(
    vec3(0.0, 1.0, 0.0),
    vec3(3.0, 1.25, 0.75),
    vec3(1.0)
);
Material groundMaterial = Material(
    vec3(0.0, 0.0, 1.0),
    vec3(2.7, 1.0, 0.95),
    vec3(1.0)
);
Material hatDotsMaterial = Material(
    vec3(0.75),
    vec3(0.35),
    vec3(1.0)
);

float smin(float a, float b, float k) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec3 triPlanar(sampler2D tex, vec3 normal, vec3 p) {
    vec3 cX = texture(tex, p.yz).rgb;
    vec3 cY = texture(tex, p.xz).rgb;
    vec3 cZ = texture(tex, p.xy).rgb;

    vec3 blend = abs(normal);
    blend /= blend.x + blend.y + blend.z + 0.001;

    return blend.x * cX + blend.y * cY + blend.z * cZ;
}

mat2 rotate(float a) {
    return mat2(-sin(a), cos(a),
                 cos(a), sin(a));
}

float hash(float n) {
    return fract(sin(n)*43758.5453);
}

vec3 hash3(float n) {
    return fract(sin(vec3(n,n+1.0,n+2.0))*vec3(43758.5453123,22578.1459123,19642.3490423));
}

float noise(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0 + 113.0*p.z;

    return mix(mix(mix( hash(n+0.0), hash(n+1.0),f.x),
                   mix( hash(n+57.0), hash(n+58.0),f.x),f.y),
               mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                   mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
}

float roundBox( vec3 p, vec3 b, float r ) {
  return length(max(abs(p)-b,0.0))-r;
}

float capsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

float line(vec3 p, vec3 a, vec3 b) {
    vec3 pa = p - a;
    vec3 ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );

    return length( pa - ba*h );
}

vec3 repeat(vec3 p, vec3 c) {
    return mod(p,c)-0.5*c;
}

vec2 solve(vec2 p, float upperLimbLength, float lowerLimbLength) {
    vec2 q = p * (0.5 + 0.5 * (upperLimbLength * upperLimbLength - lowerLimbLength * lowerLimbLength) / dot(p, p));

    float s = upperLimbLength * upperLimbLength / dot(q, q) - 1.0;

    if (s < 0.0) {
        return vec2(-100.0);
    }

    return q + q.yx * vec2(-1.0, 1.0) * sqrt(s);
}

float finger(vec3 p, vec3 target, float fingerLength) {
    float firstJointLength = 2.0 * fingerLength;
    float secondJointLength = 1.65 * fingerLength;

    vec2 height = solve(target.xy, firstJointLength, secondJointLength);
    float depth = solve(target.xz, firstJointLength, secondJointLength).y;
    depth = 0.0;

    target.z = 0.0;

    vec3 joint = vec3(height, depth);

    float finger = smin(
        capsule(p, vec3(0.0, 0.0, 0.0), joint, 0.25 + length(p - joint) * 0.25),
        capsule(p, joint, target, 0.25 + length(p - target) * 0.1),
        0.25);

    vec3 lastFingerJoint = target - normalize(target) * 0.75 + normalize(target - joint);

    finger = smin(
        finger,
        capsule(
            p,
            target,
            lastFingerJoint,
            0.25 + length(p - target) * 0.1),
        0.25);

    return finger - 0.2;
}

float thumbCalc(vec3 p, vec3 target, float fingerLength) {
    float firstJointLength = 2.0 * fingerLength;
    float secondJointLength = 1.65 * fingerLength;

    vec2 height = solve(target.xy, firstJointLength, secondJointLength);
    float depth = solve(target.xz, firstJointLength, secondJointLength).y;
    depth = 0.0;

    target.z = 0.0;

    vec3 joint = vec3(height, depth);

    float finger = smin(
        capsule(p, vec3(0.0, 0.0, 0.0), joint, 0.25 + length(p - joint) * 0.25),
        capsule(p, joint, target, 0.25 + length(p - target) * 0.1),
        0.25);

    return finger - 0.5;
}

float hand(vec3 p) {
    float result = 10000.0;

    vec3 ground = p;

   // p.yz *= rotate(-abs(sin(iGlobalTime * 0.1)) * 3.14);

    vec3 d = p;
    d.zy *= rotate(3.1);
    result = smin(result, finger(d - vec3(0.0, 0.0, -6.0),
        mix(vec3(-4.3, 0.0, 0.0), vec3(-2.5, 0.0, 0.0), abs(sin(iGlobalTime * 2.0))),
        1.2
    ), 0.25);

    vec3 c = p;
    c.zy *= rotate(2.85);
    result = smin(result, finger(c - vec3(0.0, 0.0, -4.0),
        mix(vec3(-4.55, 0.0, 0.0), vec3(-2.5, 0.0, 0.0), abs(sin(iGlobalTime * 2.0))),
        1.35
    ), 0.25);

    vec3 b = p;
    b.zy *= rotate(2.75);
    result = smin(result, finger(b - vec3(0.0, 0.0, -2.0),
        mix(vec3(-4.55, 0.0, 0.0), vec3(-2.5, 0.0, 0.0), abs(sin(iGlobalTime * 2.0))),
        1.25
    ), 0.25);

    vec3 a = p;
    a.zy *= rotate(2.5);
    result = smin(result, finger(a - vec3(0.0, 0.0, 0.0),
        mix(vec3(-3.65, 0.0, 0.0), vec3(-2.5, 0.0, 3.65), abs(sin(iGlobalTime * 2.0))),
        1.0
    ), 0.25);

    //Palm
    vec3 palm = p - vec3(2.5, 3.0, -1.0);
    palm.xz *= rotate(-3.14 * 0.7);

    palm.z += sin(palm.y * 0.75 + 1.25) * 0.5;

    result = smin(result, roundBox(palm, vec3(2.0, 3.0 - palm.x * 0.2, 0.3), 0.5), 0.5);
    result = smin(result, roundBox(palm - vec3(1.5, -2.0, 0.25), vec3(0.5, 0.15, -0.25), 1.25), 0.75);
    result = smin(result, roundBox(palm - vec3(1.5, 0.5, 1.25), vec3(0.5, 0.15, -0.55), 1.25), 0.75);


    // Thumb
    vec3 thumb = p - vec3(3.0, 5.0, -3.0);
    result = smin(result, length(thumb) - 1.75, 0.5);

    thumb.zy *= rotate(3.14 * 1.75);
    result = smin(result, thumbCalc(thumb - vec3(-2.0, 0.0, 1.0),
        mix(vec3(-3.65, 0.0, 0.0), vec3(-2.5, 0.0, 3.65), abs(sin(iGlobalTime * 2.0))),
        1.0
    ), 1.0);

    // Arm
    vec3 arm = p;
    arm.xz *= rotate(-3.14 * 0.7);
    arm.z *= 1.5;
    result = smin(result, capsule(arm, vec3(6.5, 3.0, -0.5), vec3(15.0, 3.0, 0.0), 1.5 + arm.x * 0.2), 1.5);

    // Texture
    vec3 ext = repeat(p, vec3(0.15));
    result = smin(result, max(result - 0.01, length(ext) - 0.001), 0.1);

    // Ground
    // result = min(result, ground.y + 1.5);

    return result;
}

const float shroomRotation = 4.5433;

float ground(vec3 p) {
    p.y = abs(p.y);

    float waves = 25.0;
    float ground = p.y + mix(sin(p.x * waves), sin(p.z * waves), 0.5) * 0.3;

    ground += length(p) - 1.0;
    ground *= 0.25;

    ground = min(ground, p.y + mix(sin(p.x * waves), sin(p.z * waves), 0.5) * 0.05);

    return ground;
}

float stem(vec3 p) {
    p.y -= 0.5;

    float stem = capsule(p, vec3(0.0), vec3(cos(shroomRotation) * 0.25, 1.0, sin(shroomRotation) * 0.25), 0.5);
    stem += sin(p.y * 3.0 - 1.0) * 0.15;
    stem += mix(sin(p.z * 50.0 + 2.0), sin(p.x * 50.0 + 2.0), 0.5) * 0.02;

    return stem;
}

float hat(vec3 p) {
    p.y -= 2.0;

    p.z -= sin(shroomRotation) * 0.25;
    p.x -= cos(shroomRotation) * 0.25;

    float hat = length(p) - 0.75;
    hat += p.y * 1.25;

    hat = max(hat, -(p.y + 0.5));
    hat = mix(hat, length(p) - 0.75, 0.2);

    hat += mix(sin(p.z * 50.0), sin(p.x * 50.0), 0.5) * 0.01;

    vec3 c = vec3(0.25);
    p = mod(p, c) - c*0.5;

    float dots = length(p) - 0.05;

    hat += dots * 0.35;

    vec3 q = repeat(p, vec3(0.05));
    hat = smin(hat, max(hat, length(q) - 0.0001), 0.035);

    return hat;
}

float hatDots(vec3 p) {
    p.y -= 0.05;

    float hat = hat(p);
    hat -= 0.005;

    p.y -= 1.75;

    p.z -= sin(shroomRotation) * 0.25;
    p.x -= cos(shroomRotation) * 0.25;

    vec3 c = vec3(0.25);
    p = mod(p, c) - c*0.5;


    float dots = length(p) - 0.05;

    dots = max(dots, hat);

    return dots;
}

float map(vec3 p) {

    vec3 shroomP = p - vec3(0.0, -1.0, 0.0);
    float scale = 3.0;

    shroomP /= scale;

    float shroom = min(min(hat(shroomP), stem(shroomP)), min(ground(shroomP), hatDots(shroomP)));
    shroom *= scale;

    vec3 farawayPosition = vec3(10.0, 15.0, 20.0);
    vec3 holdingPosition = vec3(-0.6, 0.75, 1.55);
    vec3 handPosition = p - mix(farawayPosition, holdingPosition, mod(iGlobalTime * 0.25, 1.0));

    handPosition.yz *= rotate(mix(91.0, 92.1, mod(iGlobalTime * 0.25, 1.0)));
    handPosition.z *= -1.0;

    return min(hand(handPosition), shroom);
}

bool isSameDistance(float distanceA, float distanceB, float eps) {
    return distanceA > distanceB - eps && distanceA < distanceB + eps;
}

bool isSameDistance(float distanceA, float distanceB) {
    return isSameDistance(distanceA, distanceB, 0.0001);
}

Material getMaterial(vec3 p) {
    float distance = map(p);

    vec3 shroomP = p - vec3(0.0, -1.0, 0.0);
    float scale = 3.0;
    shroomP /= scale;

    if (isSameDistance(distance, hat(shroomP) * scale)) {
        return hatMaterial;
    }
    else if (isSameDistance(distance, stem(shroomP) * scale)) {
        return stemMaterial;
    }
    else if (isSameDistance(distance, ground(shroomP) * scale)) {
        return groundMaterial;
    }
    else if (isSameDistance(distance, hatDots(shroomP) * scale)) {
        return hatDotsMaterial;
    }
    else {
        return defaultMaterial;
    }
}

vec3 getNormal(vec3 p) {
    vec2 extraPolate = vec2(0.002, 0.0);

    return normalize(vec3(
        map(p + extraPolate.xyy),
        map(p + extraPolate.yxy),
        map(p + extraPolate.yyx)
    ) - map(p));
}

float intersect (vec3 rayOrigin, vec3 rayDirection) {
    const float maxDistance = 50.0;
    const float distanceTreshold = 0.0001;
    const int maxIterations = 100;

    float distance = 0.0;

    float currentDistance = 1.0;

    for (int i = 0; i < maxIterations; i++) {
        if (currentDistance < distanceTreshold || distance > maxDistance) {
            break;
        }

        vec3 p = rayOrigin + rayDirection * distance;

        currentDistance = map(p);

        distance += currentDistance;
    }

    if (distance > maxDistance) {
        return -1.0;
    }

    return distance;
}

float render2D(vec2 p) {
    float time = iGlobalTime + 10.0;

    float a = 1.26;
    p *= mat2(-sin(a), cos(a),
              cos(a), sin(a));

    float result = 0.0;

    float seed = 95.0;


    for (float i = 0.0 + seed; i < 100.0 + seed; i += 2.0) {
        vec2 circleLocation = vec2(hash(i), hash(i + 1.0)) - 0.5;
        circleLocation *= 2.0;

        circleLocation.x *= 3.0 + sin(hash(i) + iGlobalTime * 2.0);
        circleLocation.y *= 2.0 + sin(hash(i) + iGlobalTime * 2.0);


        float size = hash(i * 100.0) * 0.05;

        result += smoothstep(size + 0.01, size, length(p - circleLocation));
    }

    return result;
}

vec3 light = normalize(vec3(-10.0, 20.0, 2.0));

void mainImage (out vec4 color, in vec2 p) {
    p /= iResolution.xy;
    p = 2.0 * p - 1.0;
    p.x *= iResolution.x / iResolution.y;

    vec3 cameraPosition = vec3(0.0, 4.0, 7.5);
    vec3 rayDirection = normalize(vec3(p, -1.0));

    // mat2 b = rotate(3.14 * 2.0);
    // rayDirection.xz *= b;
    // cameraPosition.xz *= b;

    float b = 3.14 * 2.0 - 0.5;
    // rayDirection.zy *= rotate(b);
    // cameraPosition.zy *= rotate(b);*/
    // rayDirection.zy *= rotate(b + sin(iGlobalTime * 0.25));
    // cameraPosition.zy *= rotate(b + sin(iGlobalTime * 0.25));
    // rayDirection.xy *= rotate(b - 1.0 + sin(iGlobalTime * 0.25));
    // cameraPosition.xy *= rotate(b - 1.0 + sin(iGlobalTime * 0.25));

    // rayDirection.xz *= rotate(sin(iGlobalTime * 0.25) * 3.14);
    // cameraPosition.xz *= rotate(sin(iGlobalTime * 0.25) * 3.14);
    // rayDirection.xz *= rotate(iGlobalTime * 3.14);
    // cameraPosition.xz *= rotate(iGlobalTime * 3.14);
    rayDirection.xz *= rotate(79.15 * 3.14 + sin(iGlobalTime) * 0.025);
    cameraPosition.xz *= rotate(79.15 * 3.14 + sin(iGlobalTime) * 0.025);

    float distance = intersect(cameraPosition, rayDirection);

    vec3 col = vec3(0.05, 0.05, 0.15);
    col += render2D(p) * vec3(0.1, 0.2, 0.05) * 0.5;
    col += (1.0 - length(p)) * 0.1;

    if (distance > 0.0) {
        col = vec3(0.0);

        vec3 p = cameraPosition + rayDirection * distance;
        vec3 normal = getNormal(p);
        Material material = getMaterial(p);

        col += material.ambient;
        col += material.diffuse * max(dot(normal, light), 0.0);

        vec3 halfVector = normalize(light + normal);
        col += material.specular * pow(max(dot(normal, halfVector), 0.0), 1024.0);

        float attDistance = 15.0;
        float att = clamp(1.0 - length(light - p) / attDistance, 0.0, 1.0); att *= att;
        col *= att;

        col *= vec3(smoothstep(0.25, 0.75, map(p + light))) + 0.5;
    }

    color.rgb = col;
}
