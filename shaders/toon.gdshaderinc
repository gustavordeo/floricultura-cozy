// Sombreado de desenho: a luz cai em três faixas em vez de um degradê.
uniform vec4 cor : source_color = vec4(1.0);
uniform vec4 emissao : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float forca_emissao = 0.0;

void fragment() {
	ALBEDO = cor.rgb;
	EMISSION = emissao.rgb * forca_emissao;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float h = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float faixa = h < 0.3334 ? 0.353 : (h < 0.6667 ? 0.667 : 1.0);
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * faixa / PI;
}
