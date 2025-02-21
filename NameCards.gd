extends Node2D

@onready var portrait = $PilotImage
@onready var name_tag = $Name
var placeholder = preload("res://pilot_images/placeholder.jpg")

# convert currently spectating to a UID and hex color to modulate the text

var image_dict = {
5271: preload("res://pilot_images/adk.jpg"),
93660: preload("res://pilot_images/ap3x.jpg"),
223886: preload("res://pilot_images/arvin.jpg"),
15641: preload("res://pilot_images/batu.jpg"),
283618: preload("res://pilot_images/blastaa.jpg"),
156744: preload("res://pilot_images/chirp.jpg"),
228140: preload("res://pilot_images/claybrain.jpg"),
54623: preload("res://pilot_images/coolwhip.jpg"),
116790: preload("res://pilot_images/cubed.jpg"),
60177: preload("res://pilot_images/din.jpg"),
209284: preload("res://pilot_images/febykris.jpg"),
135966: preload("res://pilot_images/finz.jpg"),
281903: preload("res://pilot_images/flyingpizza.jpg"),
333909: preload("res://pilot_images/flyrat.jpg"),
160627: preload("res://pilot_images/freedomduck.jpg"),
99033: preload("res://pilot_images/gman.jpg"),
165597: preload("res://pilot_images/gman.jpg"),
211123: preload("res://pilot_images/gomufas.jpg"),
25369: preload("res://pilot_images/goodvibes.jpg"),
221662: preload("res://pilot_images/iwandi.jpg"),
176509: preload("res://pilot_images/jamus.jpg"),
252638: preload("res://pilot_images/jazzmutant.jpg"),
175416: preload("res://pilot_images/jey.jpg"),
24379: preload("res://pilot_images/kuzy.jpg"),
325640: preload("res://pilot_images/lukey.jpg"),
298568: preload("res://pilot_images/luv4god.jpg"),
46774: preload("res://pilot_images/magfly.jpg"),
191696: preload("res://pilot_images/martyd.jpg"),
196105: preload("res://pilot_images/mattyo.jpg"),
83988: preload("res://pilot_images/monsterduke.jpg"),
44483: preload("res://pilot_images/morbid.jpg"),
81646: preload("res://pilot_images/nateyt.jpg"),
279816: preload("res://pilot_images/nemuo.jpg"),
133667: preload("res://pilot_images/nzm.jpg"),
261882: preload("res://pilot_images/platonair.jpg"),
278662: preload("res://pilot_images/poison.jpg"),
196003: preload("res://pilot_images/proximo.jpg"),
40865: preload("res://pilot_images/ramon.jpg"),
197083: preload("res://pilot_images/razbri.jpg"),
59672: preload("res://pilot_images/red5.jpg"),
257585: preload("res://pilot_images/redsky.jpg"),
118763: preload("res://pilot_images/rofl.jpg"),
172696: preload("res://pilot_images/sabj.jpg"),
208147: preload("res://pilot_images/salie1.jpg"),
6437: preload("res://pilot_images/sfpv.jpg"),
285657: preload("res://pilot_images/shturman.jpg"),
185222: preload("res://pilot_images/sloth.jpg"),
352046: preload("res://pilot_images/spooky.jpg"),
221974: preload("res://pilot_images/statik.jpg"),
317985: preload("res://pilot_images/suzrik.jpg"),
188094: preload("res://pilot_images/taxoo.jpg"),
74205: preload("res://pilot_images/valprim.jpg"),
86118: preload("res://pilot_images/wikiwix.jpg"),
266417: preload("res://pilot_images/zebra.jpg")
}

var current_id = 0000

var current_name = "None"

func update_portrait(user_id):
	if user_id != current_id:
		if int(user_id) in image_dict:
			portrait.texture = image_dict[int(user_id)]
		else:
			portrait.texture = placeholder
		print(user_id)
		current_id = user_id


func update_nametag(name, color, uid):
	if name != current_name:
		if int(uid) in image_dict:
			var filename = get_pilot_name(uid)
			current_name = filename
			name_tag.text = filename
			name_tag.modulate = color
		else:
			name_tag.text = name
			name_tag.modulate = color
			current_name = name
	

func get_pilot_name(uid):
	if int(uid) in image_dict:
		var full_path: String = image_dict[int(uid)].resource_path
		var path_no_ext = full_path.get_basename()
		var file_no_ext = path_no_ext.get_file()
		return file_no_ext
	else:
		return ""  # or some fallback
	
