// Desenho à mão: aquarela no papel, hachura de lápis nas sombras e traço de grafite só nas plantas.
// Fica num TextureRect que cobre a tela inteira e mostra a textura da máscara (TEXTURE);
// a cor da cena vem da própria tela (tela).
shader_type canvas_item;

uniform sampler2D tela : hint_screen_texture, filter_nearest;
uniform float espessura = 1.0;
const float ALCANCE = 50.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	vec2 frag = UV / px;
	vec3 c = texture(tela, SCREEN_UV).rgb;

	vec3 m = texture(TEXTURE, UV).rgb;
	float d = (m.r + m.g / 255.0) * ALCANCE;
	bool planta_aqui = m.b > 0.5;
	float borda = 0.0;
	vec2 e = px * espessura;
	vec2 viz[8] = vec2[8](vec2(e.x, 0.0), vec2(-e.x, 0.0), vec2(0.0, e.y), vec2(0.0, -e.y),
		e * 0.7, -e * 0.7, vec2(e.x, -e.y) * 0.7, vec2(-e.x, e.y) * 0.7);
	for (int i = 0; i < 8; i++) {
		vec3 mv = texture(TEXTURE, UV + viz[i]).rgb;
		float dv = (mv.r + mv.g / 255.0) * ALCANCE;
		bool planta_ao_lado = mv.b > 0.5;
		if ((planta_aqui || planta_ao_lado) && dv - d > 0.1) {
			borda = 1.0;
		}
	}

	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(lum), c, 0.8);                       // cores mais suaves, de aquarela
	c = mix(c, vec3(0.97, 0.93, 0.85), 0.12);         // puxadas para o tom do papel
	c *= 0.93 + 0.07 * ruido(frag * 0.02 + 3.0);      // manchas de pigmento
	float k = 1.0 / espessura;                        // espaçamento das hachuras acompanha a densidade de pixels
	if (lum < 0.45) {
		c *= 1.0 - 0.16 * step(0.6, sin((frag.x + frag.y) * k));
	}
	if (lum < 0.28) {
		c *= 1.0 - 0.16 * step(0.6, sin((frag.x - frag.y) * k));
	}
	c *= 0.94 + 0.06 * hash(floor(frag));             // grão do papel
	float pressao = 0.85 + 0.15 * ruido(frag * 0.05); // traço firme, com leve variação de pressão
	c = mix(c, vec3(0.33, 0.28, 0.24), borda * pressao);
	COLOR = vec4(c, 1.0);
}
