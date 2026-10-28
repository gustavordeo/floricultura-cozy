extends Node3D
## Sala aconchegante para decorar com plantas, no estilo de desenho à mão.
## A sala, as plantas, a câmera e a interface são montadas por código, a partir do protótipo 3D aprovado.

const LUZES := {"sol": "Sol direto", "meia": "Meia-luz", "sombra": "Sombra"}
# luz: quanto cada planta gosta de cada luz (1 = ideal, 0.6 = aceita, 0.3 = sofre); multiplica o ritmo
const PLANTAS := {
	"violeta": {"nome": "Violeta", "cor": "8a5bd0", "tempos": [6.0, 8.0], "seca": 25.0, "luz": {"sol": 0.3, "meia": 1.0, "sombra": 0.6}, "dica": "Gosta de meia-luz. Sol direto queima as folhas.", "gosta": "gosta de meia-luz"},
	"rosa": {"nome": "Rosa", "cor": "dd4b67", "tempos": [7.0, 9.0], "seca": 15.0, "luz": {"sol": 1.0, "meia": 0.6, "sombra": 0.3}, "dica": "Precisa de sol direto e de rega frequente.", "gosta": "gosta de sol"},
	"costela": {"nome": "Costela de adão", "cor": "4c9a45", "tempos": [8.0, 10.0], "seca": 60.0, "luz": {"sol": 0.6, "meia": 1.0, "sombra": 1.0}, "dica": "Tranquila: aguenta sombra e fica um minuto sem água.", "gosta": "aguenta sombra"},
}
const VASOS := {
	"barro": {"nome": "Barro", "cor": "c8643c", "charme": 0},
	"ceramica": {"nome": "Cerâmica", "cor": "eef0ea", "charme": 1},
	"cesto": {"nome": "Cesto", "cor": "d9b25f", "charme": 2},
}
const ESTAGIOS := ["muda", "crescendo", "adulta"]
# Pontos de vaso: posição de apoio na sala e a luz do lugar
const PONTOS := [
	{"id": "parapeito", "nome": "Parapeito da janela", "p": Vector3(-3.7, 1.06, -0.7), "luz": "sol"},
	{"id": "chao-janela", "nome": "Chão perto da janela", "p": Vector3(-2.9, 0, -0.1), "luz": "sol"},
	{"id": "prateleira", "nome": "Prateleira sobre o sofá", "p": Vector3(0.95, 2.03, -2.82), "luz": "meia"},
	{"id": "mesinha", "nome": "Mesinha ao lado do sofá", "p": Vector3(2.05, 0.6, -2.45), "luz": "meia"},
	{"id": "mesa-centro", "nome": "Mesa de centro", "p": Vector3(0.75, 0.44, -0.75), "luz": "meia"},
	{"id": "estante", "nome": "Topo da estante", "p": Vector3(3.3, 2.24, -2.65), "luz": "sombra"},
	{"id": "rack", "nome": "Rack da TV", "p": Vector3(-3.55, 0.52, 2.45), "luz": "sombra"},
	{"id": "canto", "nome": "Canto perto da estante", "p": Vector3(3.4, 0, -1.75), "luz": "sombra"},
	{"id": "comoda", "nome": "Cômoda", "p": Vector3(-2.75, 0.82, -2.72), "luz": "meia"},
	{"id": "suporte", "nome": "Suporte pendurado", "p": Vector3(-3.6, 1.95, 0.75), "luz": "sol"},
	{"id": "banquinho", "nome": "Banquinho ao lado da poltrona", "p": Vector3(3.3, 0.46, 0.6), "luz": "meia"},
]
const ARQUIVO_SAVE := "user://sala.json"

# Câmera: duas vistas (diagonal de diorama e bem do alto), em ângulos de órbita em volta do centro da sala
const ALVO_INICIAL := Vector3(0, 0.9, -0.3)
const DISTANCIA := 15.0
const VISTAS := {
	"diorama": {"azimute": 0.718, "polar": 1.121, "meia": 3.4},
	"alto": {"azimute": 0.696, "polar": 0.666, "meia": 4.1},
}
const AZIMUTE_MIN := 0.12
const AZIMUTE_MAX := 1.45
const POLAR_MIN := 0.35
const POLAR_MAX := 1.15
const ZOOM_MIN := 0.8
const ZOOM_MAX := 3.0

const FUNDO := Color("f3ead6")
const PAPEL := Color("fff6d8")
const TINTA := Color("3b2f26")
const TINTA_SUAVE := Color("6b5a49")
const MADEIRA := Color("7a4a2e")
const DESTAQUE := Color("dd4b67")

var estado := {"t": 0.0, "pontos": {}}
var ferramenta := "costela"
var vaso_escolhido := "barro"
var confirmacao := {}

var camera: Camera3D
var camera_mascara: Camera3D
var vp_mascara: SubViewport
var pos_mao: TextureRect
var vista := "diorama"
var alvo := ALVO_INICIAL
var azimute: float = VISTAS.diorama.azimute
var polar: float = VISTAS.diorama.polar
var zoom := 1.0
var foco := {}
var girando := false
var sentido_giro := 1.0

var arrastando := -1 # botão do mouse que está arrastando
var inicio_toque := Vector2.ZERO
var movimento_toque := 0.0
var ultimo_toque := -1000
var toques := {}
var hover := -1

var visuais: Array[Dictionary] = []
var gato: Node3D
var tela_tv: MeshInstance3D
var ponteiro_relogio: MeshInstance3D
var abajur: OmniLight3D
var tex_coracao: ImageTexture

var lbl_aconchego: Label
var lbl_info: Label
var lbl_status: Label
var btn_vista: Button
var btn_girar: Button
var botoes := {}

var tempo := 0.0
var ultimo_save := 0.0


func _ready() -> void:
	carregar()
	montar_ambiente()
	montar_sala()
	montar_pontos()
	montar_pos_processo()
	montar_interface()
	escolher("costela")
	status("Escolha uma planta e clique num espaço com + na sala. Arraste para mover o cenário.")
	get_viewport().size_changed.connect(ajustar_tamanho)
	ajustar_tamanho()
	posicionar_camera()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		salvar()


# ---------- Salvar ----------

func carregar() -> void:
	if not FileAccess.file_exists(ARQUIVO_SAVE):
		return
	var dados = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO_SAVE))
	if dados is Dictionary and dados.get("pontos") is Dictionary:
		estado = dados


func salvar() -> void:
	var f := FileAccess.open(ARQUIVO_SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(estado))


# ---------- Cena ----------

func montar_ambiente() -> void:
	var amb := Environment.new()
	amb.background_mode = Environment.BG_COLOR
	amb.background_color = FUNDO
	# luz de céu suave vinda de todos os lados
	amb.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	amb.ambient_light_color = Color("f0e0c8")
	amb.ambient_light_energy = 0.62
	amb.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = amb
	add_child(we)

	# sol entrando pela janela
	var sol := DirectionalLight3D.new()
	sol.light_color = Color("ffefc4")
	sol.light_energy = 1.35
	sol.shadow_enabled = true
	sol.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sol.directional_shadow_max_distance = 30.0
	sol.transform = Transform3D(Basis(), Vector3(-12, 7.5, 0.4)).looking_at(Vector3(-1.2, 0, -0.9), Vector3.UP)
	add_child(sol)

	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.1
	camera.far = 40.0
	camera.cull_mask = Materiais.CAMADA_VISIVEL | Materiais.CAMADA_ICONES
	add_child(camera)
	camera.make_current()


func caixa(w: float, h: float, d: float, cor: String, x: float, y: float, z: float, pai: Node3D = null, sombra := true) -> MeshInstance3D:
	if pai == null:
		pai = self
	var b := BoxMesh.new()
	b.size = Vector3(w, h, d)
	var m := Plantas.malha(b, Materiais.toon(Color(cor)))
	m.position = Vector3(x, y + h / 2.0, z)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sombra else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(m)
	Materiais.mascarar(m, false)
	return m


func cilindro(r_topo: float, r_base: float, h: float, cor: String, x: float, y: float, z: float, pai: Node3D = null, lados := 10) -> MeshInstance3D:
	if pai == null:
		pai = self
	var m := Plantas.malha(Plantas.cilindro(r_topo, r_base, h, lados), Materiais.toon(Color(cor)))
	m.position = Vector3(x, y + h / 2.0, z)
	pai.add_child(m)
	Materiais.mascarar(m, false)
	return m


func plano_ceu(w: float, h: float, cor: Color, pos: Vector3) -> void:
	var q := QuadMesh.new()
	q.size = Vector2(w, h)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = cor
	var m := Plantas.malha(q, mat)
	m.position = pos
	m.rotation.y = PI / 2.0
	m.layers = Materiais.CAMADA_ICONES
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)


func montar_sala() -> void:
	# Chão de tacos
	for i in 12:
		caixa(8, 0.1, 0.49, "b07a4a" if i % 2 else "a46e40", 0, -0.1, -3 + i * 0.5 + 0.25, self, false)
	# Parede do fundo, com meia parede clara e rodapé
	caixa(8.2, 3.2, 0.2, "9cc3b4", 0, 0, -3.1)
	caixa(8.2, 1.0, 0.04, "e8dcc4", 0, 0, -2.98, self, false)
	caixa(8.2, 0.05, 0.08, "c9b99c", 0, 1.0, -2.96, self, false)
	var x := -3.8
	while x < 4:
		caixa(0.12, 2.2, 0.02, "93baab", x, 1.05, -2.99, self, false)
		x += 0.4
	# Parede da esquerda, com o vão da janela (z de -1.6 a 0.2, y de 1.0 a 2.4)
	var parede_e := "8fb8a8"
	caixa(0.2, 1.0, 6.2, parede_e, -4.1, 0, 0)
	caixa(0.2, 0.8, 6.2, parede_e, -4.1, 2.4, 0)
	caixa(0.2, 1.4, 1.5, parede_e, -4.1, 1.0, -2.35)
	caixa(0.2, 1.4, 2.9, parede_e, -4.1, 1.0, 1.65)
	caixa(0.04, 1.0, 6.2, "e8dcc4", -3.98, 0, 0, self, false)
	caixa(0.08, 0.05, 6.2, "c9b99c", -3.96, 1.0, 0, self, false)

	# Janela: moldura, caixilho, parapeito, céu lá fora e cortinas
	var branco := "f4efe4"
	caixa(0.24, 0.08, 1.9, branco, -4.05, 2.36, -0.7)
	caixa(0.24, 0.08, 1.9, branco, -4.05, 0.98, -0.7)
	caixa(0.24, 1.4, 0.08, branco, -4.05, 1.0, -1.62)
	caixa(0.24, 1.4, 0.08, branco, -4.05, 1.0, 0.22)
	caixa(0.1, 1.4, 0.05, branco, -4.05, 1.0, -0.7)
	caixa(0.1, 0.05, 1.8, branco, -4.05, 1.68, -0.7)
	caixa(0.5, 0.06, 2.1, branco, -3.85, 1.0, -0.7)
	plano_ceu(2.0, 1.6, Color("a9dcf5"), Vector3(-4.35, 1.7, -0.7))
	plano_ceu(0.45, 0.14, Color.WHITE, Vector3(-4.33, 2.0, -1.1))
	plano_ceu(0.5, 0.14, Color.WHITE, Vector3(-4.33, 1.45, -0.25))
	var varao := cilindro(0.025, 0.025, 2.6, "7a4a2e", 0, 0, 0)
	varao.rotation.x = PI / 2.0
	varao.position = Vector3(-3.8, 2.6, -0.7)
	for zc in [-1.95, 0.55]:
		for k in 4:
			caixa(0.1, 2.0, 0.12, "e3a05a" if k % 2 else "d38f4b", -3.82 + (k % 2) * 0.04, 0.6, zc - 0.18 + k * 0.12)

	# Sofá encostado na parede do fundo
	var rosa := "c97b84"
	var rosa_claro := "d8949b"
	var rosa_escuro := "b4646e"
	caixa(2.6, 0.3, 0.95, rosa_escuro, 0.3, 0.08, -2.5)
	caixa(2.6, 0.15, 0.9, rosa_claro, 0.3, 0.38, -2.45)
	caixa(2.6, 0.75, 0.28, rosa, 0.3, 0.38, -2.85)
	caixa(0.25, 0.42, 0.95, rosa_escuro, -1.0, 0.38, -2.5)
	caixa(0.25, 0.42, 0.95, rosa_escuro, 1.6, 0.38, -2.5)
	caixa(0.06, 0.13, 0.85, rosa, 0.3, 0.4, -2.45)
	for px in [-1.05, 1.65]:
		for pz in [-2.9, -2.1]:
			caixa(0.08, 0.08, 0.08, "5e3b26", px, 0, pz)
	var almofada := caixa(0.5, 0.42, 0.14, "f6d861", -0.55, 0.53, -2.62)
	almofada.rotation.z = 0.12
	almofada = caixa(0.45, 0.38, 0.14, "8a5bd0", 1.2, 0.53, -2.62)
	almofada.rotation.z = -0.1
	# Manta dobrada no braço do sofá
	caixa(0.3, 0.06, 0.97, "5fa8d8", -1.0, 0.8, -2.5)

	# Gato dormindo no sofá
	gato = Node3D.new()
	gato.position = Vector3(0.55, 0.53, -2.35)
	add_child(gato)
	caixa(0.5, 0.2, 0.32, "e3a05a", 0, 0, 0, gato)
	caixa(0.22, 0.18, 0.24, "e3a05a", 0.3, 0.02, 0.04, gato)
	caixa(0.06, 0.07, 0.06, "b8743a", 0.25, 0.2, -0.04, gato)
	caixa(0.06, 0.07, 0.06, "b8743a", 0.25, 0.2, 0.12, gato)
	caixa(0.4, 0.06, 0.08, "b8743a", -0.08, 0.0, 0.2, gato)
	caixa(0.2, 0.04, 0.2, "f6dcb4", 0.06, 0.18, 0.0, gato)

	# Prateleira com livros acima do sofá
	caixa(1.6, 0.06, 0.32, "a8703f", 0.4, 1.97, -2.84)
	caixa(0.05, 0.2, 0.05, "7a4a2e", -0.2, 1.77, -2.95)
	caixa(0.05, 0.2, 0.05, "7a4a2e", 1.0, 1.77, -2.95)
	var livros := [["dd4b67", 0.32], ["5fa8d8", 0.38], ["f6d861", 0.28], ["4e3482", 0.35], ["4c9a45", 0.3]]
	for i in livros.size():
		caixa(0.08, livros[i][1], 0.24, livros[i][0], -0.25 + i * 0.1, 2.03, -2.84)
	var livro_deitado := caixa(0.3, 0.06, 0.22, "c97b84", 0.45, 2.03, -2.84)
	livro_deitado.rotation.y = 0.2

	# Quadros na parede
	caixa(0.9, 0.7, 0.05, "7a4a2e", 2.5, 1.5, -2.98)
	caixa(0.78, 0.58, 0.02, "f3e6c8", 2.5, 1.56, -2.95)
	caixa(0.78, 0.2, 0.02, "8fd06a", 2.5, 1.56, -2.94)
	caixa(0.16, 0.16, 0.02, "dd4b67", 2.35, 1.82, -2.93)
	caixa(0.4, 0.5, 0.05, "7a4a2e", -2.4, 1.6, -2.98)
	caixa(0.3, 0.4, 0.02, "c9a7f2", -2.4, 1.65, -2.95)

	# Mesinha ao lado do sofá
	caixa(0.5, 0.05, 0.5, "a8703f", 2.05, 0.55, -2.45)
	for d: Vector2 in [Vector2(-0.2, -0.2), Vector2(0.2, -0.2), Vector2(-0.2, 0.2), Vector2(0.2, 0.2)]:
		caixa(0.05, 0.55, 0.05, "7a4a2e", 2.05 + d.x, 0, -2.45 + d.y)

	# Abajur de chão com luz quente
	cilindro(0.18, 0.2, 0.04, "3b2f26", -1.5, 0, -2.6)
	cilindro(0.025, 0.025, 1.5, "3b2f26", -1.5, 0.04, -2.6)
	var cupula := cilindro(0.18, 0.3, 0.32, "fff3b0", -1.5, 1.45, -2.6, self, 12)
	cupula.material_override = Materiais.toon_emissivo(Color("fff3b0"), Color("ffd27a"), 0.6)
	abajur = OmniLight3D.new()
	abajur.light_color = Color("ffc977")
	abajur.light_energy = 0.9
	abajur.omni_range = 5.0
	abajur.position = Vector3(-1.5, 1.45, -2.4)
	add_child(abajur)

	# Tapete e mesa de centro
	caixa(3.4, 0.02, 2.2, "8a5bd0", 0.3, 0, -0.8, self, false)
	caixa(3.1, 0.022, 1.9, "c9a7f2", 0.3, 0, -0.8, self, false)
	caixa(2.7, 0.024, 1.5, "8a5bd0", 0.3, 0, -0.8, self, false)
	caixa(1.3, 0.06, 0.7, "a8703f", 0.3, 0.38, -0.8)
	caixa(1.2, 0.04, 0.6, "7a4a2e", 0.3, 0.12, -0.8)
	for d: Vector2 in [Vector2(-0.58, -0.28), Vector2(0.58, -0.28), Vector2(-0.58, 0.28), Vector2(0.58, 0.28)]:
		caixa(0.06, 0.38, 0.06, "7a4a2e", 0.3 + d.x, 0, -0.8 + d.y)
	caixa(0.3, 0.04, 0.22, "5fa8d8", 0.0, 0.44, -0.85) # revista
	cilindro(0.06, 0.05, 0.1, "f4efe4", 0.15, 0.44, -0.6) # xícara

	# Rack e TV na parede da esquerda
	caixa(0.55, 0.5, 2.2, "7a4a2e", -3.68, 0, 1.6)
	caixa(0.02, 0.32, 0.9, "5e3b26", -3.4, 0.09, 1.1, self, false)
	caixa(0.02, 0.32, 0.9, "5e3b26", -3.4, 0.09, 2.1, self, false)
	caixa(0.12, 0.08, 0.4, "2b2a3a", -3.75, 0.5, 1.4)
	caixa(0.08, 0.8, 1.35, "2b2a3a", -3.8, 0.75, 1.4)
	tela_tv = caixa(0.02, 0.68, 1.22, "3c5068", -3.75, 0.81, 1.4, self, false)
	tela_tv.material_override = Materiais.toon_emissivo(Color("1d2836"), Color("3c5068"), 0.8)
	caixa(0.25, 0.18, 0.3, "f6d861", -3.65, 0.5, 2.15) # caixinha decorativa

	# Cômoda no canto do fundo, perto da janela
	caixa(1.3, 0.78, 0.5, "c48a52", -2.85, 0.04, -2.72)
	caixa(1.36, 0.05, 0.54, "a8703f", -2.85, 0.8, -2.72)
	for y in [0.16, 0.42]:
		caixa(1.2, 0.02, 0.02, "7a4a2e", -2.85, y + 0.22, -2.46, self, false)
		for px in [-3.15, -2.55]:
			caixa(0.08, 0.04, 0.04, "f6d861", px, y + 0.08, -2.45, self, false)
	for px in [-3.45, -2.25]:
		caixa(0.06, 0.06, 0.06, "5e3b26", px, 0, -2.55)
	caixa(0.3, 0.05, 0.3, "3b2f26", -3.25, 0.85, -2.72) # vitrola
	cilindro(0.12, 0.12, 0.01, "2b2a3a", -3.25, 0.9, -2.72, self, 16)

	# Suporte de parede para vaso pendurado, ao lado da janela
	caixa(0.5, 0.05, 0.05, "7a4a2e", -3.8, 2.75, 0.75)
	for d: Vector2 in [Vector2(0.14, 0), Vector2(-0.07, 0.12), Vector2(-0.07, -0.12)]:
		var corda := cilindro(0.006, 0.006, 0.8, "c9b99c", -3.6 + d.x * 0.5, 2.02, 0.75 + d.y * 0.5, self, 4)
		corda.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Poltrona e banquinho na frente, à direita
	var poltrona := Node3D.new()
	poltrona.position = Vector3(3.05, 0, -0.55)
	poltrona.rotation.y = -0.15
	add_child(poltrona)
	caixa(0.95, 0.3, 0.85, "5fa8d8", 0, 0.1, 0, poltrona)
	caixa(0.85, 0.12, 0.75, "7cbbe2", 0.03, 0.4, 0, poltrona)
	caixa(0.2, 0.7, 0.85, "4f93c2", 0.42, 0.1, 0, poltrona)
	caixa(0.85, 0.32, 0.15, "4f93c2", 0, 0.4, -0.38, poltrona)
	caixa(0.85, 0.32, 0.15, "4f93c2", 0, 0.4, 0.38, poltrona)
	caixa(0.12, 0.3, 0.5, "f6d861", 0.28, 0.5, 0, poltrona)
	for d: Vector2 in [Vector2(-0.4, -0.35), Vector2(0.4, -0.35), Vector2(-0.4, 0.35), Vector2(0.4, 0.35)]:
		caixa(0.06, 0.1, 0.06, "5e3b26", d.x, 0, d.y, poltrona)
	cilindro(0.2, 0.2, 0.04, "a8703f", 3.3, 0.42, 0.6, self, 12)
	for a in [0.0, 2.1, 4.2]:
		var perna := caixa(0.04, 0.42, 0.04, "7a4a2e", 3.3 + cos(a) * 0.13, 0, 0.6 + sin(a) * 0.13)
		perna.rotation.z = cos(a) * 0.08

	# Puff, cesto de mantas e pilha de livros
	cilindro(0.3, 0.3, 0.32, "e3a05a", -1.2, 0, 0.55, self, 12)
	cilindro(0.28, 0.28, 0.04, "f6dcb4", -1.2, 0.32, 0.55, self, 12)
	cilindro(0.24, 0.2, 0.36, "d9b25f", -1.55, 0, -1.75, self, 10)
	caixa(0.3, 0.12, 0.3, "c97b84", -1.55, 0.3, -1.75)
	var manta := caixa(0.2, 0.08, 0.32, "5fa8d8", -1.5, 0.38, -1.78)
	manta.rotation.y = 0.4
	var pilha := [["4e3482", 0.1], ["dd4b67", -0.15], ["f6d861", 0.25]]
	for k in pilha.size():
		var livro := caixa(0.36, 0.07, 0.26, pilha[k][0], 2.6, k * 0.07, -1.6)
		livro.rotation.y = pilha[k][1]

	# Estante no canto direito do fundo
	var estante := "a8703f"
	caixa(1.0, 2.2, 0.06, "7a4a2e", 3.3, 0, -2.95)
	caixa(0.06, 2.2, 0.45, estante, 2.83, 0, -2.75)
	caixa(0.06, 2.2, 0.45, estante, 3.77, 0, -2.75)
	var cores_livros := ["dd4b67", "5fa8d8", "f6d861", "4e3482", "4c9a45", "e3a05a", "c9a7f2", "2f6b3a"]
	for n in 5:
		var y := n * 0.54
		caixa(1.0, 0.05, 0.45, estante, 3.3, y, -2.75)
		if n == 0 or n == 4:
			continue
		var lx := 2.9
		var k := 0
		while lx < 3.55 and k < 9:
			var larg := 0.06 + ((n * 7 + k * 3) % 4) * 0.015
			var alt := 0.3 + ((n * 5 + k * 11) % 5) * 0.03
			caixa(larg, alt, 0.32, cores_livros[(n * 3 + k) % cores_livros.size()], lx + larg / 2.0, y + 0.05, -2.75)
			lx += larg + 0.01
			k += 1
	caixa(0.2, 0.15, 0.2, "eef0ea", 3.6, 1.13, -2.75) # pote
	caixa(1.0, 0.05, 0.45, estante, 3.3, 2.18, -2.75)

	# Relógio de parede
	var relogio := cilindro(0.22, 0.22, 0.04, "f4efe4", 0, 0, 0, self, 16)
	relogio.rotation.x = PI / 2.0
	relogio.position = Vector3(-1.0, 2.5, -2.96)
	ponteiro_relogio = caixa(0.03, 0.15, 0.01, "3b2f26", -1.0, 2.5, -2.93, self, false)


# ---------- Ícones (desenhados pixel a pixel, como no protótipo) ----------

func textura_icone(retangulos: Array) -> ImageTexture:
	var img := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	for parte in retangulos:
		var cor := Color(parte[0])
		for r in parte[1]:
			img.fill_rect(Rect2i(r[0], r[1], r[2], r[3]), cor)
	return ImageTexture.create_from_image(img)


func icone(tex: Texture2D, tam: float) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	s.pixel_size = tam / 16.0
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.no_depth_test = true
	s.shaded = false
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.render_priority = 10
	s.layers = Materiais.CAMADA_ICONES
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return s


func montar_pontos() -> void:
	var tex_gota := textura_icone([
		["2e2a24", [[7, 2, 2, 1], [6, 3, 4, 1], [5, 4, 6, 2], [4, 6, 8, 5], [5, 11, 6, 2], [6, 13, 4, 1]]],
		["5fa8d8", [[7, 3, 2, 1], [6, 4, 4, 2], [5, 6, 6, 5], [6, 11, 4, 2]]],
		["a9dcf5", [[6, 7, 2, 2]]],
	])
	tex_coracao = textura_icone([
		["dd4b67", [[3, 4, 4, 2], [9, 4, 4, 2], [2, 6, 12, 3], [3, 9, 10, 1], [4, 10, 8, 1], [5, 11, 6, 1], [6, 12, 4, 1], [7, 13, 2, 1]]],
		["f7a1b5", [[4, 6, 2, 2]]],
	])
	var tex_mais := textura_icone([
		["2e2a248c", [[1, 1, 14, 14]]],
		["fff6d8", [[7, 4, 2, 8], [4, 7, 8, 2]]],
	])
	var tex_luz := {
		"sol": textura_icone([["f6d861", [[5, 5, 6, 6], [7, 1, 2, 3], [7, 12, 2, 3], [1, 7, 3, 2], [12, 7, 3, 2]]]]),
		"meia": textura_icone([["f6d861", [[4, 4, 4, 8]]], ["fff6d8", [[8, 4, 4, 8]]]]),
		"sombra": textura_icone([["c9a7f2", [[5, 3, 4, 10], [4, 5, 2, 6], [9, 11, 3, 2], [9, 3, 3, 2]]]]),
	}
	for ponto in PONTOS:
		var g := Node3D.new()
		g.position = ponto.p
		add_child(g)
		var mais := icone(tex_mais, 0.28)
		mais.position.y = 0.18
		g.add_child(mais)
		var luz := icone(tex_luz[ponto.luz], 0.2)
		luz.position = Vector3(0.25, 0.1, 0.25)
		luz.visible = false
		g.add_child(luz)
		var gota := icone(tex_gota, 0.22)
		gota.visible = false
		g.add_child(gota)
		visuais.append({"g": g, "mais": mais, "luz": luz, "gota": gota, "vaso": null, "vaso_tipo": "", "planta": null, "planta_tipo": "", "escala": 0.3, "nasceu": -9.0, "coracoes": []})


# ---------- Traço das plantas e papel ----------

func montar_pos_processo() -> void:
	# uma segunda câmera, que segue a principal, vê só as cópias de máscara e grava distância + "é planta"
	vp_mascara = SubViewport.new()
	vp_mascara.world_3d = get_viewport().find_world_3d()
	vp_mascara.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp_mascara.msaa_3d = Viewport.MSAA_DISABLED
	vp_mascara.positional_shadow_atlas_size = 0
	add_child(vp_mascara)
	camera_mascara = Camera3D.new()
	camera_mascara.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera_mascara.near = camera.near
	camera_mascara.far = camera.far
	camera_mascara.cull_mask = Materiais.CAMADA_MASCARA
	var amb := Environment.new()
	amb.background_mode = Environment.BG_COLOR
	amb.background_color = Color(1, 1, 0) # o mais longe possível, sem planta
	amb.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	camera_mascara.environment = amb
	vp_mascara.add_child(camera_mascara)
	camera_mascara.current = true

	var camada := CanvasLayer.new()
	camada.layer = 0
	add_child(camada)
	pos_mao = TextureRect.new()
	pos_mao.texture = vp_mascara.get_texture()
	pos_mao.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pos_mao.stretch_mode = TextureRect.STRETCH_SCALE
	pos_mao.set_anchors_preset(Control.PRESET_FULL_RECT)
	pos_mao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# sem suavizar: a distância está guardada em dois canais e não pode ser misturada
	pos_mao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/mao.gdshader")
	pos_mao.material = mat
	camada.add_child(pos_mao)


func ajustar_tamanho() -> void:
	vp_mascara.size = get_viewport().size
	# traço de 1 pixel, ou 2 em telas de alta densidade (Retina)
	var escala := clampf(DisplayServer.screen_get_scale(), 1.0, 2.0)
	(pos_mao.material as ShaderMaterial).set_shader_parameter("espessura", escala)


# ---------- Câmera ----------

func posicionar_camera() -> void:
	var dir := Vector3(sin(polar) * sin(azimute), cos(polar), sin(polar) * cos(azimute))
	camera.transform = Transform3D(Basis(), alvo + dir * DISTANCIA).looking_at(alvo, Vector3.UP)
	camera.size = 2.0 * VISTAS[vista].meia / zoom
	# a barra de baixo cobre um pedaço da tela: sobe um pouco o enquadramento
	camera.v_offset = -0.12 * camera.size
	camera_mascara.global_transform = camera.global_transform
	camera_mascara.size = camera.size
	camera_mascara.v_offset = camera.v_offset


func limitar_camera() -> void:
	alvo = Vector3(clampf(alvo.x, -3.5, 3.5), clampf(alvo.y, -0.5, 2.5), clampf(alvo.z, -3.0, 3.0))
	azimute = clampf(azimute, AZIMUTE_MIN, AZIMUTE_MAX)
	polar = clampf(polar, POLAR_MIN, POLAR_MAX)
	zoom = clampf(zoom, ZOOM_MIN, ZOOM_MAX)


func focar(i: int) -> void:
	foco = {"alvo": PONTOS[i].p + Vector3(0, 0.5, 0), "zoom": 2.3}


## Volta ao enquadramento inicial: centro, zoom e ângulo da vista atual.
func posicao_inicial() -> void:
	foco = {"alvo": ALVO_INICIAL, "zoom": 1.0, "azimute": VISTAS[vista].azimute, "polar": VISTAS[vista].polar}
	if girando:
		alternar_giro()


func mover_camera(dt: float) -> void:
	if girando:
		azimute += sentido_giro * dt * 0.17
		if azimute >= AZIMUTE_MAX - 0.01:
			sentido_giro = -1.0
		elif azimute <= AZIMUTE_MIN + 0.01:
			sentido_giro = 1.0
	if not foco.is_empty():
		var k := minf(1.0, dt * 4.0)
		var destino: Vector3 = foco.alvo
		alvo = alvo.lerp(destino, k)
		zoom = lerpf(zoom, foco.zoom, k)
		var chegou: bool = alvo.distance_to(destino) < 0.005 and absf(zoom - foco.zoom) < 0.005
		if foco.has("azimute"):
			azimute = lerpf(azimute, foco.azimute, k)
			polar = lerpf(polar, foco.polar, k)
			chegou = chegou and absf(azimute - foco.azimute) < 0.002 and absf(polar - foco.polar) < 0.002
		if chegou:
			foco = {}
	limitar_camera()
	posicionar_camera()


func arrastar(relativo: Vector2) -> void:
	var por_pixel := camera.size / get_viewport().get_visible_rect().size.y
	var b := camera.global_transform.basis
	alvo += (-b.x * relativo.x + b.y * relativo.y) * por_pixel


func girar_camera(relativo: Vector2) -> void:
	var altura := get_viewport().get_visible_rect().size.y
	azimute -= TAU * relativo.x / altura
	polar -= TAU * relativo.y / altura


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton:
		var e := evento as InputEventMouseButton
		match e.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if e.pressed:
					zoom *= pow(1.05, maxf(e.factor, 1.0))
					foco = {}
			MOUSE_BUTTON_WHEEL_DOWN:
				if e.pressed:
					zoom /= pow(1.05, maxf(e.factor, 1.0))
					foco = {}
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				if e.pressed:
					arrastando = e.button_index
					inicio_toque = e.position
					movimento_toque = 0.0
				elif arrastando == e.button_index:
					arrastando = -1
					if e.button_index == MOUSE_BUTTON_LEFT and movimento_toque < 6.0:
						tocar(e.position)
	elif evento is InputEventMouseMotion:
		var e := evento as InputEventMouseMotion
		if toques.size() >= 2:
			return
		if arrastando < 0:
			hover = ponto_sob(e.position)
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hover >= 0 else Input.CURSOR_ARROW)
			return
		movimento_toque += e.relative.length()
		if movimento_toque < 6.0:
			return
		foco = {}
		if arrastando == MOUSE_BUTTON_LEFT:
			arrastar(e.relative)
		else:
			girar_camera(e.relative)
	elif evento is InputEventMagnifyGesture:
		zoom *= (evento as InputEventMagnifyGesture).factor
		foco = {}
	elif evento is InputEventPanGesture:
		# dois dedos no trackpad do Mac: aproxima e afasta
		zoom *= pow(1.02, -(evento as InputEventPanGesture).delta.y)
		foco = {}
	elif evento is InputEventScreenTouch:
		var e := evento as InputEventScreenTouch
		if e.pressed:
			toques[e.index] = e.position
		else:
			toques.erase(e.index)
	elif evento is InputEventScreenDrag:
		# com dois dedos: pinça aproxima, arrastar junto gira (um dedo já chega como mouse e move o cenário)
		var e := evento as InputEventScreenDrag
		if not toques.has(e.index):
			return
		var antes: Dictionary = toques.duplicate()
		toques[e.index] = e.position
		if toques.size() != 2:
			return
		var ids := toques.keys()
		var d_antes: float = (antes[ids[0]] as Vector2).distance_to(antes[ids[1]])
		var d_agora: float = (toques[ids[0]] as Vector2).distance_to(toques[ids[1]])
		if d_antes > 1.0:
			zoom *= d_agora / d_antes
		girar_camera(e.relative / 2.0)
		movimento_toque = 99.0 # não conta como toque quando os dedos soltarem
		foco = {}


func tocar(pos: Vector2) -> void:
	var i := ponto_sob(pos)
	hover = i
	if i >= 0:
		clicar(i)
		focar(i)
		ultimo_toque = -1000
		return
	# dois cliques (ou toques) rápidos fora dos vasos voltam para a posição inicial
	var agora := Time.get_ticks_msec()
	if agora - ultimo_toque < 350:
		posicao_inicial()
		ultimo_toque = -1000
	else:
		ultimo_toque = agora


func ponto_sob(pos: Vector2) -> int:
	var origem := camera.project_ray_origin(pos)
	var direcao := camera.project_ray_normal(pos)
	var melhor := -1
	var menor := INF
	for i in PONTOS.size():
		var p: Vector3 = PONTOS[i].p
		var caixa_clique := AABB(p + Vector3(-0.275, -0.05, -0.275), Vector3(0.55, 1.1, 0.55))
		var hit = caixa_clique.intersects_ray(origem, direcao)
		if hit != null:
			var dist := origem.distance_to(hit)
			if dist < menor:
				menor = dist
				melhor = i
	return melhor


# ---------- Regras ----------

func avancar(dt: float) -> void:
	estado.t += dt
	for ponto in PONTOS:
		var v = estado.pontos.get(ponto.id)
		if v == null or v.planta == null:
			continue
		var p: Dictionary = v.planta
		if p.estagio >= 2 or estado.t >= p.molhado_ate:
			continue
		var def: Dictionary = PLANTAS[p.tipo]
		p.progresso += dt * def.luz[ponto.luz]
		if p.progresso >= def.tempos[int(p.estagio)]:
			p.progresso = 0.0
			p.estagio = int(p.estagio) + 1


func aconchego() -> int:
	var total := 0
	for ponto in PONTOS:
		var v = estado.pontos.get(ponto.id)
		if v == null:
			continue
		total += int(VASOS[v.vaso].charme)
		if v.planta == null:
			continue
		var estagio := int(v.planta.estagio)
		total += estagio
		if estagio == 2:
			var luz: float = PLANTAS[v.planta.tipo].luz[ponto.luz]
			total += 3 if luz == 1.0 else (1 if luz >= 0.6 else 0)
	return total


func confirmar(i: int, acao: String, msg: String) -> bool:
	var agora := Time.get_ticks_msec()
	if confirmacao.get("i", -99) == i and confirmacao.get("acao", "") == acao and agora < int(confirmacao.get("ate", 0)):
		confirmacao = {}
		return true
	confirmacao = {"i": i, "acao": acao, "ate": agora + 3000}
	status(msg)
	return false


func clicar(i: int) -> void:
	var ponto: Dictionary = PONTOS[i]
	var v = estado.pontos.get(ponto.id)
	var p = v.planta if v != null else null

	if ferramenta == "regador":
		if p == null:
			status("Coloque uma planta aqui antes de regar.")
			return
		p.molhado_ate = estado.t + PLANTAS[p.tipo].seca
		status("%s regada." % PLANTAS[p.tipo].nome)
		salvar()
		return
	if ferramenta == "tirar":
		if v == null:
			status("Não tem nada aqui.")
			return
		var oque: String = ("a " + String(PLANTAS[p.tipo].nome).to_lower()) if p != null else "o vaso"
		if not confirmar(i, "tirar", "Clique de novo para tirar %s daqui." % oque):
			return
		estado.pontos.erase(ponto.id)
		status("Espaço livre de novo.")
		salvar()
		return
	if ferramenta == "vaso":
		if v != null and v.vaso == vaso_escolhido:
			status("Este vaso já é desse tipo.")
			return
		estado.pontos[ponto.id] = {"vaso": vaso_escolhido, "planta": p}
		if v != null:
			status("Vaso trocado para %s." % String(VASOS[vaso_escolhido].nome).to_lower())
		else:
			status("Vaso colocado. Agora escolha uma planta para ele.")
		salvar()
		return
	var def: Dictionary = PLANTAS[ferramenta]
	if p != null:
		status("Este vaso já tem uma planta.")
		return
	estado.pontos[ponto.id] = {"vaso": v.vaso if v != null else vaso_escolhido, "planta": {"tipo": ferramenta, "estagio": 0, "progresso": 0.0, "molhado_ate": 0.0}}
	var luz: float = def.luz[ponto.luz]
	var aviso := "Ela adora essa luz!" if luz == 1.0 else ("A luz aqui é razoável para ela." if luz >= 0.6 else "Ela não gosta dessa luz e vai crescer bem devagar.")
	status("%s colocada: %s. %s Agora regue." % [def.nome, String(ponto.nome).to_lower(), aviso])
	salvar()


## Sincroniza os objetos 3D de um ponto com o estado do jogo.
func sincronizar(i: int, dt: float) -> void:
	var vis: Dictionary = visuais[i]
	var ponto: Dictionary = PONTOS[i]
	var v = estado.pontos.get(ponto.id)
	var g: Node3D = vis.g
	vis.luz.visible = i == hover
	var mais: Sprite3D = vis.mais
	mais.visible = v == null
	mais.modulate.a = 0.6 + 0.35 * sin(tempo * 2.2 + i)

	var vaso_tipo: String = v.vaso if v != null else ""
	if vaso_tipo != vis.vaso_tipo:
		if vis.vaso != null:
			vis.vaso.queue_free()
		vis.vaso = null
		if vaso_tipo != "":
			var vaso := Plantas.criar_vaso(vaso_tipo, Color(VASOS[vaso_tipo].cor))
			Materiais.mascarar(vaso, false)
			g.add_child(vaso)
			vis.vaso = vaso
		vis.vaso_tipo = vaso_tipo

	var p = v.planta if v != null else null
	var planta_tipo: String = p.tipo if p != null else ""
	if planta_tipo != vis.planta_tipo:
		if vis.planta != null:
			vis.planta.queue_free()
		vis.planta = null
		if planta_tipo != "":
			var planta := Plantas.criar_planta(planta_tipo)
			Materiais.mascarar(planta, true)
			planta.position.y = 0.28
			g.add_child(planta)
			vis.planta = planta
		vis.planta_tipo = planta_tipo
		vis.escala = 0.05
		vis.nasceu = tempo

	vis.gota.visible = false
	if p == null:
		return
	var planta_no: Node3D = vis.planta
	var alvo_escala: float = [0.38, 0.68, 1.0][int(p.estagio)]
	vis.escala = lerpf(vis.escala, alvo_escala, minf(1.0, dt * 3.0))
	# pulinho elástico quando a planta acaba de ser colocada
	var k: float = tempo - vis.nasceu
	var pulo := 1.0 + 0.25 * sin(k * 14.0) * exp(-k * 4.0) if k < 1.5 else 1.0
	planta_no.scale = Vector3.ONE * (vis.escala * pulo)
	# balanço suave em loop, com fase diferente por vaso
	planta_no.rotation = Vector3(sin(tempo * 1.1 + i * 0.7) * 0.03, 0.0, sin(tempo * 1.4 + i * 1.3) * 0.045)
	var molhada: bool = estado.t < p.molhado_ate
	var terra: MeshInstance3D = vis.vaso.get_node("Terra")
	terra.material_override = Materiais.toon(Color("3e2718") if molhada else Color("5a3a26"))
	if not molhada:
		vis.gota.visible = true
		vis.gota.position = Vector3(0.22, 0.45 + vis.escala * 0.6 + sin(tempo * 4.0) * 0.03, 0.1)
	# planta adulta feliz solta coraçõezinhos de vez em quando
	var feliz: bool = int(p.estagio) == 2 and molhada and PLANTAS[p.tipo].luz[ponto.luz] == 1.0
	if feliz and randf() < dt * 0.35:
		var c := icone(tex_coracao, 0.16)
		c.position = Vector3(randf_range(-0.15, 0.15), 0.7, randf_range(-0.15, 0.15))
		c.set_meta("vida", 1.6)
		g.add_child(c)
		vis.coracoes.append(c)
	var coracoes: Array = vis.coracoes
	for j in range(coracoes.size() - 1, -1, -1):
		var c: Sprite3D = coracoes[j]
		var vida: float = c.get_meta("vida") - dt
		c.set_meta("vida", vida)
		c.position.y += dt * 0.25
		c.modulate.a = minf(1.0, vida)
		if vida <= 0.0:
			c.queue_free()
			coracoes.remove_at(j)


# ---------- Laço ----------

func _process(delta: float) -> void:
	var dt := minf(delta, 0.1)
	tempo += dt
	avancar(dt)
	for i in PONTOS.size():
		sincronizar(i, dt)
	# gato respirando, TV piscando, relógio andando e abajur tremeluzindo
	gato.scale.y = 1.0 + sin(tempo * 2.4) * 0.04
	(tela_tv.material_override as ShaderMaterial).set_shader_parameter("forca_emissao", 0.7 + (0.25 if int(floor(tempo * 1.2)) % 3 == 0 else 0.0))
	ponteiro_relogio.rotation.z = -tempo * 0.2
	abajur.light_energy = 0.85 + sin(tempo * 0.7) * 0.05
	mover_camera(dt)
	lbl_aconchego.text = "♥ Aconchego %d" % aconchego()
	lbl_info.text = descrever(hover)
	if tempo - ultimo_save > 5.0:
		salvar()
		ultimo_save = tempo


# ---------- Interface ----------

func status(msg: String) -> void:
	if lbl_status:
		lbl_status.text = msg


func descrever(i: int) -> String:
	if i < 0:
		return "Passe o mouse ou toque num espaço com + para ver a luz de cada canto."
	var ponto: Dictionary = PONTOS[i]
	var v = estado.pontos.get(ponto.id)
	var txt := "%s · %s" % [ponto.nome, LUZES[ponto.luz]]
	if v == null:
		return txt + " · livre"
	if v.planta == null:
		return txt + " · vaso de %s vazio" % String(VASOS[v.vaso].nome).to_lower()
	var p: Dictionary = v.planta
	var def: Dictionary = PLANTAS[p.tipo]
	var luz: float = def.luz[ponto.luz]
	txt += " · %s, %s" % [def.nome, ESTAGIOS[int(p.estagio)]]
	txt += ", feliz com a luz" if luz == 1.0 else (", luz razoável" if luz >= 0.6 else ", não gosta dessa luz")
	if estado.t < p.molhado_ate:
		txt += ", terra molhada por mais %ds" % ceili(p.molhado_ate - estado.t)
	else:
		txt += ", com sede"
	return txt


func estilo_caixa(fundo: Color, borda: Color, largura := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.border_color = borda
	s.set_border_width_all(largura)
	s.shadow_color = borda
	s.shadow_size = 0
	s.shadow_offset = Vector2(3, 3)
	s.set_content_margin_all(8)
	return s


func criar_tema() -> Theme:
	var t := Theme.new()
	t.default_font_size = 15
	t.set_color("font_color", "Label", TINTA)
	for estado_botao in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var cor_borda := DESTAQUE if estado_botao in ["pressed", "hover_pressed"] else MADEIRA
		var cor_fundo := Color("fbe1e7") if estado_botao in ["pressed", "hover_pressed"] else (Color("fffbe9") if estado_botao == "hover" else PAPEL)
		var s := estilo_caixa(cor_fundo, cor_borda)
		if estado_botao == "focus":
			s.draw_center = false
		t.set_stylebox(estado_botao, "Button", s)
	for cor_nome in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(cor_nome, "Button", TINTA)
	t.set_stylebox("panel", "PanelContainer", estilo_caixa(Color(PAPEL, 0.94), MADEIRA))
	return t


func montar_interface() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 1
	add_child(camada)
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.theme = criar_tema()
	camada.add_child(raiz)

	# topo: título, aconchego e opções de câmera
	var topo := HBoxContainer.new()
	topo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	topo.offset_left = 16
	topo.offset_right = -16
	topo.offset_top = 12
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topo.add_theme_constant_override("separation", 10)
	raiz.add_child(topo)
	var titulo := Label.new()
	titulo.text = "Sala Cozy"
	titulo.add_theme_font_size_override("font_size", 28)
	titulo.add_theme_color_override("font_color", MADEIRA)
	titulo.add_theme_color_override("font_shadow_color", PAPEL)
	titulo.add_theme_constant_override("shadow_offset_x", 2)
	titulo.add_theme_constant_override("shadow_offset_y", 2)
	topo.add_child(titulo)
	var painel_aconchego := PanelContainer.new()
	painel_aconchego.tooltip_text = "Aconchego: plantas adultas felizes com a luz, e vasos bonitos"
	topo.add_child(painel_aconchego)
	lbl_aconchego = Label.new()
	lbl_aconchego.add_theme_font_size_override("font_size", 18)
	painel_aconchego.add_child(lbl_aconchego)
	var espaco := Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	espaco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topo.add_child(espaco)
	btn_vista = Button.new()
	btn_vista.text = "Câmera do alto"
	btn_vista.toggle_mode = true
	btn_vista.toggled.connect(func(_ligado: bool) -> void: trocar_vista())
	topo.add_child(btn_vista)
	btn_girar = Button.new()
	btn_girar.text = "Girar a sala"
	btn_girar.toggle_mode = true
	btn_girar.toggled.connect(func(ligado: bool) -> void: girando = ligado)
	topo.add_child(btn_girar)
	var btn_recomecar := Button.new()
	btn_recomecar.text = "Recomeçar"
	btn_recomecar.pressed.connect(recomecar)
	topo.add_child(btn_recomecar)

	# baixo: informação do ponto, barra de plantas/vasos/cuidados e mensagem
	var baixo := VBoxContainer.new()
	baixo.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	baixo.offset_left = 16
	baixo.offset_right = -16
	baixo.offset_bottom = -12
	baixo.grow_vertical = Control.GROW_DIRECTION_BEGIN
	baixo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(baixo)
	lbl_info = Label.new()
	lbl_info.add_theme_color_override("font_color", TINTA_SUAVE)
	lbl_info.add_theme_color_override("font_outline_color", PAPEL)
	lbl_info.add_theme_constant_override("outline_size", 6)
	baixo.add_child(lbl_info)
	var barra := HBoxContainer.new()
	barra.add_theme_constant_override("separation", 18)
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baixo.add_child(barra)
	var grupo_ferramentas := ButtonGroup.new()

	var plantas := grupo(barra, "PLANTAS", 3)
	for id in PLANTAS:
		var def: Dictionary = PLANTAS[id]
		botao(plantas, id, def.nome, def.gosta, Color(def.cor), def.dica, grupo_ferramentas, escolher.bind(id))
	var vasos := grupo(barra, "VASOS", 3)
	for id in VASOS:
		var def: Dictionary = VASOS[id]
		var detalhe: String = ("+%d aconchego" % def.charme) if def.charme > 0 else "simples"
		botao(vasos, "vaso-" + id, def.nome, detalhe, Color(def.cor), "Usa este vaso nas próximas plantas, ou clique num vaso da sala para trocar.", grupo_ferramentas, escolher_vaso.bind(id))
	var cuidados := grupo(barra, "CUIDADOS", 2)
	botao(cuidados, "regador", "Regador", "molha a terra", Color("5fa8d8"), "Plantas só crescem com a terra molhada.", grupo_ferramentas, escolher.bind("regador"))
	botao(cuidados, "tirar", "Tirar", "libera o espaço", Color("a8703f"), "Remove o vaso e a planta. Pede confirmação.", grupo_ferramentas, escolher.bind("tirar"))

	var painel_status := PanelContainer.new()
	baixo.add_child(painel_status)
	lbl_status = Label.new()
	lbl_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	painel_status.add_child(lbl_status)


func grupo(pai: Control, titulo: String, peso: int) -> HBoxContainer:
	var caixa_grupo := VBoxContainer.new()
	caixa_grupo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caixa_grupo.size_flags_stretch_ratio = peso
	caixa_grupo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(caixa_grupo)
	var rotulo := Label.new()
	rotulo.text = titulo
	rotulo.add_theme_font_size_override("font_size", 12)
	rotulo.add_theme_color_override("font_color", TINTA_SUAVE)
	rotulo.add_theme_color_override("font_outline_color", PAPEL)
	rotulo.add_theme_constant_override("outline_size", 6)
	caixa_grupo.add_child(rotulo)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 8)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa_grupo.add_child(linha)
	return linha


func botao(pai: Control, id: String, rotulo: String, detalhe: String, cor: Color, dica: String, grupo_botoes: ButtonGroup, acao: Callable) -> void:
	var b := Button.new()
	b.toggle_mode = true
	b.button_group = grupo_botoes
	b.tooltip_text = dica
	b.text = "%s\n%s" % [rotulo, detalhe]
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_text = true
	b.focus_mode = Control.FOCUS_NONE
	# amostra da cor, como nos botões do protótipo
	var img := Image.create_empty(18, 18, false, Image.FORMAT_RGBA8)
	img.fill(TINTA)
	img.fill_rect(Rect2i(2, 2, 14, 14), cor)
	b.icon = ImageTexture.create_from_image(img)
	b.pressed.connect(acao)
	pai.add_child(b)
	botoes[id] = b


func marcar() -> void:
	var id := "vaso-" + vaso_escolhido if ferramenta == "vaso" else ferramenta
	if botoes.has(id):
		(botoes[id] as Button).set_pressed_no_signal(true)


func escolher(id: String) -> void:
	ferramenta = id
	marcar()
	if PLANTAS.has(id):
		status("%s: %s Clique num espaço com + na sala." % [PLANTAS[id].nome, PLANTAS[id].dica])
	elif id == "regador":
		status("Regador na mão. Clique nas plantas com a gotinha de sede.")
	else:
		status("Clique num vaso da sala para tirá-lo.")


func escolher_vaso(id: String) -> void:
	vaso_escolhido = id
	ferramenta = "vaso"
	marcar()
	status("Vaso de %s escolhido. Clique num espaço livre para colocar, ou num vaso da sala para trocar." % String(VASOS[id].nome).to_lower())


func trocar_vista() -> void:
	vista = "alto" if vista == "diorama" else "diorama"
	foco = {}
	alvo = ALVO_INICIAL
	zoom = 1.0
	azimute = VISTAS[vista].azimute
	polar = VISTAS[vista].polar


func alternar_giro() -> void:
	btn_girar.button_pressed = not btn_girar.button_pressed


func recomecar() -> void:
	if not confirmar(-2, "recomecar", "Clique de novo em \"Recomeçar\" para esvaziar a sala."):
		return
	estado = {"t": 0.0, "pontos": {}}
	salvar()
	status("Sala vazia de novo.")
