class_name SaveModule
extends BalloonModule
## ════════════════════════════════════════════════════════════════
## SaveModule — 对话进度跟踪模块
## ════════════════════════════════════════════════════════════════
##
## 每行只更新 NarrativeSlotModule 的内存快照；落盘由显式 SaveSystem.save_slot()
## 或项目自己的周期 autosave 负责。
## ════════════════════════════════════════════════════════════════

@export_group("存档设置")
## 是否跟踪对话进度（只写内存）
@export var track_dialogue_progress: bool = true
## 存档章节名（显示在存档槽中）
@export var chapter_name: String = ""

# ════════════════════════════════════════════════════════════════
# 内部状态
# ════════════════════════════════════════════════════════════════

var _current_resource: DialogueResource = null
var _current_cue: String = ""

# ════════════════════════════════════════════════════════════════
# BalloonModule 接口
# ════════════════════════════════════════════════════════════════

# Returns the module identifier used by ModularBalloon.
func get_module_name() -> String:
	return "save"

# Captures the active dialogue resource and starting cue.
func on_dialogue_started(resource: DialogueResource, cue: String) -> void:
	_current_resource = resource
	_current_cue = cue

# Tracks each line in memory without writing a save file.
func on_dialogue_line_changed(line: DialogueLine) -> void:
	if not track_dialogue_progress:
		return
	_track_progress(line)

# Clears the transient dialogue context when the balloon ends.
func on_dialogue_ended() -> void:
	_current_resource = null
	_current_cue = ""

# ════════════════════════════════════════════════════════════════
# 内部方法
# ════════════════════════════════════════════════════════════════

## Updates the registered slot module; this function deliberately never writes disk.
func _track_progress(line: DialogueLine) -> void:
	var sys := get_node_or_null("/root/SaveSystem")
	if sys == null:
		return
	if not sys.has_method("get_module"):
		return
	
	var module = sys.get_module("narrative_slot")
	if module == null:
		return
	if not module.has_method("record_dialogue_progress"):
		return
	
	module.call("record_dialogue_progress",
		_current_resource,
		line.id,
		_current_cue,
		chapter_name,
		line.character,
		line.text
	)
