class_name Materiais
extends RefCounted
## Materiais compartilhados: tinta de desenho (toon) e a máscara que alimenta o traço das plantas.

const SHADER_TOON := preload("res://shaders/toon.gdshader")
const SHADER_TOON_DUPLA := preload("res://shaders/toon_dupla.gdshader")
const SHADER_MASCARA := preload("res://shaders/mascara.gdshader")

## Camadas de renderização: a câmera principal vê VISIVEL e ICONES; a câmera da máscara vê só MASCARA.
const CAMADA_VISIVEL := 1
const CAMADA_ICONES := 2
const CAMADA_MASCARA := 4

static var _cache := {}
static var _mascaras := {}


static func toon(cor: Color, dupla := false) -> ShaderMaterial:
	var chave := "%s-%s" % [cor.to_html(), dupla]
	if not _cache.has(chave):
		var m := ShaderMaterial.new()
		m.shader = SHADER_TOON_DUPLA if dupla else SHADER_TOON
		m.set_shader_parameter("cor", cor)
		_cache[chave] = m
	return _cache[chave]


static func toon_emissivo(cor: Color, emissao: Color, forca: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER_TOON
	m.set_shader_parameter("cor", cor)
	m.set_shader_parameter("emissao", emissao)
	m.set_shader_parameter("forca_emissao", forca)
	return m


static func mascara(planta: bool) -> ShaderMaterial:
	if not _mascaras.has(planta):
		var m := ShaderMaterial.new()
		m.shader = SHADER_MASCARA
		m.set_shader_parameter("planta", 1.0 if planta else 0.0)
		_mascaras[planta] = m
	return _mascaras[planta]


## Dá a cada malha dentro de `no` uma cópia invisível para a câmera principal, pintada com a máscara.
static func mascarar(no: Node, planta: bool) -> void:
	var malhas: Array[MeshInstance3D] = []
	if no is MeshInstance3D:
		malhas.append(no as MeshInstance3D)
	for filho in no.find_children("*", "MeshInstance3D", true, false):
		malhas.append(filho as MeshInstance3D)
	for mi in malhas:
		if mi.layers == CAMADA_MASCARA:
			continue
		var copia := MeshInstance3D.new()
		copia.mesh = mi.mesh
		copia.material_override = mascara(planta)
		copia.layers = CAMADA_MASCARA
		copia.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.add_child(copia)
