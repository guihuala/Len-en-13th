extends Control

const ButtonIcons = preload("res://scripts/button_icons.gd")
const ArtCatalog = preload("res://scripts/art_catalog.gd")
const ShopItem = preload("res://scenes/ui/shop_item.tscn")
const ShopPresentation = preload("res://scripts/shop_presentation.gd")
const UITheme = preload("res://scripts/ui_theme.gd")
const Motion = preload("res://scripts/motion.gd")
const StoryVisual = preload("res://scripts/story_visual.gd")
const ACTION_TONES = ["water", "fertilize", "care", "guide", "prune", "direct", "coordinate"]
const INK = Color("25292c")
const MUTED = Color("475148")
const PAPER = Color("f4f5ef")
const RED = Color("9b424b")
const PORTRAITS = {
	"tsubakura":preload("res://assets/art/regions/characters__tsubakura.tres"),
	"yabusame":preload("res://assets/art/regions/characters__yabusame.tres"),
	"tabinoki":preload("res://assets/art/regions/tree__mini_tabinoki.tres")
}
const FIRST_PURCHASE_FEEDBACK = {
  "watering_can": "旅之木：「为什么要特意写这个？」",
  "drip_irrigation": "哦哦，会自己浇水！那我去休息一下～。有事叫另一个我。",
  "ink_fertilizer": "旅之木：「这个问号是什么？」",
  "cutting": "新小苗：「こんの木ー」",
  "dimension_box": "本人数量：2；身份确认：0。",
  "harujion": "系统：「实验成功。」\n旅之木：「实验是什么？」",
  "factory": "新建文件夹：「下次一定」。",
  "root_support": "树根挪开了。又伸回来了。",
  "pollination": "旅之木：「真的没剪刀吗？」",
  "seed_bank": "こんの木ー",
  "greenhouse": "薮雨：「那边也长出来了！」",
  "pruning": "木？",
  "grove": "第三条：竹笋除外。",
  "planet_core": "结束直播。"
}
var story_visual: Control
var audience: Control
var growth_props: Control
var screen_feedback: Node
var purchase_feedback: PanelContainer
var purchase_visual_remaining: float = 0
var tree: Control
var value_label: Label
var rate_label: Label
var stage_label: Label
var current_hint: String=""
var hint_label: Label
var speech_bubble: Panel
var progress: ProgressBar
var progress_label: Label
var shop_buttons: Dictionary = {}
var compact_system_dialog: bool = false
var dialog: Panel
var dialog_title: Label
var dialog_speaker: Label
var dialog_body: Label
var current_event: Dictionary = {}
var dialog_index: int = 0
var debug_panel: Panel
var sound: AudioStreamPlayer
var refresh_timer: float = 0
var purchase_quip: String = ""
var purchase_quip_remaining: float = 0
var ui: Dictionary = {}
var cards: Dictionary = {}
var unlocked_before: Dictionary = {}
var card_labels: Dictionary = {}
var shop_list: VBoxContainer
var shop_selector: OptionButton
var selected_shop_stage: int = -1
var shop_collapsed: bool = false
var expanded_shop_top: float = -292.0
var expanded_plant_bottom: float = -292.0
var last_shop_stage: int = -1
var shop_dragged: Dictionary = {}
var shop_press_origin: Dictionary = {}
var shop_card_height: float = 92
var modal_shade: ColorRect
var portrait_slot: Control
var portrait_image: TextureRect
var portrait_rest_position: Vector2
var portrait_tween: Tween
var displayed_portrait: String = ""
var tree_area: Control
var displayed_stage: int = -1
var displayed_ending: bool = false
var layout_left: float = 0
var layout_width: float = 390
var shop_top: float = 0
var tutorial: Control
var buy_to_milestone: bool = false
var tones: Dictionary = {
	"water": preload("res://assets/audio/water.wav"),
	"fertilize": preload("res://assets/audio/fertilize.wav"),
	"care": preload("res://assets/audio/care.wav"),
	"guide": preload("res://assets/audio/guide.wav"),
	"prune": preload("res://assets/audio/prune.wav"),
	"direct": preload("res://assets/audio/direct.wav"),
	"coordinate": preload("res://assets/audio/coordinate.wav"),
	"buy": preload("res://assets/audio/buy.wav"),
	"dialog": preload("res://assets/audio/dialog.wav")
}

func _ready() -> void:
	GameState.paused=false
	bind_scene_nodes()
	theme.default_font=UITheme.font_for_locale()
	theme.set_font("font","TooltipLabel",theme.default_font)
	value_label.add_theme_font_override("font",UITheme.data_font())
	rate_label.add_theme_font_override("font",UITheme.data_font())
	GameState.changed.connect(refresh)
	tree_area.resized.connect(layout_tree)
	resized.connect(layout_ui)
	layout_ui()
	refresh()
	Motion.reveal(self,0.22)

# Layout and styles are authored in scenes/ui/*.tscn; main.tscn composes them.
# Resolve unique names through each scene root because instances own their children.
func bind_scene_nodes() -> void:
	ui={
		"plant_panel":%PlantPanel, "studio_view":%PlantPanel.get_node("%StudioView"),
		"camera_header":%PlantPanel.get_node("%CameraHeader"), "camera_footer":%PlantPanel.get_node("%CameraFooter"),
		"shop_panel":%ShopPanel, "menu":%MenuButton, "stats":%Stats,
		"stat_growth":%Stats.get_node("%GrowthCaption"), "stat_rate":%Stats.get_node("%RateCaption"),
		"buy_mode":%ShopPanel.get_node("%BuyModeButton"), "shop_selector":%ShopPanel.get_node("%ShopStageSelector"),
		"shop_toggle":%ShopPanel.get_node("%ShopToggle"),
		"dialog_rail":$ModalLayer.get_node("%DialogRail"),
	}
	tree=%PlantPanel.get_node("%TreeView")
	tree_area=%PlantPanel.get_node("%TreeArea")
	value_label=%Stats.get_node("%GrowthValue")
	rate_label=%Stats.get_node("%RateValue")
	stage_label=%PlantPanel.get_node("%StageLabel")
	hint_label=%PlantPanel.get_node("%HintLabel")
	speech_bubble=%PlantPanel.get_node("%SpeechBubble")
	progress=%PlantPanel.get_node("%GrowthProgress")
	progress_label=%PlantPanel.get_node("%ProgressLabel")
	dialog=$ModalLayer.get_node("%Dialog")
	dialog_title=$ModalLayer.get_node("%DialogTitle")
	dialog_speaker=$ModalLayer.get_node("%DialogSpeaker")
	dialog_body=$ModalLayer.get_node("%DialogBody")
	debug_panel=%DebugPanel
	sound=%Sound
	modal_shade=$ModalLayer.get_node("%ModalShade")
	portrait_slot=$ModalLayer.get_node("%PortraitSlot")
	portrait_image=$ModalLayer.get_node("%PortraitImage")
	portrait_rest_position=portrait_image.position
	tutorial=%Tutorial
	story_visual=StoryVisual.new()
	dialog.get_node("Content").add_child(story_visual)
	dialog.get_node("Content").move_child(story_visual,1)
	growth_props=tree_area.get_node("GrowthProps")
	audience=growth_props.audience
	ui.burst=growth_props.tonic
	purchase_feedback=preload("res://scenes/ui/purchase_feedback.tscn").instantiate()
	ui.plant_panel.add_child(purchase_feedback)
	screen_feedback=$ScreenFeedback
	shop_list=%ShopPanel.get_node("%ShopList")
	ui.menu.pressed.connect(open_menu)
	tree.watered.connect(water)
	ui.burst.pressed.connect(activate_burst)
	ui.buy_mode.pressed.connect(toggle_buy_mode)
	ui.shop_toggle.pressed.connect(toggle_shop)
	expanded_shop_top=ui.shop_panel.offset_top
	expanded_plant_bottom=ui.plant_panel.offset_bottom
	dialog.gui_input.connect(_on_dialog_gui_input)
	ButtonIcons.apply(ui.menu,"menu",tr("菜单"))
	shop_selector=ui.shop_selector
	for i in range(GameState.THRESHOLDS.size()):
		shop_selector.add_item(tr(str(GameState.balance.stage_tabs[i])),i)
	shop_selector.item_selected.connect(select_shop_stage)
	shop_selector.get_popup().add_theme_font_size_override("font_size",UITheme.TYPE_BODY)
	shop_selector.get_popup().add_theme_constant_override("v_separation",24)
	shop_selector.get_popup().add_theme_stylebox_override("panel",UITheme.asset_style("panel_paper"))
	shop_selector.get_popup().add_theme_color_override("font_color",UITheme.text_color(INK))
	for item in GameState.upgrades:
		var id: String=item.id
		var card: Panel=ShopItem.instantiate()
		card.name=id
		card.visible=false
		shop_list.add_child(card)
		var buy: Button=card.get_node("Purchase/BuyButton")
		cards[id]=card
		card_labels[id]={"title":card.get_node("Title"),"tag":card.get_node("Effect"),"icon":card.get_node("Icon"),"price":card.get_node("Price")}
		shop_buttons[id]=buy
		card_labels[id].title.add_theme_font_override("font",UITheme.emphasis_font())
		card_labels[id].title.add_theme_color_override("font_color",Color("344b30"))
		card_labels[id].tag.add_theme_color_override("font_color",Color("526747"))
		card_labels[id].tag.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		card_labels[id].price.add_theme_font_size_override("font_size",12)
		card_labels[id].price.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		var payback_label: Label=card.get_node("Purchase/Payback")
		card_labels[id].payback=payback_label
		card_labels[id].icon.texture=ArtCatalog.texture(str(item.icon))
		var info_button: Button=card.get_node("Icon/ItemHelp")
		info_button.tooltip_text=tr("查看道具说明")
		info_button.set_meta("action_label",info_button.tooltip_text)
		info_button.pressed.connect(show_item_details.bind(id))
		var badge: Label=info_button.get_node("Badge")
		info_button.mouse_entered.connect(func(): badge.add_theme_color_override("font_color",Color("8a603a")))
		info_button.mouse_exited.connect(func(): badge.add_theme_color_override("font_color",Color("455b36")))
		info_button.focus_entered.connect(func(): badge.add_theme_color_override("font_color",Color("8a603a")))
		info_button.focus_exited.connect(func(): badge.add_theme_color_override("font_color",Color("455b36")))
		card.tooltip_text=tr(str(item.note))
		buy.pressed.connect(purchase_from_card.bind(id))
		buy.gui_input.connect(track_shop_gesture.bind(id))
		buy.mouse_exited.connect(cancel_shop_drag.bind(id))
	var actions=[func(): GameState.add_growth(200),func(): GameState.add_growth(2000),func(): GameState.add_growth(maxf(0,GameState.THRESHOLDS[3]-GameState.lifetime)),func(): GameState.add_growth(float(GameState.balance.ending_lifetime)),replay_events,toggle_debug]
	for i in range(actions.size()):
		debug_panel.get_node("Action%d" % (i+1)).pressed.connect(actions[i])
	bind_button_feedback(self)
	tutorial.setup(self)

func bind_button_feedback(parent: Node) -> void:
	for child in parent.get_children():
		if child is Button: Motion.bind_button(child)
		bind_button_feedback(child)

func layout_ui() -> void:
	if ui.is_empty(): return
	layout_width=$Interface.size.x
	layout_left=$Interface.position.x
	ui.burst.visible=GameState.burst_unlocked()
	layout_tree()
	if tutorial!=null: tutorial.refresh()
	if dialog!=null and dialog.visible: layout_dialog.call_deferred()

func layout_dialog() -> void:
	if dialog_body==null: return
	var content: VBoxContainer=dialog.get_node("Content")
	var padding: float=24 if compact_system_dialog else 20
	dialog_body.custom_minimum_size=Vector2.ZERO
	content.offset_top=padding
	content.offset_bottom=-padding
	dialog_body.size.x=dialog.size.x-content.offset_left+content.offset_right
	var height: float=dialog_body.get_minimum_size().y+padding*2
	var separation: int=content.get_theme_constant("separation")
	if dialog_speaker.get_parent().visible:
		height+=dialog_speaker.get_parent().get_combined_minimum_size().y+separation
	if story_visual!=null and story_visual.visible:
		height+=story_visual.get_combined_minimum_size().y+separation
	dialog.offset_top=dialog.offset_bottom-maxf(76,ceilf(height))

func set_portrait(key: String, animate: bool = true) -> void:
	if not PORTRAITS.has(key): key=""
	var changed: bool=key!=displayed_portrait
	displayed_portrait=key
	if changed:
		if portrait_tween!=null and portrait_tween.is_valid(): portrait_tween.kill()
		portrait_image.position=portrait_rest_position
		portrait_image.modulate.a=1
	portrait_slot.visible=not key.is_empty()
	portrait_image.texture=PORTRAITS.get(key) if not key.is_empty() else null
	layout_dialog()
	if changed and not key.is_empty() and animate and not GameState.reduced_motion:
		portrait_image.position.x=portrait_rest_position.x-12
		portrait_image.modulate.a=0
		portrait_tween=create_tween().set_parallel(true)
		portrait_tween.tween_property(portrait_image,"position:x",portrait_rest_position.x,0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		portrait_tween.tween_property(portrait_image,"modulate:a",1.0,0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func layout_tree() -> void:
	if tree==null: return
	# Reserve two lines and the hand-drawn bubble tail, even between remarks.
	var top: float=speech_bubble.reserved_height()
	tree.fit_into(Rect2(Vector2(0,top),Vector2(tree_area.size.x,maxf(1,tree_area.size.y-top))))
	displayed_stage=GameState.stage
	displayed_ending="ending" in GameState.triggered

func open_menu() -> void:
	GameState.save_game()
	GameState.paused=true
	ui.menu.disabled=true
	get_tree().call_deferred("change_scene_to_file","res://scenes/mainmenu.tscn")

func fmt(n: float) -> String:
	if n>=1000000: return "%.2fM" % (n/1000000)
	if n>=10000: return "%.1fk" % (n/1000)
	return str(int(n)) if is_equal_approx(n,floor(n)) else "%.1f" % n

func refresh() -> void:
	if value_label == null: return
	var previous_hint: String=current_hint
	if ui.burst.visible!=GameState.burst_unlocked(): layout_ui()
	var stage_changed: bool=last_shop_stage!=GameState.stage
	if stage_changed:
		speech_bubble.dismiss()
		purchase_quip_remaining=0
		ui.studio_view.update_stage()
		last_shop_stage=GameState.stage
		selected_shop_stage=GameState.stage
		update_shop_view()
	value_label.text=fmt(GameState.growth)
	rate_label.text=fmt(GameState.per_second())
	ui.stat_rate.text=(tr("临时×3·%ss") % int(ceil(GameState.burst_remaining))) if GameState.burst_remaining>0 else tr("每秒增长")
	if displayed_stage!=GameState.stage or displayed_ending!=("ending" in GameState.triggered): layout_tree()
	stage_label.text=tr(GameState.balance.stage_names[GameState.stage])
	var next_label: Label=%PlantPanel.get_node("%NextStageLabel")
	if "ending" in GameState.triggered:
		next_label.text=tr("栽培结束。仍可继续栽培。")
	elif GameState.stage<GameState.THRESHOLDS.size()-1:
		next_label.text=tr("下一阶段：%s") % tr(str(GameState.balance.stage_names[GameState.stage+1]))
	else:
		next_label.text=tr("下一目标：栽培结束")
	audience.visible="nursery" in GameState.triggered or int(GameState.counts.get("seed_bank",0))>0
	growth_props.refresh()
	var phrases: Array=GameState.balance.stage_hints
	current_hint=tr(phrases[GameState.stage] if GameState.clicks>=3 else "浇点水。")
	if GameState.stage==1:
		if tree.current_variant==1: current_hint=tr("「帽子长出来了。……还挺快。」")
		elif tree.current_variant==2: current_hint=tr("「哦！帽子！……先长这个啊？！」")
	if purchase_quip_remaining>0 and GameState.clicks>=3:
		current_hint=tr(purchase_quip)
	elif GameState.burst_remaining>0:
		current_hint=tr("加速中 · 还剩 %s 秒") % str(int(ceil(GameState.burst_remaining)))
	if current_hint!=previous_hint and speech_bubble.visible and not stage_changed:
		speech_bubble.replace_text(current_hint)
	ui.buy_mode.text=tr("凑整") if buy_to_milestone else tr("购买 ×1")
	ui.buy_mode.tooltip_text=tr("凑整") if not buy_to_milestone else "×1"
	var target: float=float(GameState.balance.ending_lifetime) if GameState.stage==GameState.THRESHOLDS.size()-1 else GameState.THRESHOLDS[GameState.stage+1]
	progress.max_value=target
	progress.value=GameState.lifetime
	progress_label.text=tr("累计 %s / %s") % [fmt(GameState.lifetime),fmt(target)]
	if "ending" in GameState.triggered: progress_label.text=tr("累计 %s") % fmt(GameState.lifetime)
	for u in GameState.upgrades:
		var b: Button=shop_buttons[u.id]
		var owned: int=int(GameState.counts.get(u.id,0))
		var bought: bool=not u.repeat and owned>0
		var full: bool=GameState.at_capacity(u)
		var locked: bool=not GameState.unlocked(u)
		var quantity: int=GameState.purchase_quantity(u,buy_to_milestone)
		var cost: int=GameState.quantity_price(u,quantity)
		var can_afford: bool=GameState.growth>=cost
		card_labels[u.id].title.text=tr(str(u.name))
		var state_text: String=tr("已购买" if bought else ("已满" if full else ("等待剧情" if locked else ("不足" if not can_afford else "购买"))))
		var next: int=GameState.next_production_milestone(u)
		var details: String=tr("持有 %d") % owned if u.repeat else tr("一次性")
		if next>0: details=tr("%d 组 · %d 组翻倍") % [owned,next]
		var effect: String=tr(str(u.tag))
		if float(u.click)>0: effect=tr("点击 +%s") % fmt(GameState.tool_click_gain(u))
		elif float(u.rate)>0:
			effect=tr("自动 +%s/秒") % fmt(GameState.next_rate_gain(u,quantity))
		elif u.id=="harujion": effect=tr("全部产量 ×2")
		elif u.id=="planet_core": effect=tr("结束直播")
		if float(u.get("click_share",0))>0:
			details=tr("联动自动 %s%%") % str(int(round(float(u.click_share)*100)))
		if GameState.burst_remaining>0 and (float(u.click)>0 or float(u.rate)>0):
			effect="×3 · "+effect
		var status_label: Label=card_labels[u.id].payback
		status_label.visible=not locked and not bought and not full and (float(u.rate)>0 or not can_afford)
		if status_label.visible:
			status_label.text=(tr("还差 %s") % fmt(ceil(maxf(0,cost-GameState.growth)))) if not can_afford else (tr("回本 %ss") % fmt(ceil(GameState.payback_seconds(u,quantity))))
			status_label.add_theme_color_override("font_color",Color("79503a") if not can_afford else UITheme.text_color(MUTED))
		card_labels[u.id].tag.text=effect
		var inventory_details: String=details
		if locked and not bought and not full:
			details=ShopPresentation.unlock_hint(u,fmt(float(GameState.balance.ending_lifetime)))
		card_labels[u.id].price.text=details
		card_labels[u.id].price.add_theme_color_override("font_color",Color("65694f"))
		b.icon=ArtCatalog.texture("res://assets/art/regions/ui__icons__lock.tres") if locked and not bought and not full else null
		b.add_theme_constant_override("icon_max_width",18)
		b.add_theme_constant_override("h_separation",4)
		b.text=state_text if bought or full or locked else tr("购买" if can_afford else "生长值不足")+"\n"+fmt(cost)
		if locked and u.id=="planet_core" and str(u.get("requires_event","")) in GameState.triggered: b.text=tr("目标\n未达成")
		if not bought and not full and not locked and can_afford and quantity>1: b.text=("×%d\n" % quantity)+fmt(cost)
		if buy_to_milestone and u.repeat and not locked and not full:
			b.text="×%d\n" % quantity + (tr("合计 %s") if can_afford else tr("不足 %s")) % fmt(cost)
		b.tooltip_text=state_text+" · "+tr(str(u.name))+"\n"+(tr("%s 生长值") % fmt(cost))+"\n"+tr(str(u.note))
		if float(u.get("click_share",0))>0:
			b.tooltip_text+="\n"+(tr("每次操作额外获得 %s 基础收益和 %s%% 的自动产量。") % [fmt(float(u.click)*GameState.multiplier()*GameState.burst_multiplier()),str(int(round(float(u.click_share)*100)))])
		elif float(u.rate)>0:
			var total_rate: float=float(u.rate)*owned*GameState.production_multiplier(u)*GameState.multiplier()*GameState.burst_multiplier()
			b.tooltip_text+="\n"+(tr("当前合计 %s/秒；本次增加 %s/秒。") % [fmt(total_rate),fmt(GameState.next_rate_gain(u,quantity))])
			if next>0:
				b.tooltip_text+="\n"+(tr("再买 %d 组，本设施总产量翻倍。") % (next-owned))
		elif u.id=="harujion":
			b.tooltip_text+="\n"+tr("固定点击收益和自动产量同时翻倍，与生长药剂叠加。")
		if buy_to_milestone and u.repeat and not locked and not full:
			b.tooltip_text+="\n"+(tr("本次购买 %d 组 · 合计 %s 生长值") % [quantity,fmt(cost)])
			if next>0:
				var needed: float=maxf(0,GameState.quantity_price(u,next-owned)-GameState.growth)
				b.tooltip_text+="\n"+(tr("达到 %d 组翻倍还差 %s 生长值。") % [next,fmt(ceil(needed))])
		if float(u.rate)>0:
			b.tooltip_text+="\n"+(tr("常态自动回本约 %s 秒；每次购买涨价 %s%%。") % [fmt(ceil(GameState.payback_seconds(u,quantity))),str(int(round((float(u.get("price_growth",GameState.balance.price_growth))-1)*100)))])
			b.tooltip_text+="\n"+tr("仅按常态自动产量估算，不含手动操作和临时加速。")
		if GameState.burst_remaining>0 and (float(u.click)>0 or float(u.rate)>0):
			b.tooltip_text+="\n"+tr("当前收益含临时 ×3，药剂结束后恢复常态。")
			var normal_gain: float=(GameState.tool_click_gain(u) if float(u.click)>0 else GameState.next_rate_gain(u,quantity))/GameState.burst_multiplier()
			b.tooltip_text+="\n"+((tr("常态每次操作 +%s") if float(u.click)>0 else tr("常态自动 +%s/秒")) % fmt(normal_gain))
		if locked and not bought and not full:
			b.tooltip_text+="\n"+ShopPresentation.unlock_hint(u,fmt(float(GameState.balance.ending_lifetime)),true)
		elif not can_afford and not bought and not full:
			b.tooltip_text+="\n"+status_label.text+"\n"+inventory_details
		cards[u.id].tooltip_text=b.tooltip_text
		b.set_meta("action_label",b.tooltip_text)
		var icon: TextureRect=card_labels[u.id].icon
		icon.modulate.a=0.72 if locked else 1.0
		if unlocked_before.get(u.id,true)==false and not locked and cards[u.id].visible:
			Motion.pulse_icon(icon)
		unlocked_before[u.id]=not locked
		b.disabled=GameState.paused or locked or bought or full or not can_afford
		var purchase_state: String="complete" if bought or full else ("locked" if locked else ("short" if not can_afford else "ready"))
		ShopPresentation.apply(b,purchase_state,buy_to_milestone and bool(u.repeat) and not locked and not full)
	refresh_milestone_tabs()
	if stage_changed and GameState.pending.is_empty() and not GameState.paused: speech_bubble.say(current_hint,5.0)
	if tutorial!=null: tutorial.refresh()

func refresh_milestone_tabs() -> void:
	for index in range(shop_selector.item_count):
		var doubling: bool=false
		if index<=GameState.stage:
			for item in GameState.shop_items(index):
				var next: int=GameState.next_production_milestone(item)
				var quantity: int=GameState.purchase_quantity(item,buy_to_milestone)
				if next>0 and int(GameState.counts.get(item.id,0))+quantity>=next and GameState.unlocked(item) and GameState.growth>=GameState.quantity_price(item,quantity):
					doubling=true
		shop_selector.set_item_text(index,tr(GameState.balance.stage_tabs[index])+(" ×2" if doubling else ""))
	shop_selector.text=shop_selector.get_item_text(selected_shop_stage)
	ui.shop_toggle.set_collapsed(shop_collapsed)
	ui.shop_toggle.tooltip_text=tr("展开道具栏" if shop_collapsed else "收起道具栏")
	ui.shop_toggle.set_meta("action_label",ui.shop_toggle.tooltip_text)

func toggle_shop() -> void:
	set_shop_collapsed(not shop_collapsed)

func set_shop_collapsed(collapsed: bool) -> void:
	shop_collapsed=collapsed
	ui.shop_panel.add_theme_stylebox_override("panel",UITheme.asset_style("plain" if collapsed else "panel_drawer"))
	ui.shop_panel.offset_top=-64.0 if collapsed else expanded_shop_top
	ui.plant_panel.offset_bottom=-64.0 if collapsed else expanded_plant_bottom
	shop_selector.visible=not collapsed
	ui.buy_mode.visible=not collapsed
	shop_list.visible=not collapsed
	ui.shop_toggle.anchor_left=1.0
	ui.shop_toggle.anchor_right=ui.shop_toggle.anchor_left
	ui.shop_toggle.offset_left=-60.0
	ui.shop_toggle.offset_right=-16.0
	ui.shop_toggle.offset_top=8.0
	ui.shop_toggle.offset_bottom=52.0
	shop_selector.get_popup().hide()
	refresh_milestone_tabs()
	layout_ui()

func toggle_buy_mode() -> void:
	buy_to_milestone=not buy_to_milestone
	refresh()

func activate_burst() -> void:
	if GameState.activate_burst():
		Motion.pulse_icon(rate_label)
		speech_bubble.say(tr("临时加速 ×3"))
		tree.splash()
		play_tone("buy")
		refresh()
		if purchase_quip_remaining>0: speech_bubble.say(current_hint,5.0)

func _process(delta: float) -> void:
	if not GameState.paused:
		purchase_quip_remaining=maxf(0,purchase_quip_remaining-delta)
	if purchase_visual_remaining>0:
		purchase_visual_remaining=maxf(0,purchase_visual_remaining-delta)
		if purchase_visual_remaining<=0 and current_event.get("id","").begins_with("purchase_"):
			advance_dialog()
	refresh_timer+=delta
	if refresh_timer>0.1:
		refresh_timer=0
		refresh()
	if current_event.is_empty() and not GameState.pending.is_empty():
		var id: String=GameState.pending.front()
		for event in GameState.events:
			if event.id==id:
				current_event=event
				dialog_index=0
				GameState.paused=true
				speech_bubble.dismiss()
				debug_panel.hide()
				show_line()
				break

func water() -> void:
	var action_stage: int=GameState.stage
	var amount: float=GameState.water()
	if amount<=0: return
	tree.splash(action_stage)
	screen_feedback.trigger()
	if GameState.clicks<3 or GameState.clicks%6==0: speech_bubble.say(current_hint)
	play_tone(ACTION_TONES[action_stage])
	var floating=preload("res://scenes/ui/floating_number.tscn").instantiate()
	floating.text="+"+fmt(amount)
	floating.position=tree.get_feedback_position()+Vector2(randf_range(-16,16),0)
	add_child(floating)
	floating.z_index=10
	var tween=create_tween().set_parallel(true)
	if not GameState.reduced_motion: tween.tween_property(floating,"position:y",floating.position.y-65,0.8)
	tween.tween_property(floating,"modulate:a",0.0,0.8)
	tween.chain().tween_callback(floating.queue_free)

func purchase(id: String) -> void:
	var item: Dictionary={}
	for upgrade in GameState.upgrades:
		if upgrade.id==id:
			item=upgrade
			break
	if item.is_empty(): return
	var quantity: int=GameState.purchase_quantity(item,buy_to_milestone)
	var previous: int=int(GameState.counts.get(id,0))
	var before_rate: float=GameState.per_second()
	var before_click: float=GameState.per_click()
	if GameState.buy(id,quantity):
		var result: String=""
		if not is_equal_approx(before_rate,GameState.per_second()):
			result=tr("总产量 %s → %s/秒") % [fmt(before_rate),fmt(GameState.per_second())]
		if not is_equal_approx(before_click,GameState.per_click()):
			if not result.is_empty(): result+="\n"
			result+=tr("每次操作 %s → %s") % [fmt(before_click),fmt(GameState.per_click())]
		if previous==0:
			purchase_quip=tr(str(FIRST_PURCHASE_FEEDBACK.get(id,item.note))).split("\n")[0]
			purchase_quip_remaining=5
			if id in ["dimension_box","factory","seed_bank","grove","harujion"]:
				show_purchase_visual(id)
		for milestone in GameState.balance.get("production_milestones",[]):
			if float(item.rate)>0 and previous<int(milestone) and int(GameState.counts.get(id,0))>=int(milestone):
				purchase_quip=tr("%s · %d 组达成，产量 ×2！") % [tr(str(item.name)),int(milestone)]
				purchase_quip_remaining=5
				result=(tr("%d 组达成 · 本设施 ×2") % int(milestone))+"\n"+(tr("总产量 %s → %s/秒") % [fmt(before_rate),fmt(GameState.per_second())])
		if not result.is_empty():
			if GameState.burst_remaining>0: result=tr("含临时×3 · %s") % result
			purchase_feedback.present(result)
		Motion.pulse_icon(card_labels[id].icon)
		play_tone("buy")
		refresh()
		if purchase_quip_remaining>0: speech_bubble.say(current_hint,5.0)

func show_purchase_visual(id: String) -> void:
	if not current_event.is_empty(): return
	current_event={"id":"purchase_"+id,"title":tr("旅ノ木憲法（栽培用・临时）") if id=="grove" else tr("首次购买"),"speaker":tr("系统"),"lines":[tr("本游戏原创的栽培规则。") if id=="grove" else tr(str(FIRST_PURCHASE_FEEDBACK[id]))]}
	dialog_index=0
	GameState.paused=true
	# A brief computer frame is enough; the constitution remains until dismissed.
	purchase_visual_remaining=1.4 if id=="factory" else 0.0
	show_line()

func show_line() -> void:
	var opening: bool=not dialog.visible
	var speakers: Array=current_event.get("speakers",[])
	var speaker: Dictionary=speakers[dialog_index] if dialog_index<speakers.size() else {"name":current_event.speaker,"portrait":""}
	set_portrait(str(speaker.get("portrait","")))
	var speaker_name: String=str(speaker.get("name",current_event.speaker))
	var system_line: bool=speaker_name in ["系统",tr("系统")]
	compact_system_dialog=system_line
	dialog_speaker.text="" if system_line else tr(speaker_name)
	dialog_speaker.get_parent().visible=not system_line
	dialog_body.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER if system_line else HORIZONTAL_ALIGNMENT_LEFT
	dialog_body.vertical_alignment=VERTICAL_ALIGNMENT_CENTER if system_line else VERTICAL_ALIGNMENT_TOP
	dialog.show()
	modal_shade.show()
	if opening:
		Motion.reveal(dialog,0.2)
		Motion.reveal(modal_shade,0.16)
	else:
		Motion.reveal(dialog_body,0.12)
	dialog_title.text=""
	dialog_title.hide()
	ui.dialog_rail.hide()
	dialog_body.text=tr(str(current_event.lines[dialog_index]))
	story_visual.present(str(current_event.id),dialog_index)
	story_visual.visible=not system_line or str(current_event.id).begins_with("purchase_")
	layout_dialog()
	layout_dialog.call_deferred()
	refresh()
	dialog.grab_focus()
	play_tone("dialog")

func _on_dialog_gui_input(event: InputEvent) -> void:
	if current_event.is_empty(): return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		dialog.accept_event()
		advance_dialog()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:
		dialog.accept_event()
		advance_dialog()

func advance_dialog() -> void:
	if current_event.is_empty(): return
	dialog_index+=1
	if dialog_index < current_event.lines.size():
		show_line()
		return
	if not str(current_event.id).begins_with("purchase_") and current_event.id not in GameState.triggered:
		GameState.triggered.append(current_event.id)
	GameState.pending.erase(current_event.id)
	current_event={}
	purchase_visual_remaining=0
	dialog.hide()
	set_portrait("",false)
	modal_shade.hide()
	GameState.paused=false
	GameState.save_game()
	refresh()
	tree.grab_focus()

func save_now() -> void:
	GameState.save_game()

func reset() -> void:
	purchase_feedback.dismiss()
	purchase_quip_remaining=0
	current_event={}
	purchase_visual_remaining=0
	dialog.hide()
	set_portrait("",false)
	modal_shade.hide()
	GameState.reset_game()
	refresh()

func toggle_debug() -> void:
	if OS.is_debug_build(): debug_panel.visible=not debug_panel.visible

func replay_events() -> void:
	if not current_event.is_empty(): return
	for id in GameState.triggered:
		if id not in GameState.pending: GameState.pending.append(id)
	debug_panel.hide()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode==KEY_ESCAPE and current_event.is_empty():
		open_menu()
		return
	if event.keycode==KEY_F1: toggle_debug()
	if event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE] and not current_event.is_empty():
		advance_dialog()
		get_viewport().set_input_as_handled()
	elif event.keycode==KEY_SPACE and current_event.is_empty():
		water()
		get_viewport().set_input_as_handled()

func play_tone(id: String) -> void:
	if sound==null or not GameState.sound_enabled: return
	sound.stream=tones[id]
	sound.play()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST,NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		save_now()

func select_shop_stage(value: int) -> void:
	if value>GameState.stage or value<0: return
	selected_shop_stage=value
	update_shop_view()
	refresh()
	Motion.reveal(shop_list,0.14)

func update_shop_view() -> void:
	for i in range(shop_selector.item_count):
		shop_selector.set_item_disabled(i,i>GameState.stage)
	shop_selector.select(selected_shop_stage)
	for item in GameState.upgrades:
		cards[item.id].visible=int(item.get("shop_stage",0))==selected_shop_stage
	refresh_milestone_tabs()

func visible_shop_ids() -> Array:
	var result: Array=[]
	for item in GameState.upgrades:
		if cards[item.id].visible: result.append(item.id)
	return result

func track_shop_gesture(event: InputEvent, id: String) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		shop_press_origin[id]=event.position
		shop_dragged[id]=false
	elif event is InputEventScreenTouch and event.pressed:
		shop_press_origin[id]=event.position
		shop_dragged[id]=false
	elif event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_LEFT:
		if event.position.distance_to(shop_press_origin.get(id,event.position))>12: shop_dragged[id]=true
	elif event is InputEventScreenDrag:
		if event.position.distance_to(shop_press_origin.get(id,event.position))>12: shop_dragged[id]=true

func cancel_shop_drag(id: String) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): shop_dragged[id]=true

func purchase_from_card(id: String) -> void:
	if not shop_dragged.get(id,false): purchase(id)

func show_item_details(id: String) -> void:
	if GameState.paused: return
	speech_bubble.dismiss()
	var previous=get_node_or_null("ItemDetails")
	if previous!=null:
		remove_child(previous)
		previous.queue_free()
	var details=preload("res://scripts/item_details.gd").new()
	add_child(details)
	var item: Dictionary=GameState.upgrades.filter(func(entry): return entry.id==id)[0]
	details.present(shop_buttons[id].tooltip_text,tr(str(item.note)))
