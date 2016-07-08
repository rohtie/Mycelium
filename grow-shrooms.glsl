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
Material dirtMaterial = Material(
    vec3(2.45, 0.71, 0.15),
    vec3(4.7, 4.0, 0.95),
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

float ground(vec3 p) {
    p.xz -= iGlobalTime * 0.5;

    float ground = p.y + noise(vec3(p.x, 0.0, p.z) * 1.5) * 0.5;

    // vec3 q = repeat(p, vec3(0.05));
    // ground = smin(ground, max(ground, length(q) - 0.0001), 0.075);

    return ground;
}

float map(vec3 p) {
    float ground = ground(p);

    p = repeat(p, vec3(5.5, 0.0, 5.5));

    float seed = 0.41;
    float result = 100000.0;

    for (float i = 0.0 + seed; i < 100.0 + seed; i += 4.0) {
        vec3 shroomBase = hash3(i);

        float height = shroomBase.y;
        shroomBase.y = -(ground - p.y);

        shroomBase.xz -= 0.5;
        shroomBase.xz *= 5.0;

        float growth = mod(iGlobalTime * 0.15, 3.0);

        vec3 shroomTop = shroomBase;
        shroomBase.y += growth * height;

        float size = 0.5 + hash(i * 100.0);
        size *= 0.15;

        float shroom = capsule(p, shroomBase, shroomTop, size * 0.25);

        float shroomHat = length(p - shroomBase) - size * growth;
        shroomHat = max(shroomHat, -(p.y - shroomBase.y));

        shroom = min(shroom, shroomHat);

        result = min(result, shroom);
    }

    return smin(result, ground, 0.1);
}

bool isSameDistance(float distanceA, float distanceB, float eps) {
    return distanceA > distanceB - eps && distanceA < distanceB + eps;
}

bool isSameDistance(float distanceA, float distanceB) {
    return isSameDistance(distanceA, distanceB, 0.0001);
}

Material getMaterial(vec3 p) {
    return defaultMaterial;
    // float distance = map(p);
    // if (isSameDistance(distance, dirt(p), 0.25)) {
    //     return dirtMaterial;
    // }
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
    const float maxDistance = 15.0;
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

vec3 light = normalize(vec3(10.0, 20.0, 2.0));

void mainImage (out vec4 color, in vec2 p) {
    p /= iResolution.xy;
    p = 2.0 * p - 1.0;
    p.x *= iResolution.x / iResolution.y;

    vec3 cameraPosition = vec3(0.0, 0.5, 5.0);
    vec3 rayDirection = normalize(vec3(p, -1.0));

    float b = 1.25;

    rayDirection.zy *= rotate(b);
    cameraPosition.zy *= rotate(b);

    rayDirection.xz *= rotate(b - 1.0 + sin(iGlobalTime * 0.25) * 0.1);
    cameraPosition.xz *= rotate(b - 1.0 + sin(iGlobalTime * 0.25) * 0.1);

    float distance = intersect(cameraPosition, rayDirection);

    vec3 col = vec3(0.05, 0.05, 0.15);
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

        float attDistance = 11.0;
        float att = clamp(1.0 - length(light - p) / attDistance, 0.0, 1.0); att *= att;
        col *= att;

        col *= vec3(smoothstep(0.25, 0.75, map(p + light))) + 0.5;
    }

    color.rgb = col;
}
