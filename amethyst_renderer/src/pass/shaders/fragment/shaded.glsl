// TODO: Needs documentation.

#version 150 core

layout (std140) uniform FragmentArgs {
    int point_light_count;
    int directional_light_count;
};

struct PointLight {
    vec4 position;
    vec4 color;
    float intensity;
    float radius;
    float smoothness;
    float _pad;
};

layout (std140) uniform PointLights {
    PointLight plight[128];
};

struct DirectionalLight {
    vec4 color;
    vec4 direction;
};

layout (std140) uniform DirectionalLights {
    DirectionalLight dlight[16];
};

uniform vec3 ambient_color;
uniform vec3 camera_position;

uniform sampler2D albedo;
uniform sampler2D emission;

layout (std140) uniform AlbedoOffset {
    vec2 u_offset;
    vec2 v_offset;
} albedo_offset;

layout (std140) uniform EmissionOffset {
    vec2 u_offset;
    vec2 v_offset;
} emission_offset;

in VertexData {
    vec4 position;
    vec3 normal;
    vec3 tangent;
    vec2 tex_coord;
} vertex;

out vec4 out_color;

float tex_coord(float coord, vec2 offset) {
    return offset.x + coord * (offset.y - offset.x);
}

vec2 tex_coords(vec2 coord, vec2 u, vec2 v) {
    return vec2(tex_coord(coord.x, u), tex_coord(coord.y, v));
}

void main() {
    vec4 color = texture(albedo, tex_coords(vertex.tex_coord, albedo_offset.u_offset, albedo_offset.v_offset));
    vec4 ecolor = texture(emission, tex_coords(vertex.tex_coord, emission_offset.u_offset, emission_offset.v_offset));
    vec4 lighting = vec4(0.0);
    vec4 normal = vec4(normalize(vertex.normal), 0.0);
    for (int i = 0; i < point_light_count; i++) {
        // Calculate diffuse light
        vec4 light_dir = normalize(plight[i].position - vertex.position);
        float diff = max(dot(light_dir, normal), 0.0);
        vec4 diffuse = diff * plight[i].color;
        // Calculate attenuation
        vec4 dist = plight[i].position - vertex.position;
        float dist2 = dot(dist, dist);
        float attenuation = (plight[i].intensity / dist2);
        lighting += diffuse * attenuation;
    }
    for (int i = 0; i < directional_light_count; i++) {
        vec4 dir = dlight[i].direction;
        float diff = max(dot(-dir, normal), 0.0);
        vec4 diffuse = diff * dlight[i].color;
        lighting += diffuse;
    }
    lighting += vec4(ambient_color, 0.0);
    out_color = lighting * color + ecolor;
}
