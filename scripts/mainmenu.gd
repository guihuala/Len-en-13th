extends Control

const ButtonIcons = preload("res://scripts/button_icons.gd")
const ArtCatalog = preload("res://scripts/art_catalog.gd")
const Motion = preload("res://scripts/motion.gd")
const UITheme = preload("res://scripts/ui_theme.gd")
const CREDITS_TEXT = "[center]たびのきの木\n\n[b]制作[/b]\nmoku\n\n[b]原作[/b]\nJynX · 連縁Project\n\n[b]引擎[/b]\nGodot Engine\n\n[b]字体[/b]\n寒蝉半圆体 · ChillType\nZen Maru Gothic · The Zen Maru Gothic Project Authors\nNoto Sans SC / JP · Adobe / Google\nSIL Open Font License 1.1\n\n非官方同人作品\n感谢你来种树。[/center]"
var menu_time: float = 0.0
var credits_button: Button
var credits_dialog: Panel
var credits_body: RichTextLabel
var close_credits_button: Button

const INK = Color("25292c")
const MUTED = Color("475148")
var title: TextureRect
var footer: Label
var preview_panel: Panel
var studio_view: TextureRect
var preview_area: Control
var preview: Control
var start_button: Button
var new_button: Button
var sound_button: Button
var language_button: Button
var save_info: Label
var confirm_new: Panel
var confirm_shade: ColorRect
var confirm_title: Label
var confirm_body: Label
var cancel_button: Button
var restart_button: Button
var has_progress: bool = false

func _ready() -> void:
	GameState.paused=true
	title=%Title
	footer=%Footer
	preview_panel=%PreviewPanel
	studio_view=%PreviewPanel.get_node("%StudioView")
	preview_area=%PreviewPanel.get_node("%PreviewArea")
	preview=%PreviewPanel.get_node("%TreePreview")
	start_button=%StartButton
	new_button=%NewButton
	sound_button=%Settings.get_node("%SoundButton")
	language_button=%Settings.get_node("%LanguageButton")
	save_info=%SaveInfo
	confirm_new=%RestartDialog
	confirm_shade=%ConfirmShade
	confirm_title=%RestartDialog.get_node("%ConfirmTitle")
	confirm_body=%RestartDialog.get_node("%ConfirmBody")
	cancel_button=%RestartDialog.get_node("%CancelButton")
	restart_button=%RestartDialog.get_node("%RestartButton")

	credits_button=%Settings.get_node("%CreditsButton")
	credits_dialog=%CreditsDialog
	credits_body=%CreditsDialog.get_node("%CreditsBody")
	close_credits_button=%CreditsDialog.get_node("%CloseCreditsButton")
	credits_button.pressed.connect(show_credits)
	close_credits_button.pressed.connect(hide_credits)
	has_progress=GameState.clicks>0 or GameState.lifetime>0
	new_button.visible=has_progress
	start_button.pressed.connect(start_game)
	new_button.pressed.connect(show_confirmation)
	sound_button.pressed.connect(toggle_sound)
	language_button.pressed.connect(toggle_language)
	cancel_button.pressed.connect(hide_confirmation)
	restart_button.pressed.connect(new_game)
	for button in [start_button,new_button,sound_button,language_button,cancel_button,restart_button,credits_button,close_credits_button]:
		Motion.bind_button(button)
	preview_area.resized.connect(layout_preview)
	layout_preview()
	refresh_text()
	resized.connect(layout_modals)
	layout_modals()
	Motion.reveal(self,0.24)

func _process(delta: float) -> void:
	# Only decorative artwork moves; menu controls keep stable hit areas.
	if GameState.reduced_motion:
		title.scale=Vector2.ONE
		title.rotation=0.0
		return
	menu_time+=delta
	title.pivot_offset=title.size/2
	title.scale=Vector2.ONE*(1.0+sin(menu_time*1.1)*0.012)
	title.rotation=sin(menu_time*0.65)*0.006

func show_credits() -> void:
	confirm_new.hide()
	layout_modals()
	confirm_shade.show()
	credits_dialog.show()
	credits_dialog.z_as_relative=false
	credits_dialog.z_index=30
	credits_body.scroll_to_line(0)
	Motion.reveal(credits_dialog,0.18)
	close_credits_button.grab_focus()

func layout_modals() -> void:
	if credits_dialog==null: return
	# Use the actual viewport on first open as well as after a window resize.
	credits_dialog.set_anchors_preset(Control.PRESET_CENTER)
	credits_dialog.size=Vector2(minf(350,size.x-32),minf(540,size.y-32))
	credits_dialog.position=(credits_dialog.get_parent().size-credits_dialog.size)/2

func hide_credits() -> void:
	credits_dialog.hide()
	confirm_shade.hide()
	credits_button.grab_focus()

func layout_preview() -> void:
	preview.fit_into(Rect2(Vector2.ZERO,preview_area.size))

func start_game() -> void:
	GameState.paused=false
	start_button.disabled=true
	get_tree().call_deferred("change_scene_to_file","res://scenes/main.tscn")

func new_game() -> void:
	GameState.reset_game()
	start_game()

func update_sound_label() -> void:
	ButtonIcons.apply(sound_button,"sound_on" if GameState.sound_enabled else "sound_off",tr("声音：开" if GameState.sound_enabled else "声音：关"))

func toggle_sound() -> void:
	GameState.sound_enabled=not GameState.sound_enabled
	GameState.save_game()
	update_sound_label()

func format_number(value: float) -> String:
	if value>=1000000: return "%.2fM" % (value/1000000)
	if value>=10000: return "%.1fk" % (value/1000)
	return str(int(value))

func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST,NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		GameState.save_game()

func show_confirmation() -> void:
	confirm_shade.show()
	confirm_new.show()
	Motion.reveal(confirm_new,0.18)
	Motion.reveal(confirm_shade,0.16)
	cancel_button.grab_focus()

func hide_confirmation() -> void:
	confirm_shade.hide()
	confirm_new.hide()
	new_button.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE and (confirm_new.visible or credits_dialog.visible):
		if credits_dialog.visible: hide_credits()
		else: hide_confirmation()
		get_viewport().set_input_as_handled()

func refresh_text() -> void:
	theme.default_font=UITheme.font_for_locale()
	theme.set_font("font","TooltipLabel",theme.default_font)
	translate_children(self)
	credits_body.text=tr(CREDITS_TEXT)
	start_button.text=tr("继续栽培" if has_progress else "开始栽培")
	save_info.text=tr("累计生长 %s") % format_number(GameState.lifetime)
	ButtonIcons.apply(language_button,"language","简体中文" if GameState.language=="ja" else "日本語","中文" if GameState.language=="ja" else "日本語")
	ButtonIcons.apply(new_button,"restart",tr("重新开始"),tr("重新开始"))
	start_button.icon=ArtCatalog.texture("res://assets/ui/icons/play.svg")
	start_button.expand_icon=true
	start_button.icon_alignment=HORIZONTAL_ALIGNMENT_LEFT
	start_button.tooltip_text=start_button.text
	update_sound_label()

func translate_children(parent: Node) -> void:
	for child in parent.get_children():
		if child.has_meta("i18n_source"):
			child.text=tr(str(child.get_meta("i18n_source")))
		translate_children(child)

func toggle_language() -> void:
	GameState.set_language("zh_CN" if GameState.language=="ja" else "ja")
	refresh_text()
	Motion.reveal(save_info,0.15)
