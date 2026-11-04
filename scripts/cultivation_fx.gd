extends Node2D

# Later cultivation actions use their own geometry and motion, rather than water.
const COLORS = [Color("77b5ca"),Color("b89a59"),Color("91b866"),Color("b2ce79"),Color("dae6aa"),Color("e3c37b"),Color("e8da92")]
const MAX_PULSES = 6
const MAX_PARTICLES = 144
var pulses: Array = []
var particles: Array = []

func emit_action(stage: int, origin: Vector2, extent: Vector2) -> void:
	if GameState.reduced_motion: return
	var unit: float=clampf(minf(extent.x,extent.y)/280.0,0.7,1.35)
	var center: Vector2=Vector2(extent.x*0.5,extent.y*0.80) if stage in [1,3] else origin
	if stage==6: center=extent*Vector2(0.5,0.52)
	pulses.append({"stage":stage,"p":center,"age":0.0,"unit":unit,"radius":minf(extent.x,extent.y)*0.34})
	if pulses.size()>MAX_PULSES: pulses.pop_front()
	if stage in [1,2,4]:
		for i in range(18):
			var point: Vector2=center
			var velocity: Vector2
			var gravity: float=0
			if stage==1:
				point+=Vector2(randf_range(-44,44),randf_range(-82,-48))*unit
				velocity=Vector2(randf_range(-9,9),randf_range(50,85))*unit
				gravity=85*unit
			elif stage==2:
				point+=Vector2(randf_range(-60,60),randf_range(-10,28))*unit
				velocity=Vector2(randf_range(-24,24),randf_range(-65,-32))*unit
			else:
				point+=Vector2(randf_range(-26,26),randf_range(-18,18))*unit
				velocity=Vector2(randf_range(-100,100),randf_range(-100,-40))*unit
				gravity=230*unit
			particles.append({"stage":stage,"p":point,"v":velocity,"gravity":gravity,"age":0.0,"spin":randf_range(-3,3),"angle":randf_range(-PI,PI),"unit":unit,"duration":randf_range(0.65,0.9),"size":randf_range(0.7,1.15)})
	if particles.size()>MAX_PARTICLES: particles=particles.slice(particles.size()-MAX_PARTICLES)
	queue_redraw()

func clear_effects() -> void:
	pulses.clear()
	particles.clear()
	queue_redraw()

func advance(delta: float) -> void:
	if GameState.reduced_motion:
		clear_effects()
		return
	for pulse in pulses: pulse.age+=delta
	pulses=pulses.filter(func(p): return p.age<1.0)
	for particle in particles:
		particle.age+=delta
		particle.p+=particle.v*delta+Vector2(0,0.5*float(particle.gravity)*delta*delta)
		particle.v.y+=particle.gravity*delta
		particle.angle+=particle.spin*delta
	particles=particles.filter(func(p): return p.age<p.duration)
	queue_redraw()

func leaf(point: Vector2, radius: float, color: Color, angle: float) -> void:
	draw_set_transform(point,angle)
	var outline: PackedVector2Array=[]
	for i in range(17):
		var t: float=float(i)/16.0
		outline.append(Vector2(lerpf(-radius,radius,t),-sin(t*PI)*radius*0.48))
	for i in range(1,16):
		var t: float=float(i)/16.0
		outline.append(Vector2(lerpf(radius,-radius,t),sin(t*PI)*radius*0.34))
	draw_colored_polygon(outline,color)
	draw_line(Vector2(-radius*0.7,0),Vector2(radius*0.7,0),color.darkened(0.28),1,true)
	draw_set_transform(Vector2.ZERO)

func path_between(start: Vector2, end: Vector2, bend: float) -> PackedVector2Array:
	var points: PackedVector2Array=[]
	for i in range(17):
		var t: float=float(i)/16
		points.append(start.lerp(end,t)+Vector2(sin(t*PI)*bend,0))
	return points

func growing_path(points: PackedVector2Array, progress: float, color: Color, width: float) -> void:
	var count: int=clampi(int(progress*(points.size()-1))+1,2,points.size())
	draw_polyline(points.slice(0,count),color,width,true)

func _draw() -> void:
	for pulse in pulses:
		var stage: int=pulse.stage
		var t: float=pulse.age
		var unit: float=pulse.unit
		var origin: Vector2=pulse.p
		var color: Color=COLORS[stage]
		color.a=minf(t/0.06,1.0)*minf((1.0-t)/0.30,1.0)
		match stage:
			1:
				# Nutrients soak into the soil; the short shoots visibly absorb them.
				for i in range(3):
					var point: Vector2=origin+Vector2((i-1)*27,0)*unit
					draw_set_transform(point,0,Vector2(1,0.35))
					draw_arc(Vector2.ZERO,(8+t*20)*unit,0,TAU,32,color,2*unit,true)
					draw_set_transform(Vector2.ZERO)
					draw_line(point,point+Vector2(0,-18*minf(t*3,1))*unit,color,2*unit,true)
			2:
				# Three growing stems and paired leaves make care distinct from rain.
				for i in range(3):
					var base: Vector2=origin+Vector2((i-1)*43,24)*unit
					var tip: Vector2=base+Vector2((i-1)*7,-42*minf(t*4,1))*unit
					draw_line(base,tip,color,2*unit,true)
					leaf(tip+Vector2(-5,-1)*unit,8*unit,color,-0.5)
					leaf(tip+Vector2(5,-5)*unit,8*unit,color,0.5)
			3:
				# Branching root routes carry visible beads towards new growth.
				for i in range(3):
					var end: Vector2=origin+Vector2((i-1)*67,-(48+22*(i%2)))*unit
					var route: PackedVector2Array=path_between(origin,end,(i-1)*15*unit)
					growing_path(route,minf(t*3,1),color.darkened(0.2),3*unit)
					var bead: Vector2=route[mini(16,int(fmod(t*1.8+i*0.18,1.0)*17))]
					draw_circle(bead,4*unit,color)
					draw_line(end,end+Vector2(-5,11)*unit,color,2*unit,true)
					draw_line(end,end+Vector2(6,9)*unit,color,2*unit,true)
			4:
				# Two blades close, followed by falling, rotating leaf cuttings.
				if t<0.5:
					var opening: float=lerpf(0.65,0.08,minf(t*6,1))
					for side in [-1,1]:
						var angle: float=-0.65+side*opening
						var direction: Vector2=Vector2.from_angle(angle)
						draw_line(origin-direction*14*unit,origin+direction*43*unit,color,3*unit,true)
						draw_arc(origin-direction*22*unit,7*unit,0,TAU,20,color,2*unit,true)
					if t>0.13: draw_line(origin+Vector2(-32,29)*unit,origin+Vector2(40,-35)*unit,Color(1,0.98,0.8,color.a*(1-t*1.8)),2*unit,true)
			5:
				# An appraisal eye scans, then sends orders to three target plots.
				var scan: float=minf(t*5,1)
				draw_set_transform(origin,0,Vector2(1,0.5))
				draw_arc(Vector2.ZERO,22*unit,0,TAU,40,color,2*unit,true)
				draw_set_transform(Vector2.ZERO)
				draw_circle(origin,5*unit,color)
				for i in range(3):
					var end: Vector2=origin+Vector2.from_angle(-PI*0.85+i*PI*0.35)*70*unit
					var point: Vector2=origin.lerp(end,scan)
					draw_line(origin,point,color,1.5*unit,true)
					draw_arc(end,9*unit,-PI*0.5,TAU*minf(t*2,1)-PI*0.5,24,color,2*unit,true)
					if t>0.35:
						draw_polyline(PackedVector2Array([end+Vector2(-5,0)*unit,end+Vector2(-1,4)*unit,end+Vector2(6,-5)*unit]),color,2*unit,true)
			6:
				# A planet-wide circuit synchronizes six districts, with packets in transit.
				var radius: float=pulse.radius
				var nodes: PackedVector2Array=[]
				for i in range(6): nodes.append(origin+Vector2.from_angle(-PI*0.5+i*TAU/6)*radius*Vector2(1,0.75))
				for i in range(6):
					var point: Vector2=nodes[i]
					var end: Vector2=nodes[(i+1)%6]
					var route_color: Color=Color(color,color.a*0.65)
					draw_line(point,end,route_color,1.5*unit,true)
					draw_line(origin,point,route_color,1*unit,true)
					draw_circle(point,5*unit,color)
					draw_arc(point,(8+fmod(t*2+i*0.12,1)*9)*unit,0,TAU,24,route_color,1.5*unit,true)
					draw_circle(point.lerp(end,fmod(t*1.7,1)),3*unit,color)
				draw_arc(origin,(10+t*17)*unit,0,TAU,32,color,2*unit,true)
	for particle in particles:
		var color: Color=COLORS[particle.stage]
		color.a=minf(float(particle.age)/0.045,1.0)*clampf((float(particle.duration)-float(particle.age))/0.25,0,1)
		var unit: float=float(particle.unit)*float(particle.size)
		if particle.stage==1:
			draw_circle(particle.p,2.4*unit,color)
			draw_circle(particle.p+Vector2(-0.8,-0.8),0.8*unit,Color(0.98,0.94,0.75,color.a))
		else:
			leaf(particle.p,(5 if particle.stage==2 else 8)*unit,color,particle.angle)
