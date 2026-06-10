require 'faker'

GRID_SIZE = ENV.fetch("GALAXY_GRID_SIZE", 20).to_i

# Syllabes d'ouverture (consonnes initiales)
NAME_OPENING = %w[
  Ar Vel Xor Thal Aer Vor Zel Kor Eth Myr
  Dra Sol Fen Ith Lyr Nar Phe Ral Sev Tor
  Ux Vyr Wex Yar Zeph Cal Del Esh Far Gal
  Hev Jor Kel Lev Mex Nev Orl Pax Qel Riv
].freeze

# Racines médiales
NAME_MIDDLE = %w[
  an ath or ix el ur em yn ar eth
  ion ael orn yx ith on ax yr en al
  os eus im av ior eon ull ath enn ex
].freeze

# Suffixes finaux (peuvent être vides)
NAME_CLOSING = (
  %w[is us ia on ar ix eon ara ith orm
     ax yn el or em ath ion ael yx en] + ['', '', '']
).freeze

# Constants for toroidal placement
MIN_DISTANCE = 3  # distance euclidienne toroïdale minimale entre deux planètes
COORD_MAX = 100
MAX_ATTEMPTS = 500  # tentatives max par planète avant abandon

def toric_distance(x1, y1, x2, y2, grid: COORD_MAX)
  dx = (x1 - x2).abs
  dy = (y1 - y2).abs
  dx = grid - dx if dx > grid / 2.0
  dy = grid - dy if dy > grid / 2.0
  Math.sqrt(dx**2 + dy**2)
end

def find_valid_position(placed, rng)
  MAX_ATTEMPTS.times do
    x = rng.rand(COORD_MAX)
    y = rng.rand(COORD_MAX)
    next if placed.any? { |px, py| toric_distance(x, y, px, py) < MIN_DISTANCE }
    return [x, y]
  end
  nil  # abandon si pas de position valide trouvée
end

def generate_planet_name(index, rng)
  opening = NAME_OPENING[index % NAME_OPENING.size]
  middle  = NAME_MIDDLE[(index * 7 + 13) % NAME_MIDDLE.size]
  closing = NAME_CLOSING[(index * 11 + 5) % NAME_CLOSING.size]
  "#{opening}#{middle}#{closing}".strip
end

puts "Seeding galaxy grid (#{GRID_SIZE}x#{GRID_SIZE} = #{GRID_SIZE ** 2} planets)..."

now = Time.current
rng = Random.new(42)
placed = []

(0...GRID_SIZE).each do |x|
  (0...GRID_SIZE).each do |y|
    index = x * GRID_SIZE + y
    pos = find_valid_position(placed, rng)

    if pos.nil?
      puts "Warning: Could not find valid position for planet #{index}"
      next
    end

    coord_x, coord_y = pos
    placed << [coord_x, coord_y]

    Planet.find_or_create_by!(coord_x: coord_x, coord_y: coord_y) do |p|
      name = generate_planet_name(index, rng)
      # Handle name collisions
      existing_names = Planet.where(name: name).count
      if existing_names > 0
        suffix = ["II", "III", "IV", "V", "VI", "VII"][existing_names - 1] || "#{existing_names + 1}"
        name = "#{name} #{suffix}"
      end

      p.name                 = name
      p.planet_type          = "empty"
      p.biome                = Planet::BIOMES[(coord_x + coord_y) % Planet::BIOMES.size]
      p.is_home              = false
      p.resources_updated_at = now
    end
  end
end

puts "Done - #{Planet.count} planets in galaxy."

puts "Creating Users..."

NB_USERS = 100

user = User.create(
  username: "Root",
  email_address: "user@example.com",
  password: "Password1!",
  password_confirmation: "Password1!"
)
Users::OnboardingService.new(user).call

NB_USERS.times do |i|
  user = User.create(
    username: Faker::Internet.username(specifier: "root_#{i + 1}"),
    email_address: Faker::Internet.email(name: "user_#{i + 1}"),
    password: "Password1!",
    password_confirmation: "Password1!"
  )
  Users::OnboardingService.new(user).call
end

puts "Done - #{User.count} users in galaxy."