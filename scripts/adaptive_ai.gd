extends RefCounted
## Offline contextual multi-armed bandit with online incremental reward updates.
var values := [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]
var visits := [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]]
var rng := RandomNumberGenerator.new()

func _init() -> void:
 rng.randomize()

func context(traffic: int, speed: float) -> int:
 return int(traffic >= 2) + 2 * int(speed > 0.65)

func choose(ctx: int) -> int:
 if rng.randf() < 0.18:
  return rng.randi_range(0, 2)
 var winner: int = 0
 var best: float = -9999.0
 var total: int = visits[ctx][0] + visits[ctx][1] + visits[ctx][2]
 for action in range(3):
  var confidence: float = 0.4 * sqrt(log(float(total + 2)) / float(visits[ctx][action] + 1))
  var value: float = values[ctx][action] + confidence
  if value > best:
   best = value
   winner = action
 return winner

func learn(ctx: int, action: int, reward: float) -> void:
 visits[ctx][action] += 1
 var n: float = float(visits[ctx][action])
 values[ctx][action] += (clampf(reward, -1.0, 1.0) - values[ctx][action]) / n
