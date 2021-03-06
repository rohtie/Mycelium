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
Material dropMaterial = defaultMaterial;

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

float capsule (vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

vec3 repeat(vec3 p, vec3 c) {
    return mod(p,c)-0.5*c;
}

float ground(vec3 p) {
    p.y = abs(p.y);

    float waves = 25.0;
    float ground = p.y + mix(sin(p.x * waves), sin(p.z * waves), 0.5) * 0.3;

    ground += length(p) - 1.0;
    ground *= 0.25;

    return ground;
}

float stem(vec3 p) {
    p.y -= 0.5;

    float stem = capsule(p, vec3(0.0), vec3(cos(iGlobalTime) * 0.25, 1.0, sin(iGlobalTime) * 0.25), 0.5);
    stem += sin(p.y * 3.0 - 1.0) * 0.15;
    stem += mix(sin(p.z * 50.0 + 2.0), sin(p.x * 50.0 + 2.0), 0.5) * 0.02;

    return stem;
}

float hat(vec3 p) {
    p.y -= 2.0;

    p.z -= sin(iGlobalTime) * 0.25;
    p.x -= cos(iGlobalTime) * 0.25;

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

    p.z -= sin(iGlobalTime) * 0.25;
    p.x -= cos(iGlobalTime) * 0.25;

    vec3 c = vec3(0.25);
    p = mod(p, c) - c*0.5;


    float dots = length(p) - 0.05;

    dots = max(dots, hat);

    return dots;
}

float shroomPartition() {
    float t = mod(iGlobalTime * 0.25, 5.0);
    t /= 5.0;
    t /= 0.05;
    t = floor(t) / 16.0;

    return t;
}

float drop(vec3 p) {
    p.y -= 4.0;
    p.y -= shroomPartition() * 3.25;
    p.y += mod(iGlobalTime * 5.0, 5.0);

    p.z -= sin(iGlobalTime) * 0.25;
    p.x -= cos(iGlobalTime) * 0.25;


    float drop = length(p) - 0.15;
    p.y -= 0.37;
    drop = smin(drop, length(p) - 0.01, 0.4);

    return drop;
}

float map(vec3 p) {
    float map = min(min(hat(p), stem(p)), min(ground(p), hatDots(p)));

    // Cool woosh effect
    // map = smin(mod(iGlobalTime, 1.0), map, 0.5);

    map = max(map, p.y + 0.75 - shroomPartition() * 3.25);

    map = smin(drop(p), map, 0.5);

    return map;
}

bool isSameDistance(float distanceA, float distanceB, float eps) {
    return distanceA > distanceB - eps && distanceA < distanceB + eps;
}

bool isSameDistance(float distanceA, float distanceB) {
    return isSameDistance(distanceA, distanceB, 0.0001);
}

Material getMaterial(vec3 p) {
    float distance = map(p);

    if (isSameDistance(distance, hat(p))) {
        return hatMaterial;
    }
    else if (isSameDistance(distance, stem(p))) {
        return stemMaterial;
    }
    else if (isSameDistance(distance, ground(p))) {
        return groundMaterial;
    }
    else if (isSameDistance(distance, hatDots(p))) {
        return hatDotsMaterial;
    }
    else if (isSameDistance(distance, drop(p))) {
        return dropMaterial;
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
    const float maxDistance = 10.0;
    const float distanceTreshold = 0.001;
    const int maxIterations = 50;

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

mat2 rotate(float a) {
    return mat2(-sin(a), cos(a),
               cos(a), sin(a));
}

float hash(float n) {
    return fract(sin(n)*43758.5453);
}

float render2D(vec2 p) {
    float time = iGlobalTime + 10.0;

    float a = 1.26;
    p *= mat2(-sin(a), cos(a),
              cos(a), sin(a));

    float result = 0.0;

    float seed = 95.0;

    float movement = mod(iGlobalTime * 0.25, 1.0) * 5.0;

    for (float i = 0.0 + seed; i < 100.0 + seed; i += 2.0) {
        vec2 circleLocation = vec2(hash(i), hash(i + 1.0)) - 0.5;
        circleLocation *= 2.0;

        circleLocation.x *= 3.0;
        circleLocation.y *= 2.0;

        circleLocation.x += 0.3 * sin(time * hash(i * 5.0));
        circleLocation.y += 0.2 * sin(time * hash(i * 6.0));

        float size = hash(i * 100.0) * 0.05;

        result += smoothstep(size + 0.01, size, length(p - circleLocation));
    }

    return result;
}

vec3 light = normalize(vec3(10.0, 20.0, 2.0));

void mainImage (out vec4 color, in vec2 p) {
    p /= iResolution.xy;
    p = 2.0 * p - 1.0;
    p.x *= iResolution.x / iResolution.y;

    vec3 cameraPosition = vec3(0.0, 0.5, 3.0);
    vec3 rayDirection = normalize(vec3(p, -1.0));

    float b = 1.25 + sin(iGlobalTime) * 0.25;
    rayDirection.zy *= rotate(b);
    cameraPosition.zy *= rotate(b);

    float a = 3.14 + sin(iGlobalTime * 0.5);
    rayDirection.xz *= rotate(a);
    cameraPosition.xz *= rotate(a);

    cameraPosition.y += abs(sin(a)) / 2.0;

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

        float att = clamp(1.0 - length(light - p) / 5.0, 0.0, 1.0); att *= att;
        col *= att;

        col *= vec3(smoothstep(0.25, 0.75, map(p + light))) + 0.5;
    }

    color.rgb = col;
}
