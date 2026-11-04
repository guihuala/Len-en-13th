extends Node

signal changed
const SaveManager = preload("res://scripts/save_manager.gd")
var balance: Dictionary = {}
var THRESHOLDS: Array = []
var EVENT_IDS: Array = []
var upgrades: Array = []
var events: Array = []
var growth: float = 0
var lifetime: float = 0
var clicks: int = 0
var counts: Dictionary = {}
var triggered: Array = []
var pending: Array = []
var stage: int = 0
var paused: bool = false
var elapsed: float = 0
var save_clock: float = 0
var saved_ok: bool = true
var sound_enabled: bool = true
var language: String = "zh_CN"
var reduced_motion: bool = false
var tutorial_done: bool = false
var burst_charge: float = 0
var burst_remaining: float = 0
var stage_floor: int = 0

func _ready() -> void:
	balance = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
	THRESHOLDS = balance.thresholds
	EVENT_IDS = balance.event_ids
	upgrades = JSON.parse_string(FileAccess.get_file_as_string("res://data/upgrades.json"))
	events = JSON.parse_string(FileAccess.get_file_as_string("res://data/events.json"))
	if OS.has_feature("web"):
		reduced_motion=bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches",true))
	load_game()

func _process(delta: float) -> void:
	if not paused:
		elapsed += maxf(delta,0)
		var remaining: float=maxf(delta,0)
		while remaining>0:
			# Split at buff expiry so a slow frame never earns extra boosted time.
			var slice: float=minf(remaining,burst_remaining) if burst_remaining>0 else remaining
			var produced: float=per_second()*slice
			if burst_unlocked(): burst_charge=minf(float(balance.burst.cooldown),burst_charge+slice)
			burst_remaining=maxf(0,burst_remaining-slice)
			remaining=maxf(0,remaining-slice)
			if produced>0: add_growth(produced)
	save_clock += delta
	if save_clock >= 30:
		save_game()

func multiplier() -> float:
	return 2.0 if counts.get("harujion", 0) > 0 else 1.0

func base_per_click() -> float:
	var value: float = 1 + float(balance.stage_click_bonus[stage])
	for u in upgrades:
		value += float(u.click) * int(counts.get(u.id, 0))
	return value * multiplier() * burst_multiplier()

func click_passive_share() -> float:
	# Tools add independent shares, so purchase order cannot change their value.
	var share: float=float(balance.get("click_passive_share",1.0))
	for u in upgrades:
		share+=float(u.get("click_share",0))*int(counts.get(u.id,0))
	return share

func per_click() -> float:
	# The live rate already includes global and burst bonuses; never multiply twice.
	return base_per_click() + per_second()*click_passive_share()

func tool_click_gain(u: Dictionary) -> float:
	return float(u.click)*multiplier()*burst_multiplier()+per_second()*float(u.get("click_share",0))

func action_name() -> String:
	return str(balance.stage_actions[stage])

func production_multiplier(u: Dictionary, quantity: int = -1) -> float:
	if float(u.rate)<=0: return 1
	var owned: int=int(counts.get(u.id,0)) if quantity<0 else quantity
	var result: float=1
	for milestone in balance.get("production_milestones",[]):
		if owned>=int(milestone): result*=2
	return result

func next_production_milestone(u: Dictionary) -> int:
	if float(u.rate)<=0: return 0
	for milestone in balance.get("production_milestones",[]):
		if int(counts.get(u.id,0))<int(milestone): return int(milestone)
	return 0

func next_rate_gain(u: Dictionary, quantity: int = 1) -> float:
	var owned: int=int(counts.get(u.id,0))
	var delta: float=float(u.rate)*((owned+quantity)*production_multiplier(u,owned+quantity)-owned*production_multiplier(u,owned))
	return delta*multiplier()*burst_multiplier()

func raw_passive() -> float:
	var value: float = 0
	for u in upgrades:
		value += float(u.rate) * int(counts.get(u.id, 0)) * production_multiplier(u)
	return value

func per_second() -> float:
	return raw_passive()*multiplier()*burst_multiplier()

func burst_multiplier() -> float:
	return float(balance.burst.multiplier) if burst_remaining>0 and balance.has("burst") else 1.0

func burst_unlocked() -> bool:
	return balance.has("burst") and int(counts.get("drip_irrigation",0))>0 and "sprout" in triggered

func burst_ready() -> bool:
	return burst_unlocked() and burst_remaining<=0 and burst_charge>=float(balance.burst.cooldown)-0.00001

func activate_burst() -> bool:
	if paused or not burst_ready(): return false
	burst_charge=0
	burst_remaining=float(balance.burst.duration)
	save_game()
	changed.emit()
	return true

func price(u: Dictionary, offset: int = 0) -> int:
	return int(ceil(float(u.price) * pow(float(u.get("price_growth",balance.price_growth)), int(counts.get(u.id, 0))+offset)))

func payback_seconds(u: Dictionary, quantity: int = 1) -> float:
	# Compare permanent automatic output only; temporary boosts must not sway investment.
	var gain: float=next_rate_gain(u,quantity)/burst_multiplier()
	return float(quantity_price(u,quantity))/gain if gain>0 else INF

func quantity_price(u: Dictionary, quantity: int = 1) -> int:
	var total: int=0
	for offset in range(quantity): total+=price(u,offset)
	return total

func purchase_quantity(u: Dictionary, to_milestone: bool) -> int:
	if not to_milestone or not u.repeat: return 1
	var owned: int=int(counts.get(u.id,0))
	var goal: int=next_production_milestone(u)
	var limit: int=goal-owned if goal>0 else 10
	var total: int=0
	var quantity: int=0
	for offset in range(limit):
		var cost: int=price(u,offset)
		if total+cost>growth: break
		if int(u.get("max_owned",0))>0 and owned+quantity>=int(u.max_owned): break
		total+=cost
		quantity+=1
	return maxi(1,quantity)

func unlocked(u: Dictionary) -> bool:
	if clicks < 3 or stage<int(u.get("shop_stage",0)):
		return false
	if u.has("requires_event") and u.requires_event not in triggered:
		return false
	if u.id == "planet_core":
		return lifetime >= float(balance.ending_lifetime)
	return true

func at_capacity(u: Dictionary) -> bool:
	return int(u.get("max_owned", 0)) > 0 and int(counts.get(u.id, 0)) >= int(u.max_owned)

func buy(id: String, quantity: int = 1) -> bool:
	if paused or quantity<1 or quantity>1000:
		return false
	for u in upgrades:
		if u.id != id:
			continue
		var owned: int=int(counts.get(id,0))
		if not unlocked(u) or at_capacity(u) or (not u.repeat and (owned>0 or quantity!=1)):
			return false
		if int(u.get("max_owned",0))>0 and owned+quantity>int(u.max_owned): return false
		var cost: int=quantity_price(u,quantity)
		if growth<cost: return false
		growth -= cost
		counts[id] = owned + quantity
		if id=="drip_irrigation" and owned==0 and balance.has("burst"):
			burst_charge=float(balance.burst.cooldown)
		if id == "planet_core" and not "ending" in triggered:
			pending.append("ending")
		changed.emit()
		save_game()
		return true
	return false

func water() -> float:
	if paused:
		return 0
	clicks += 1
	var amount = per_click()
	add_growth(amount)
	return amount

func add_growth(amount: float) -> void:
	growth += maxf(amount, 0)
	lifetime += maxf(amount, 0)
	check_milestones()
	changed.emit()

func check_milestones() -> void:
	stage = 0
	for i in range(1, THRESHOLDS.size()):
		if lifetime >= THRESHOLDS[i]:
			stage = i
	stage=maxi(stage,stage_floor)
	for i in range(EVENT_IDS.size()):
		var reached: bool = clicks >= 3 if i == 0 else stage>=i
		if reached and EVENT_IDS[i] not in triggered and EVENT_IDS[i] not in pending:
			pending.append(EVENT_IDS[i])
	# Keep new records ahead of an unfinished ending in pre-expansion saves.
	var event_order: Array = EVENT_IDS + ["ending"]
	pending.sort_custom(func(a, b): return event_order.find(a) < event_order.find(b))

func save_game() -> void:
	saved_ok = SaveManager.write_save({"version":5,"growth":growth,"lifetime":lifetime,"clicks":clicks,"counts":counts,"triggered":triggered,"pending":pending,"elapsed":elapsed,"sound_enabled":sound_enabled,"language":language,"tutorial_done":tutorial_done,"burst_charge":burst_charge,"burst_remaining":burst_remaining,"stage_floor":stage_floor})
	save_clock = 0

func load_game() -> void:
	var data = SaveManager.read_save()
	growth = maxf(float(data.get("growth", 0)), 0)
	lifetime = maxf(float(data.get("lifetime", growth)), growth)
	clicks = maxi(int(data.get("clicks", 0)), 0)
	counts = data.get("counts", {})
	migrate_legacy_counts()
	# Existing players keep their progress without receiving a new mandatory tour.
	tutorial_done = bool(data.get("tutorial_done", clicks>0 or lifetime>0 or not counts.is_empty()))
	var burst: Dictionary=balance.get("burst",{})
	burst_charge=clampf(float(data.get("burst_charge",float(burst.get("cooldown",0)) if int(counts.get("drip_irrigation",0))>0 else 0)),0,float(burst.get("cooldown",0)))
	burst_remaining=clampf(float(data.get("burst_remaining",0)),0,float(burst.get("duration",0)))
	triggered = data.get("triggered", [])
	pending = data.get("pending", [])
	stage_floor=clampi(int(data.get("stage_floor",0)),0,THRESHOLDS.size()-1)
	if int(data.get("version",1))<4:
		# Raised gates must never revoke a chapter or facility the player already earned.
		for i in range(EVENT_IDS.size()):
			if EVENT_IDS[i] in triggered or EVENT_IDS[i] in pending: stage_floor=maxi(stage_floor,i)
		for item in upgrades:
			if int(counts.get(item.id,0))>0: stage_floor=maxi(stage_floor,int(item.shop_stage))
	elapsed = float(data.get("elapsed", 0))
	sound_enabled=bool(data.get("sound_enabled",true))
	language=str(data.get("language","ja" if OS.get_locale_language()=="ja" else "zh_CN"))
	if language not in ["zh_CN","ja"]: language="zh_CN"
	TranslationServer.set_locale(language)
	check_milestones()

func migrate_legacy_counts() -> void:
	# The previous final item maps to the new planetary core without losing a purchase.
	if counts.has("anniversary"):
		counts["planet_core"]=maxi(int(counts.get("planet_core",0)),int(counts["anniversary"]))
		counts.erase("anniversary")

func reset_game() -> void:
	growth = 0
	lifetime = 0
	clicks = 0
	counts.clear()
	triggered.clear()
	pending.clear()
	stage = 0
	stage_floor = 0
	elapsed = 0
	paused = false
	tutorial_done = false
	burst_charge=0
	burst_remaining=0
	save_game()
	changed.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

func set_language(value: String) -> void:
	if value not in ["zh_CN","ja"]: return
	language=value
	TranslationServer.set_locale(language)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("try { localStorage.setItem('tabinoki_language','%s'); document.documentElement.lang='%s'; } catch(e) {}" % [language,"ja" if language=="ja" else "zh-CN"],true)
	save_game()

func shop_items(for_stage: int) -> Array:
	return upgrades.filter(func(upgrade): return int(upgrade.get("shop_stage",0))==for_stage)

func finish_tutorial() -> void:
	tutorial_done = true
	save_game()
	changed.emit()
