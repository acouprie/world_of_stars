module GameSpeed
  # Multiply resource production and divide construction/training durations by this factor.
  # Set GAME_SPEED=60 at launch to run the game 60x faster (dev/testing only).
  MULTIPLIER = ENV.fetch("GAME_SPEED", "1").to_f.clamp(1.0, Float::INFINITY)
end
