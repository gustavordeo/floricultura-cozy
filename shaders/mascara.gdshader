// Passe escondido que alimenta o traço: grava a distância até a câmera (em dois canais, para ter precisão)
// e se o pixel é de planta. O traço só é desenhado onde aparece planta.
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled, shadows_disabled, ambient_light_disabled;

uniform float planta = 0.0;
const float ALCANCE = 50.0;

// o Godot converte a saída para sRGB; desfazemos isso para os números chegarem intactos na textura
vec3 srgb_para_linear(vec3 c) {
	return mix(pow((c + vec3(0.055)) / 1.055, vec3(2.4)), c / 12.92, lessThan(c, vec3(0.04045)));
}

void fragment() {
	float d = clamp(-VERTEX.z / ALCANCE, 0.0, 1.0);
	float alto = floor(d * 255.0) / 255.0;
	float baixo = fract(d * 255.0);
	ALBEDO = srgb_para_linear(vec3(alto, baixo, planta));
}
