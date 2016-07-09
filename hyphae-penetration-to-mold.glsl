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
Material groundMaterial = Material(
    vec3(3.25, 0.71, 0.15) * 0.45,
    vec3(4.7, 5.75, 0.95) * 0.15,
    vec3(1.0, 5.0, 1.0) * 0.25
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

vec3 triPlanarNoise(vec3 normal, vec3 p) {
    vec3 cX = vec3(noise(vec3(p.yz, 0.0)), 0.0, 0.0);
    vec3 cY = vec3(0.0, noise(vec3(p.xz, 0.0)), 0.0);
    vec3 cZ = vec3(0.0, 0.0, noise(vec3(p.xy, 0.0)));

    vec3 blend = abs(normal);
    blend /= blend.x + blend.y + blend.z + 0.001;

    return blend.x * cX + blend.y * cY + blend.z * cZ;
}

vec3 triPlanarHash(vec3 normal, vec3 p) {
    vec3 cX = vec3(hash3(p.y * p.z));
    vec3 cY = vec3(hash3(p.x * p.z));
    vec3 cZ = vec3(hash3(p.x * p.y));

    vec3 blend = abs(normal);
    blend /= blend.x + blend.y + blend.z + 0.001;

    return blend.x * cX + blend.y * cY + blend.z * cZ;
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

float dirtExtensions(vec3 p) {
    p = repeat(p, vec3(1.0));
    return length(p) - 1.0;
}

float dirt(vec3 p) {
    p.x -= 0.1;

    float dirt = max(length(p) - 6.0, p.x);
    return smin(dirt, max(dirt, dirtExtensions(p) + 0.7) - 0.15, 0.5);
}

float groundTexture(vec3 p) {
    p = repeat(p, vec3(0.1));

    float groundTexture = max(abs(p.x), max(abs(p.y), abs(p.z))) - 0.025;
    return groundTexture;
}

float ground(vec3 p) {
    float ground = smin(max(p.y, length(p - vec3(0.0, -3.75, 0.0)) - 4.5), length(p - vec3(0.0, -0.25, 0.0)) - 1.0, 0.75);

    float a = max(ground - 0.2, groundTexture(p));

    float b = smin(ground, max(ground - 0.01, groundTexture(p)), 0.1);

    // Cool transition between states
    b  = mix(a, b, sin(iGlobalTime * 10.0 + 1.23) * 0.5 + 0.75);

    vec3 q = repeat(p, vec3(0.01));
    b = smin(b, max(b, length(q) - 0.0001), 0.01);

    return b;
}

float shrooms(vec3 p) {
    float shrooms = mix(dirt(p), ground(p),  mod(iGlobalTime * 0.29284, 1.0));

    if (mod(iGlobalTime * 0.29284, 1.0) < 0.82) {
        shrooms += mod(iGlobalTime * 0.29284, 1.0) * 0.075;
    }

    shrooms = mix(smin(shrooms, max(shrooms - 0.01, groundTexture(p)), 0.01), shrooms, mod(iGlobalTime * 0.29284, 1.0));

    return shrooms;
}

float map(vec3 p) {
    return shrooms(p);
}

bool isSameDistance(float distanceA, float distanceB, float eps) {
    return distanceA > distanceB - eps && distanceA < distanceB + eps;
}

bool isSameDistance(float distanceA, float distanceB) {
    return isSameDistance(distanceA, distanceB, 0.0001);
}

Material getMaterial(vec3 p) {
    float distance = map(p);
    if (isSameDistance(distance, shrooms(p), 0.01)) {
        return groundMaterial;
    }
    return defaultMaterial;
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

    float seed = 205.0;

    float movement = mod(iGlobalTime * 0.25, 1.0) * 5.0;

    for (float i = 0.0 + seed; i < 100.0 + seed; i += 2.0) {
        vec2 circleLocation = vec2(hash(i), hash(i + 1.0)) - 0.5;

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

    vec3 cameraPositionA = vec3(0.5, 0.5, 3.0);
    vec3 rayDirectionA = normalize(vec3(p, -1.0));

    mat2 rotation = rotate(1.75 + sin(iGlobalTime) * 0.25);
    rayDirectionA.xz *= rotation;
    cameraPositionA.xz *= rotation;


    vec3 cameraPositionB = vec3(0.0, 0.5, 10.0);
    vec3 rayDirectionB = normalize(vec3(p, -1.0));

    float b = 1.25;
    rayDirectionB.zy *= rotate(b + sin(iGlobalTime * 0.25) * 0.1);
    cameraPositionB.zy *= rotate(b + sin(iGlobalTime * 0.25) * 0.1);

    rayDirectionB.xy *= rotate(b - 1.0 + sin(iGlobalTime * 0.25) * 0.1);
    cameraPositionB.xy *= rotate(b - 1.0 + sin(iGlobalTime * 0.25) * 0.1);

    vec3 cameraPosition = mix(cameraPositionB, cameraPositionA, mod(iGlobalTime * 0.29284, 1.0));
    vec3 rayDirection = mix(rayDirectionB, rayDirectionA, mod(iGlobalTime * 0.29284, 1.0));

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

        float att = clamp(1.0 - length(light - p) / mix(10.0, 5.0, mod(iGlobalTime * 0.29284, 1.0)), 0.0, 1.0); att *= att;
        col *= att;

        col *= vec3(smoothstep(0.25, 0.75, map(p + light))) + 0.5;
    }

    color.rgb = col;
}
