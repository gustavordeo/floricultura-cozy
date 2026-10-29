class_name Plantas
extends RefCounted
## Modelos 3D das plantas e dos vasos, montados com formas simples (mesmo desenho do protótipo aprovado).

const VERDE := Color("4c9a45")
const VERDE_ESCURO := Color("2f6b3a")


static func malha(mesh: Mesh, material: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = material
	return m


static func cilindro(r_topo: float, r_base: float, altura: float, lados := 10) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_topo
	c.bottom_radius = r_base
	c.height = altura
	c.radial_segments = lados
	c.rings = 0
	return c


static func esfera(raio: float, lados := 8, aneis := 6, metade := false) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = raio
	s.height = raio * 2.0
	s.radial_segments = lados
	s.rings = aneis
	s.is_hemisphere = metade
	return s


## Folha em coração com recortes nas bordas e furinhos perto da nervura.
## Fica deitada no plano XZ, apontando para +X.
static func folha_costela(tam: float) -> ArrayMesh:
	var lado: Array[Vector2] = [
		Vector2(0, 0.02), Vector2(-0.22, -0.14), Vector2(-0.42, -0.08), Vector2(-0.52, 0.12),
		Vector2(-0.52, 0.38), Vector2(-0.42, 0.62), Vector2(-0.24, 0.84), Vector2(0, 1),
	]
	var borda: Array[Vector2] = []
	for i in lado.size() - 1:
		for k in 4:
			borda.append(lado[i].lerp(lado[i + 1], k / 4.0))
	borda.append(Vector2(0, 1))
	# recortes: alguns pontos da borda puxados para perto da nervura
	for k: int in [10, 14, 18, 22]:
		borda[k] = Vector2(borda[k].x * 0.3, borda[k].y + 0.04)
	var contorno := PackedVector2Array(borda)
	for i in range(borda.size() - 2, 0, -1):
		contorno.append(Vector2(-borda[i].x, borda[i].y))

	var pontos := contorno.duplicate()
	var furos: Array[PackedVector2Array] = []
	for centro: Vector2 in [Vector2(0.12, 0.3), Vector2(-0.12, 0.3), Vector2(0.11, 0.46), Vector2(-0.11, 0.46), Vector2(0.09, 0.6), Vector2(-0.09, 0.6)]:
		var furo := PackedVector2Array()
		for k in 8:
			var a := TAU * k / 8.0
			furo.append(centro + Vector2(cos(a) * 0.025, sin(a) * 0.04))
		furos.append(furo)
		pontos.append_array(furo)

	# triangula tudo e descarta o que cai fora da folha ou dentro de um furo
	var triangulos := Geometry2D.triangulate_delaunay(pontos)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, triangulos.size(), 3):
		var a := pontos[triangulos[i]]
		var b := pontos[triangulos[i + 1]]
		var c := pontos[triangulos[i + 2]]
		var meio := (a + b + c) / 3.0
		if not Geometry2D.is_point_in_polygon(meio, contorno):
			continue
		var no_furo := false
		for furo in furos:
			if Geometry2D.is_point_in_polygon(meio, furo):
				no_furo = true
		if no_furo:
			continue
		for p: Vector2 in [a, b, c]:
			st.set_normal(Vector3.UP)
			st.add_vertex(Vector3(p.y * tam, 0.0, p.x * tam))
	return st.commit()


static func criar_planta(tipo: String, cor: Color) -> Node3D:
	var g := Node3D.new()
	match tipo:
		"costela":
			var folha := folha_costela(0.55)
			# [giro em volta do vaso, altura do caule, inclinação da folha, folha clara?]
			var folhas := [[0.2, 0.62, 0.55, true], [1.5, 0.42, 0.25, false], [2.7, 0.55, 0.45, true], [3.9, 0.36, 0.2, false], [5.0, 0.5, 0.4, true]]
			var lean := 0.35
			for f in folhas:
				var altura: float = f[1]
				var haste := Node3D.new()
				haste.rotation.y = f[0]
				var caule := malha(cilindro(0.012, 0.018, altura, 5), Materiais.toon(VERDE_ESCURO))
				caule.position = Vector3(sin(lean) * altura / 2.0, cos(lean) * altura / 2.0, 0.0)
				caule.rotation.z = -lean
				haste.add_child(caule)
				var fo := malha(folha, Materiais.toon(cor if f[3] else cor.darkened(0.35), true))
				fo.position = Vector3(sin(lean) * altura, cos(lean) * altura, 0.0)
				fo.rotation.z = f[2]
				haste.add_child(fo)
				g.add_child(haste)
		"violeta":
			violeta(g, cor)
		"rosa":
			var cores_petalas := [cor.darkened(0.3), cor, cor.lightened(0.4)]
			for pos: Vector3 in [Vector3(0, 0.62, 0), Vector3(0.12, 0.45, 0.06), Vector3(-0.1, 0.5, -0.05)]:
				var caule := malha(cilindro(0.012, 0.014, pos.y, 5), Materiais.toon(VERDE_ESCURO))
				caule.position = pos / 2.0
				caule.rotation = Vector3(pos.z * 1.2, 0.0, -pos.x * 1.2)
				g.add_child(caule)
				var botao := Node3D.new()
				botao.position = pos
				for c in 3:
					var camada := malha(esfera(0.07 - c * 0.018, 7, 5, true), Materiais.toon(cores_petalas[c], true))
					camada.position.y = c * 0.012
					camada.rotation.y = c * 0.8
					botao.add_child(camada)
				g.add_child(botao)
				var folha := malha(esfera(0.06, 6, 4), Materiais.toon(VERDE))
				folha.scale = Vector3(1.0, 0.25, 0.5)
				folha.position = Vector3(pos.x * 0.5 + 0.06, pos.y * 0.5, pos.z * 0.5)
				folha.rotation.z = 0.5
				g.add_child(folha)
	return g


## Violeta-africana, como nas fotos de referência: roseta baixa de folhas ovais aveludadas
## (verde-escuras em cima, vinho embaixo) e um buquê de flores de 5 pétalas em domo no centro.
static func violeta(g: Node3D, cor: Color) -> void:
	var folha_cima := esfera(0.5, 10, 4, true)
	var mat_cima := Materiais.toon(Color("3b5a38"))
	var mat_cima_clara := Materiais.toon(Color("466b42"))
	var mat_baixo := Materiais.toon(Color("a8475e"))
	var mat_talo := Materiais.toon(Color("7c8a4a"))
	var mat_nervura := Materiais.toon(Color("6e8f4a"))
	# [giro, comprimento do talo, comprimento da folha, largura, inclinação, ponta caída]
	var folhas := []
	for k in 8:
		folhas.append([TAU * k / 8.0 + (0.12 if k % 2 else 0.0), 0.13 + (k % 3) * 0.01, 0.22, 0.19, 0.22, -0.18])
	for k in 5:
		folhas.append([TAU * k / 5.0 + 0.4, 0.05, 0.15, 0.13, 0.8, 0.0])
	for i in folhas.size():
		var f: Array = folhas[i]
		var talo: float = f[1]
		var comp: float = f[2]
		var larg: float = f[3]
		var haste := Node3D.new()
		haste.position.y = 0.03
		haste.rotation = Vector3(0.0, f[0], f[4])
		g.add_child(haste)
		var peciolo := malha(cilindro(0.008, 0.011, talo, 5), mat_talo)
		peciolo.rotation.z = -PI / 2.0
		peciolo.position.x = talo / 2.0
		haste.add_child(peciolo)
		# a folha é um ovo achatado: metade de cima verde e metade de baixo vinho
		var lamina := Node3D.new()
		lamina.position.x = talo
		lamina.rotation.z = f[5]
		haste.add_child(lamina)
		var cima := malha(folha_cima, mat_cima_clara if i % 3 == 0 else mat_cima)
		cima.scale = Vector3(comp, 0.05, larg)
		cima.position.x = comp / 2.0
		lamina.add_child(cima)
		var baixo := malha(folha_cima, mat_baixo)
		baixo.scale = Vector3(comp, 0.03, larg)
		baixo.rotation.x = PI
		baixo.position.x = comp / 2.0
		lamina.add_child(baixo)
		var nervura := BoxMesh.new()
		nervura.size = Vector3(comp * 0.8, 0.004, 0.01)
		var linha := malha(nervura, mat_nervura)
		linha.position = Vector3(comp * 0.45, 0.024, 0.0)
		lamina.add_child(linha)

	# buquê de flores em domo, sobre hastes castanho-rosadas que saem do meio das folhas
	var mat_haste := Materiais.toon(Color("7a4a3a"))
	var petala := esfera(0.5, 8, 4)
	var mat_petala := Materiais.toon(cor)
	var mat_petala_clara := Materiais.toon(cor.lightened(0.15))
	var mat_miolo := Materiais.toon(Color("e8d93a"))
	var mat_anel := Materiais.toon(cor.darkened(0.6))
	var antera := esfera(0.009, 5, 3)
	var anel := esfera(0.014, 6, 3)
	# [ângulo, distância do centro, altura]
	var flores := [[0.0, 0.0, 0.2]]
	for k in 7:
		flores.append([TAU * k / 7.0 + 0.2, 0.085 + (k % 2) * 0.02, 0.15 + (k % 3) * 0.012])
	for f: Array in flores:
		var a: float = f[0]
		var r: float = f[1]
		var pos := Vector3(cos(a) * r, f[2], sin(a) * r)
		g.add_child(haste_entre(Vector3(0, 0.03, 0), pos, 0.006, mat_haste))
		var flor := Node3D.new()
		flor.position = pos
		flor.rotation = Vector3(0.0, -a, -r * 5.0)
		g.add_child(flor)
		# 2 pétalas menores em cima e 3 maiores embaixo
		for p in 5:
			var ap := PI / 2.0 + TAU * p / 5.0
			var tam := 0.8 if p == 0 or p == 4 else 1.0
			var pet := malha(petala, mat_petala_clara if p % 2 else mat_petala)
			pet.scale = Vector3(0.042, 0.009, 0.036) * tam
			pet.position = Vector3(cos(ap), 0.0, sin(ap)) * 0.021 * tam
			pet.rotation.y = -ap
			flor.add_child(pet)
		var centro := malha(anel, mat_anel)
		centro.scale.y = 0.4
		centro.position = Vector3(0.006, 0.004, 0.0)
		flor.add_child(centro)
		for z in [-0.006, 0.006]:
			var am := malha(antera, mat_miolo)
			am.position = Vector3(0.007, 0.01, z)
			flor.add_child(am)
	# botõezinhos fechados entre as flores
	var botao := esfera(0.014, 6, 4)
	var mat_botao := Materiais.toon(cor.darkened(0.45))
	for a in [1.0, 3.3, 5.2]:
		g.add_child(haste_entre(Vector3(0, 0.03, 0), Vector3(cos(a) * 0.05, 0.17, sin(a) * 0.05), 0.005, mat_haste))
		var b := malha(botao, mat_botao)
		b.position = Vector3(cos(a) * 0.05, 0.17, sin(a) * 0.05)
		g.add_child(b)


## Cilindro fininho ligando dois pontos (hastes das flores).
static func haste_entre(de: Vector3, ate: Vector3, raio: float, material: Material) -> MeshInstance3D:
	var dir := ate - de
	var m := malha(cilindro(raio, raio, dir.length(), 4), material)
	m.transform = Transform3D(Basis(Quaternion(Vector3.UP, dir.normalized())), (de + ate) / 2.0)
	return m


static func criar_vaso(tipo: String, cor: Color) -> Node3D:
	var g := Node3D.new()
	var corpo := malha(cilindro(0.17, 0.12, 0.28, 12 if tipo == "cesto" else 10), Materiais.toon(cor))
	corpo.position.y = 0.14
	g.add_child(corpo)
	match tipo:
		"barro":
			var borda := malha(cilindro(0.19, 0.18, 0.06, 10), Materiais.toon(Color("e08458")))
			borda.position.y = 0.27
			g.add_child(borda)
		"ceramica":
			var faixa := malha(cilindro(0.162, 0.152, 0.05, 10), Materiais.toon(Color("5fa8d8")))
			faixa.position.y = 0.18
			g.add_child(faixa)
		_:
			for k in 3:
				var trama := malha(cilindro(0.165 - k * 0.012, 0.16 - k * 0.012, 0.025, 12), Materiais.toon(Color("a8823c")))
				trama.position.y = 0.24 - k * 0.08
				g.add_child(trama)
	var terra := malha(cilindro(0.155, 0.155, 0.02, 10), Materiais.toon(Color("5a3a26")))
	terra.position.y = 0.27
	terra.name = "Terra"
	g.add_child(terra)
	return g
