extends Node2D
## Self-contained 2D racing game. All art and controls are drawn/generated in code.
const LANES := [180.0, 360.0, 540.0]
var rng := RandomNumberGenerator.new()
var brain = preload("res://scripts/adaptive_ai.gd").new()
var player_lane: int = 1
var speed: float = 0.55
var distance: float = 0.0
var lives: int = 3
var cars: Array[Dictionary] = []
var spawn_clock: float = 0.0
var scroll: float = 0.0
var rival_lane: int = 0
var rival_distance: float = 0.0
var rival_previous: float = 0.0
var rival_context: int = 0
var rival_action: int = 1
var ai_clock: float = 0.0
var ended: bool = false
var accelerating: bool = false
var braking: bool = false
var status: Label
var details: Label
var restart: Button

func _ready() -> void:
 rng.randomize()
 var layer := CanvasLayer.new()
 add_child(layer)
 var ui := Control.new()
 ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ui.mouse_filter = Control.MOUSE_FILTER_PASS
 layer.add_child(ui)
 status = Label.new()
 status.position = Vector2(22, 18)
 status.add_theme_font_size_override("font_size", 34)
 ui.add_child(status)
 details = Label.new()
 details.position = Vector2(22, 67)
 details.add_theme_font_size_override("font_size", 22)
 ui.add_child(details)
 var left := _button(ui, "LEFT", Vector2(20, 1100), Vector2(148, 140))
 var right := _button(ui, "RIGHT", Vector2(185, 1100), Vector2(148, 140))
 var gas := _button(ui, "GAS", Vector2(555, 1100), Vector2(145, 140))
 var brake := _button(ui, "BRAKE", Vector2(385, 1140), Vector2(145, 90))
 restart = _button(ui, "RESTART", Vector2(245, 575), Vector2(230, 90))
 left.pressed.connect(func(): _steer(-1))
 right.pressed.connect(func(): _steer(1))
 gas.button_down.connect(func(): accelerating = true)
 gas.button_up.connect(func(): accelerating = false)
 brake.button_down.connect(func(): braking = true)
 brake.button_up.connect(func(): braking = false)
 restart.pressed.connect(_reset)
 _reset()

func _button(ui: Control, title: String, pos: Vector2, dimensions: Vector2) -> Button:
 var b := Button.new()
 b.text = title
 b.position = pos
 b.size = dimensions
 b.add_theme_font_size_override("font_size", 28)
 ui.add_child(b)
 return b

func _reset() -> void:
 player_lane = 1
 speed = 0.55
 distance = 0.0
 lives = 3
 cars.clear()
 spawn_clock = 0.0
 scroll = 0.0
 rival_lane = 0
 rival_distance = 0.0
 rival_previous = 0.0
 ai_clock = 0.0
 ended = false
 accelerating = false
 braking = false
 restart.visible = false
 _hud()
 queue_redraw()

func _steer(amount: int) -> void:
 if not ended:
  player_lane = clampi(player_lane + amount, 0, 2)

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_LEFT or event.keycode == KEY_A:
   _steer(-1)
  elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
   _steer(1)
  elif event.keycode == KEY_R and ended:
   _reset()
 if event is InputEventScreenTouch and event.pressed and event.position.y < 1050.0:
  _steer(-1 if event.position.x < 360.0 else 1)

func _process(delta: float) -> void:
 if ended:
  return
 if accelerating or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
  speed = minf(1.0, speed + delta * 0.45)
 elif braking or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
  speed = maxf(0.15, speed - delta * 0.7)
 else:
  speed = move_toward(speed, 0.55, delta * 0.14)
 var velocity: float = 300.0 + speed * 550.0
 distance += velocity * delta / 65.0
 scroll = fposmod(scroll + velocity * delta, 160.0)
 spawn_clock += delta
 if spawn_clock >= maxf(0.48, 1.3 - distance / 1500.0):
  spawn_clock = 0.0
  cars.append({"lane": rng.randi_range(0, 2), "y": -100.0, "factor": rng.randf_range(0.7, 1.15), "hit": false})
 for i in range(cars.size() - 1, -1, -1):
  var car: Dictionary = cars[i]
  car["y"] = float(car["y"]) + velocity * delta * float(car["factor"])
  if absf(float(car["y"]) - 1020.0) < 80.0 and int(car["lane"]) == player_lane and not bool(car["hit"]):
   car["hit"] = true
   lives -= 1
   speed = 0.15
   if lives <= 0:
    ended = true
    restart.visible = true
  if float(car["y"]) > 1380.0:
   cars.remove_at(i)
  else:
   cars[i] = car
 ai_clock += delta
 if ai_clock > 1.3:
  ai_clock = 0.0
  var congestion: int = 0
  for car in cars:
   if float(car["y"]) < 400.0:
    congestion += 1
  brain.learn(rival_context, rival_action, clampf((rival_distance - rival_previous) / 18.0 - float(congestion) * 0.2, -1.0, 1.0))
  rival_previous = rival_distance
  rival_context = brain.context(congestion, speed)
  rival_action = brain.choose(rival_context)
  if rival_action == 0:
   rival_lane = maxi(0, rival_lane - 1)
  elif rival_action == 2:
   rival_lane = mini(2, rival_lane + 1)
 rival_distance += delta * (9.0 + float(rival_action == 1) * 2.0)
 _hud()
 queue_redraw()

func _hud() -> void:
 status.text = "NEURAL RACER   %d PTS   HP %d" % [int(distance * 3.0), lives]
 details.text = "SPEED %d%%  |  AI %dm  |  YOU %dm" % [int(speed * 100.0), int(rival_distance), int(distance)]
 if ended:
  status.text = "RACE OVER   SCORE %d" % int(distance * 3.0)

func _draw() -> void:
 draw_rect(Rect2(0, 0, 720, 1280), Color("174235"))
 draw_rect(Rect2(80, 0, 560, 1280), Color("252b40"))
 for x in [88.0, 628.0]:
  draw_rect(Rect2(x, 0, 7, 1280), Color("d2eaff"))
 for x in [270.0, 450.0]:
  for n in range(10):
   draw_rect(Rect2(x, float(n) * 160.0 + scroll - 160.0, 7, 90), Color("b9d4e4"))
 for car in cars:
  _car(Vector2(LANES[int(car["lane"])], float(car["y"])), Color("c85b5b"))
 _car(Vector2(LANES[rival_lane], 260.0), Color("9d7aff"))
 _car(Vector2(LANES[player_lane], 1020.0), Color("20e8b9"))
 if ended:
  draw_rect(Rect2(100, 450, 520, 220), Color(0.04, 0.06, 0.12, 0.85))

func _car(p: Vector2, color: Color) -> void:
 draw_rect(Rect2(p.x - 40, p.y - 72, 80, 144), color)
 draw_rect(Rect2(p.x - 29, p.y - 38, 58, 45), Color("162236"))
 draw_rect(Rect2(p.x - 48, p.y - 40, 9, 30), Color("101018"))
 draw_rect(Rect2(p.x + 39, p.y - 40, 9, 30), Color("101018"))
 draw_rect(Rect2(p.x - 48, p.y + 36, 9, 30), Color("101018"))
 draw_rect(Rect2(p.x + 39, p.y + 36, 9, 30), Color("101018"))
