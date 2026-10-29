class_name Hud
extends Control
## Interface limpa: aconchego num cantinho, um menu escondido e uma barra de botões redondos.
## Ao escolher uma planta (ou o vaso), abrem bolinhas em volta do botão para escolher a cor.

signal ferramenta_escolhida(id: String)
signal cor_escolhida(planta: String, cor: String)
signal vaso_escolhido(id: String)
signal vista_trocada
signal giro_alternado(ligado: bool)
signal recomecar_pedido

const PAPEL := Color("fff6d8")
const TINTA := Color("3b2f26")
const TINTA_SUAVE := Color("6b5a49")
const MADEIRA := Color("7a4a2e")
const DESTAQUE := Color("dd4b67")

var plantas: Dictionary
var vasos: Dictionary

var lbl_aconchego: Label
var aviso: PanelContainer
var lbl_aviso: Label
var dica: Label
var menu: VBoxContainer
var btn_vista: Button
var btn_giro: Button
var botoes := {} # id da ferramenta -> BotaoRedondo
var grupo := ButtonGroup.new()
var anel: Array[BotaoRedondo] = []
var anel_origem: BotaoRedondo
var tween_aviso: Tween


func montar(p_plantas: Dictionary, p_vasos: Dictionary, cores: Dictionary, vaso_atual: String) -> void:
	plantas = p_plantas
	vasos = p_vasos
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = criar_tema()

	# aconchego, pequeno no canto de cima
	var pilula := PanelContainer.new()
	pilula.position = Vector2(16, 14)
	pilula.tooltip_text = "Aconchego: plantas adultas felizes com a luz, e vasos bonitos"
	add_child(pilula)
	lbl_aconchego = Label.new()
	lbl_aconchego.add_theme_font_size_override("font_size", 18)
	pilula.add_child(lbl_aconchego)

	# menu escondido no canto: câmera, giro e recomeçar
	var btn_menu := BotaoRedondo.new("menu", Color.WHITE, 18.0)
	btn_menu.tooltip_text = "Opções"
	btn_menu.anchor_left = 1.0
	btn_menu.anchor_right = 1.0
	btn_menu.offset_left = -64
	btn_menu.offset_right = -18
	btn_menu.offset_top = 10
	btn_menu.offset_bottom = 56
	btn_menu.pressed.connect(func() -> void: menu.visible = not menu.visible)
	add_child(btn_menu)
	menu = VBoxContainer.new()
	menu.anchor_left = 1.0
	menu.anchor_right = 1.0
	menu.offset_left = -18
	menu.offset_right = -18
	menu.offset_top = 62
	menu.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	menu.alignment = BoxContainer.ALIGNMENT_END
	menu.visible = false
	add_child(menu)
	btn_vista = opcao_menu("Câmera do alto", true)
	btn_vista.toggled.connect(func(_ligado: bool) -> void: vista_trocada.emit())
	btn_giro = opcao_menu("Girar a sala", true)
	btn_giro.toggled.connect(func(ligado: bool) -> void: giro_alternado.emit(ligado))
	var btn_recomecar := opcao_menu("Recomeçar", false)
	btn_recomecar.pressed.connect(func() -> void: recomecar_pedido.emit())

	# barra de baixo: plantas | vaso | cuidados
	var barra := PanelContainer.new()
	barra.anchor_left = 0.5
	barra.anchor_right = 0.5
	barra.anchor_top = 1.0
	barra.anchor_bottom = 1.0
	barra.offset_bottom = -14
	barra.grow_horizontal = Control.GROW_DIRECTION_BOTH
	barra.grow_vertical = Control.GROW_DIRECTION_BEGIN
	barra.add_theme_stylebox_override("panel", estilo_pilula(Color(PAPEL, 0.82), 32, 10))
	add_child(barra)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 6)
	barra.add_child(linha)
	for id in plantas:
		var def: Dictionary = plantas[id]
		var b := ferramenta(linha, id, id, Color(cores.get(id, def.cores[0])), "%s: %s" % [def.nome, def.gosta])
		b.pressed.connect(_ao_tocar_planta.bind(id))
	separador(linha)
	var b_vaso := ferramenta(linha, "vaso", "vaso", Color(vasos[vaso_atual].cor), "Vaso: coloque num espaço livre ou troque um vaso da sala")
	b_vaso.pressed.connect(_ao_tocar_vaso)
	separador(linha)
	var b_regador := ferramenta(linha, "regador", "regador", Color.WHITE, "Regador: plantas só crescem com a terra molhada")
	b_regador.pressed.connect(_ao_tocar_cuidado.bind("regador"))
	var b_tirar := ferramenta(linha, "tirar", "tirar", Color.WHITE, "Tirar: libera o espaço (pede confirmação)")
	b_tirar.pressed.connect(_ao_tocar_cuidado.bind("tirar"))

	# aviso que aparece e some sozinho, logo acima da barra
	aviso = PanelContainer.new()
	aviso.anchor_left = 0.5
	aviso.anchor_right = 0.5
	aviso.anchor_top = 1.0
	aviso.anchor_bottom = 1.0
	aviso.offset_bottom = -104
	aviso.grow_horizontal = Control.GROW_DIRECTION_BOTH
	aviso.grow_vertical = Control.GROW_DIRECTION_BEGIN
	aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aviso.modulate.a = 0.0
	aviso.add_theme_stylebox_override("panel", estilo_pilula(Color(PAPEL, 0.95), 16, 2))
	add_child(aviso)
	lbl_aviso = Label.new()
	lbl_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.add_child(lbl_aviso)

	# dica pequena que acompanha o ponteiro em cima dos espaços de vaso
	dica = Label.new()
	dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dica.add_theme_font_size_override("font_size", 13)
	dica.add_theme_color_override("font_color", TINTA)
	dica.add_theme_color_override("font_outline_color", PAPEL)
	dica.add_theme_constant_override("outline_size", 7)
	dica.visible = false
	add_child(dica)


func _ao_tocar_planta(id: String) -> void:
	ferramenta_escolhida.emit(id)
	alternar_anel(botoes[id], opcoes_de_cor(id), _ao_escolher_cor.bind(id))


func _ao_escolher_cor(valor: String, id: String) -> void:
	(botoes[id] as BotaoRedondo).definir_cor(Color(valor))
	cor_escolhida.emit(id, valor)


func _ao_tocar_vaso() -> void:
	ferramenta_escolhida.emit("vaso")
	alternar_anel(botoes["vaso"], opcoes_de_vaso(), _ao_escolher_vaso)


func _ao_escolher_vaso(id: String) -> void:
	(botoes["vaso"] as BotaoRedondo).definir_cor(Color(vasos[id].cor))
	vaso_escolhido.emit(id)


func _ao_tocar_cuidado(id: String) -> void:
	fechar_anel()
	ferramenta_escolhida.emit(id)


func _ao_tocar_bolinha(ao_escolher: Callable, valor: String) -> void:
	ao_escolher.call(valor)
	fechar_anel()


func ferramenta(pai: Control, id: String, tipo: String, cor: Color, texto: String) -> BotaoRedondo:
	var b := BotaoRedondo.new(tipo, cor, 25.0)
	b.toggle_mode = true
	b.button_group = grupo
	b.tooltip_text = texto
	pai.add_child(b)
	botoes[id] = b
	return b


func separador(pai: Control) -> void:
	var s := ColorRect.new()
	s.color = Color(MADEIRA, 0.25)
	s.custom_minimum_size = Vector2(2, 34)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(s)


func opcao_menu(texto: String, alternar: bool) -> Button:
	var b := Button.new()
	b.text = texto
	b.toggle_mode = alternar
	b.focus_mode = Control.FOCUS_NONE
	menu.add_child(b)
	return b


func opcoes_de_cor(planta: String) -> Array:
	var lista := []
	var def: Dictionary = plantas[planta]
	for i in def.cores.size():
		lista.append({"valor": def.cores[i], "cor": Color(def.cores[i]), "dica": def.nomes_cores[i], "tipo": "cor"})
	return lista


func opcoes_de_vaso() -> Array:
	var lista := []
	for id in vasos:
		var def: Dictionary = vasos[id]
		var extra: String = (" (+%d aconchego)" % def.charme) if def.charme > 0 else ""
		lista.append({"valor": id, "cor": Color(def.cor), "dica": def.nome + extra, "tipo": "vaso"})
	return lista


# ---------- Bolinhas em volta de um botão ----------

func alternar_anel(origem: BotaoRedondo, opcoes: Array, ao_escolher: Callable) -> void:
	var estava_aberto := anel_origem == origem
	fechar_anel()
	if estava_aberto:
		return
	anel_origem = origem
	var centro := origem.get_global_rect().get_center() - global_position
	var n := opcoes.size()
	var raio_anel := origem.raio + 34.0
	for k in n:
		# arco por cima do botão, da esquerda para a direita
		var t := 0.5 if n == 1 else float(k) / (n - 1)
		var a := lerpf(-PI + 0.35, -0.35, t)
		var op: Dictionary = opcoes[k]
		var bolinha := BotaoRedondo.new(op.tipo, op.cor, 14.0 if op.tipo == "cor" else 16.0)
		bolinha.tooltip_text = op.dica
		add_child(bolinha)
		bolinha.size = bolinha.custom_minimum_size
		bolinha.position = centro + Vector2(cos(a), sin(a)) * raio_anel - bolinha.size / 2.0
		bolinha.pivot_offset = bolinha.size / 2.0
		bolinha.scale = Vector2.ZERO
		bolinha.pressed.connect(_ao_tocar_bolinha.bind(ao_escolher, String(op.valor)))
		var tw := create_tween()
		tw.tween_interval(k * 0.03)
		tw.tween_property(bolinha, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		anel.append(bolinha)


func fechar_anel() -> void:
	for bolinha in anel:
		bolinha.queue_free()
	anel.clear()
	anel_origem = null


func _input(evento: InputEvent) -> void:
	if anel.is_empty():
		return
	if evento is InputEventKey and (evento as InputEventKey).pressed and (evento as InputEventKey).keycode == KEY_ESCAPE:
		fechar_anel()
		return
	var clique := evento as InputEventMouseButton
	if clique == null or not clique.pressed:
		return
	# clique fora das bolinhas e do botão de origem fecha o anel
	var pos := get_global_mouse_position()
	for bolinha in anel:
		if bolinha.get_global_rect().has_point(pos):
			return
	if anel_origem and anel_origem.get_global_rect().has_point(pos):
		return
	fechar_anel()


# ---------- Avisos e dicas ----------

func mostrar_aviso(msg: String) -> void:
	lbl_aviso.text = msg
	if tween_aviso:
		tween_aviso.kill()
	tween_aviso = create_tween()
	tween_aviso.tween_property(aviso, "modulate:a", 1.0, 0.15)
	tween_aviso.tween_interval(3.2)
	tween_aviso.tween_property(aviso, "modulate:a", 0.0, 0.6)


func mostrar_dica(texto: String, pos: Vector2) -> void:
	dica.visible = texto != ""
	if not dica.visible:
		return
	dica.text = texto
	dica.size = Vector2.ZERO
	var limite := get_viewport_rect().size - dica.get_combined_minimum_size() - Vector2(8, 8)
	dica.position = (pos + Vector2(18, 10)).clamp(Vector2(8, 8), limite)


func atualizar_aconchego(valor: int) -> void:
	lbl_aconchego.text = "♥ %d" % valor


func marcar(id: String) -> void:
	if botoes.has(id):
		(botoes[id] as BotaoRedondo).set_pressed_no_signal(true)
		(botoes[id] as BotaoRedondo).queue_redraw()


func desligar_giro() -> void:
	btn_giro.button_pressed = false


# ---------- Tema ----------

func estilo_pilula(fundo: Color, raio: int, margem: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.border_color = MADEIRA
	s.set_border_width_all(2)
	s.set_corner_radius_all(raio)
	s.set_content_margin_all(margem)
	s.content_margin_left = margem + 6
	s.content_margin_right = margem + 6
	s.shadow_color = Color(MADEIRA, 0.25)
	s.shadow_offset = Vector2(2, 3)
	s.shadow_size = 1
	return s


func criar_tema() -> Theme:
	var t := Theme.new()
	t.default_font_size = 15
	t.set_color("font_color", "Label", TINTA)
	t.set_stylebox("panel", "PanelContainer", estilo_pilula(Color(PAPEL, 0.9), 16, 4))
	for estado in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var marcado: bool = estado in ["pressed", "hover_pressed"]
		var s := estilo_pilula(Color("fbe1e7") if marcado else (Color("fffbe9") if estado == "hover" else PAPEL), 14, 6)
		s.border_color = DESTAQUE if marcado else MADEIRA
		if estado == "focus":
			s.draw_center = false
			s.border_color = Color.TRANSPARENT
		t.set_stylebox(estado, "Button", s)
	for nome in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(nome, "Button", TINTA)
	t.set_color("font_color", "TooltipLabel", TINTA)
	t.set_stylebox("panel", "TooltipPanel", estilo_pilula(PAPEL, 8, 4))
	return t
