extends Control

const UITheme = preload("res://scripts/ui_theme.gd")
var sheet: PanelContainer
var body: RichTextLabel
var plain_text: String=""
var close_button: Button

func _ready() -> void:
	name="ItemDetails"
	z_index=18
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade=ColorRect.new()
	shade.color=Color(0.09,0.07,0.045,0.30)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed: queue_free())
	add_child(shade)
	sheet=PanelContainer.new()
	sheet.theme=UITheme.create()
	var paper=UITheme.asset_style("panel_dialog")
	paper.content_margin_left=16
	paper.content_margin_right=16
	paper.content_margin_top=12
	paper.content_margin_bottom=16
	sheet.add_theme_stylebox_override("panel",paper)
	add_child(sheet)
	var column=VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	sheet.add_child(column)
	var header=HBoxContainer.new()
	column.add_child(header)
	var title=Label.new()
	title.text=tr("道具说明")
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",14)
	title.add_theme_color_override("font_color",Color("716e5b"))
	header.add_child(title)
	close_button=Button.new()
	close_button.icon=preload("res://assets/ui/icons/close.svg")
	close_button.expand_icon=true
	close_button.add_theme_constant_override("icon_max_width",22)
	close_button.tooltip_text=tr("关闭")
	close_button.set_meta("action_label",tr("关闭"))
	close_button.custom_minimum_size=Vector2(44,44)
	for state in ["normal","hover","pressed","disabled","focus"]:
		close_button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	close_button.add_theme_color_override("icon_hover_color",Color("8a6c43"))
	close_button.add_theme_color_override("icon_focus_color",Color("8a6c43"))
	close_button.pressed.connect(queue_free)
	header.add_child(close_button)
	var scroll=ScrollContainer.new()
	scroll.name="DetailsScroll"
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var track=StyleBoxFlat.new()
	track.bg_color=Color(0.50,0.56,0.43,0.10)
	var thumb=StyleBoxFlat.new()
	thumb.bg_color=Color("9ca78c")
	thumb.content_margin_left=3
	thumb.content_margin_right=3
	for corner in ["top_left","top_right","bottom_left","bottom_right"]: thumb.set("corner_radius_"+corner,2)
	var scrollbar=scroll.get_v_scroll_bar()
	scrollbar.add_theme_stylebox_override("scroll",track)
	for state in ["grabber","grabber_highlight","grabber_pressed"]: scrollbar.add_theme_stylebox_override(state,thumb)
	body=RichTextLabel.new()
	preload("res://scripts/help_typography.gd").configure(body)
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("normal_font_size",16)
	scroll.add_child(body)
	resized.connect(layout_sheet)
	body.minimum_size_changed.connect(func(): layout_sheet.call_deferred())

func present(text: String, flavor: String = "") -> void:
	plain_text=text
	body.text=preload("res://scripts/help_typography.gd").rich_text(text,flavor)
	layout_sheet()
	layout_sheet.call_deferred()
	close_button.grab_focus()

func layout_sheet() -> void:
	if body==null: return
	var width: float=minf(336,size.x-32)
	var font: Font=body.get_theme_font("normal_font")
	var text_height: float=font.get_multiline_string_size(plain_text,HORIZONTAL_ALIGNMENT_LEFT,width-48,16).y
	var lines: float=text_height/maxf(1,font.get_height(16))
	var desired: float=text_height+lines*4+100
	if body.size.x>100 and body.get_content_height()>0:
		desired=body.get_content_height()+92
	var height: float=minf(size.y-32,minf(520,desired))
	sheet.size=Vector2(width,maxf(180,height))
	sheet.position=(size-sheet.size)*0.5

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if GameState.paused: queue_free()
