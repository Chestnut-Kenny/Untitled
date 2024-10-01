shader_type spatial;

#define iTime TIME

uniform float size = 5.0;
uniform sampler2D iChannel0;
uniform vec2 texture_size = vec2(1024.0, 1024.0); // Tamaño de la textura
uniform vec2 uv_scale = vec2(1.0, 1.0);  // Escala de las coordenadas UV

// Máximo número de celdas que una onda puede cruzar.
#define MAX_RADIUS 2

// Funciones hash para generar el patrón de las ondas.
#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)

float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx + p3.yz) * p3.zy);
}

void fragment()
{
    float resolution = size;

    // Reemplazo de TEXTURE_PIXEL_SIZE con tamaño manual
    vec2 pixel_size = 1.0 / texture_size;

    // Ajustamos las coordenadas UV con la escala
    vec2 uv = UV * uv_scale * resolution;  // Usa las coordenadas UV del objeto 3D con la escala aplicada
    vec2 uv2 = uv * vec2(1.0, pixel_size.x / pixel_size.y);  // Ajuste de UV usando el tamaño de la textura
    vec2 p0 = floor(uv2);

    vec2 circles = vec2(0.);
    for (int j = -MAX_RADIUS; j <= MAX_RADIUS; ++j)
    {
        for (int i = -MAX_RADIUS; i <= MAX_RADIUS; ++i)
        {
            vec2 pi = p0 + vec2(float(i), float(j));
            vec2 p = pi + hash22(pi);

            float t = fract(0.3 * iTime + hash12(pi));
            vec2 v = p - uv2;
            float d = length(v) - (float(MAX_RADIUS) + 1.) * t;

            float h = 1e-3;
            float d1 = d - h;
            float d2 = d + h;
            float p1 = sin(31. * d1) * smoothstep(-0.6, -0.3, d1) * smoothstep(0., -0.3, d1);
            float p2 = sin(31. * d2) * smoothstep(-0.6, -0.3, d2) * smoothstep(0., -0.3, d2);
            circles += 0.5 * normalize(v) * ((p2 - p1) / (2. * h) * (1. - t) * (1. - t));
        }
    }
    circles /= float((MAX_RADIUS * 2 + 1) * (MAX_RADIUS * 2 + 1));

    // Cálculo de la intensidad de las ondas
    float intensity = mix(0.01, 0.15, smoothstep(0.1, 0.6, abs(fract(0.05 * iTime + 0.5) * 2. - 1.)));
    vec3 n = vec3(circles, sqrt(1. - dot(circles, circles)));

    // Textura y color final
    vec3 color = texture(iChannel0, uv / resolution - intensity * n.xy).rgb + 5. * pow(clamp(dot(n, normalize(vec3(1., 0.7, 0.5))), 0., 1.), 6.);
    ALBEDO = color;
}
