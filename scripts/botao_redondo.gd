class_name BotaoRedondo
extends Button
## Botão redondo de papel, com borda de madeira e um ícone simples desenhado no meio.
## Tipos: violeta, rosa, costela, vaso, regador, tirar, menu, cor.

const PAPEL := Color("fff6d8")
const PAPEL_MARCADO := Color("fbe1e7")
const MADEIRA := Color("7a4a2e")
const DESTAQUE := Color("dd4b67")
const TINTA := Color("3b2f26")

var tipo := "cor"
var cor := Color.WHITE
var raio := 26.0


func _init(p_tipo := "cor", p_cor := Color.WHITE, p_raio := 26.0) -> void:
	tipo = p_tipo
	cor = p_cor
	raio = p_raio
	custom_minimum_size = Vector2.ONE * (raio * 2.0 + 10.0)
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for estado in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(estado, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	toggled.connect(func(_ligado: bool) -> void: queue_redraw())


func definir_cor(nova: Color) -> void:
	cor = nova
	queue_redraw()


func _has_point(ponto: Vector2) -> bool:
	return ponto.distance_to(size / 2.0) <= raio + 4.0


func _draw() -> void:
	var c := size / 2.0
	var r := raio + (2.0 if is_hovered() else 0.0)
	var marcado := button_pressed
	# sombra deslocada, como um recorte de papel colado
	draw_circle(c + Vector2(2, 3), r, Color(MADEIRA, 0.3))
	draw_circle(c, r, PAPEL_MARCADO if marcado else PAPEL)
	var e := r / 26.0 # escala do ícone
	match tipo:
		"violeta":
			for k in 5:
				var a := -PI / 2.0 + TAU * k / 5.0
				draw_circle(c + Vector2(cos(a), sin(a)) * 8.0 * e, 6.5 * e, cor)
				draw_arc(c + Vector2(cos(a), sin(a)) * 8.0 * e, 6.5 * e, 0.0, TAU, 20, Color(TINTA, 0.5), 1.0, true)
			draw_circle(c, 3.6 * e, Color("f6d861"))
		"rosa":
			draw_circle(c, 13.0 * e, cor.darkened(0.3))
			draw_circle(c + Vector2(0.5, -0.5) * e, 10.0 * e, cor)
			draw_arc(c, 6.5 * e, 0.3, 4.8, 18, cor.lightened(0.45), 2.0 * e, true)
			draw_arc(c + Vector2(0.5, -0.5) * e, 3.0 * e, 2.5, 7.5, 14, cor.lightened(0.45), 1.8 * e, true)
			draw_arc(c, 13.0 * e, 0.0, TAU, 32, Color(TINTA, 0.5), 1.0, true)
		"costela":
			var folha := PackedVector2Array()
			for k in 24:
				var a := TAU * k / 24.0
				folha.append(c + Vector2(cos(a) * 12.0, sin(a) * 14.0 + 1.0) * e)
			draw_colored_polygon(folha, cor)
			folha.append(folha[0])
			draw_polyline(folha, Color(TINTA, 0.5), 1.0, true)
			# recortes da folha e nervura central
			var fundo := PAPEL_MARCADO if marcado else PAPEL
			for lado in [-1.0, 1.0]:
				for y in [-6.0, 0.0, 6.0]:
					draw_line(c + Vector2(lado * 12.5, y) * e, c + Vector2(lado * 5.0, y - 2.0) * e, fundo, 2.4 * e, true)
			draw_line(c + Vector2(0, -12) * e, c + Vector2(0, 15) * e, cor.lightened(0.4), 1.6 * e, true)
		"vaso":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-10, -3) * e, c + Vector2(10, -3) * e, c + Vector2(7, 12) * e, c + Vector2(-7, 12) * e]), cor)
			draw_rect(Rect2(c + Vector2(-12.5, -8) * e, Vector2(25, 6) * e), cor.lightened(0.15))
			draw_rect(Rect2(c + Vector2(-12.5, -8) * e, Vector2(25, 6) * e), Color(TINTA, 0.5), false, 1.0)
			draw_polyline(PackedVector2Array([c + Vector2(-10, -2) * e, c + Vector2(-7, 12) * e, c + Vector2(7, 12) * e, c + Vector2(10, -2) * e]), Color(TINTA, 0.5), 1.0, true)
			draw_line(c + Vector2(0, -8) * e, c + Vector2(0, -14) * e, Color("4c9a45"), 2.0 * e, true)
			draw_circle(c + Vector2(-3, -14) * e, 3.0 * e, Color("4c9a45"))
			draw_circle(c + Vector2(3, -15) * e, 3.0 * e, Color("5aa850"))
		"regador":
			var azul := Color("5fa8d8")
			draw_circle(c + Vector2(0, 4) * e, 9.0 * e, azul)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -13) * e, c + Vector2(-7.8, -0.5) * e, c + Vector2(7.8, -0.5) * e]), azul)
			draw_circle(c + Vector2(-3, 3) * e, 2.6 * e, Color("a9dcf5"))
		"tirar":
			var vinho := Color("b4646e")
			draw_line(c + Vector2(-8, -8) * e, c + Vector2(8, 8) * e, vinho, 4.0 * e, true)
			draw_line(c + Vector2(8, -8) * e, c + Vector2(-8, 8) * e, vinho, 4.0 * e, true)
		"menu":
			for x in [-7.0, 0.0, 7.0]:
				draw_circle(c + Vector2(x, 0) * e, 2.6 * e, TINTA)
		_:
			draw_circle(c, r - 4.0, cor)
	draw_arc(c, r, 0.0, TAU, 48, DESTAQUE if marcado else MADEIRA, 3.0 if marcado else 2.0, true)
