extends RefCounted

static var cache: Dictionary = {}

# Use silhouette bounds only for foreground copies; keep the painting grid intact.
static func fitted(source: Texture2D) -> Texture2D:
	var key: int=source.get_instance_id()
	if cache.has(key): return cache[key]
	var image: Image=source.get_image()
	if image==null: return source
	var bounds: Rect2i=image.get_used_rect()
	if not bounds.has_area(): return source
	var view=AtlasTexture.new()
	view.atlas=source
	view.region=Rect2(bounds)
	view.filter_clip=true
	cache[key]=view
	return view
