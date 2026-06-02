GRID_SIZE = ENV.fetch("GALAXY_GRID_SIZE", 20).to_i

PLANET_NAME_PREFIXES = %w[Alpha Beta Gamma Delta Epsilon Zeta Eta Theta Iota Kappa
                           Lambda Mu Nu Xi Omicron Pi Rho Sigma Tau Upsilon].freeze
PLANET_NAME_SUFFIXES = %w[Prime Secundus Tertius Major Minor Caelum Novus Aether Solara Nexis
                           Vega Arcturus Sirius Altair Rigel Deneb Castor Pollux Aldebaran Fomalhaut].freeze

def generate_planet_name(x, y)
  prefix = PLANET_NAME_PREFIXES[x % PLANET_NAME_PREFIXES.size]
  suffix = PLANET_NAME_SUFFIXES[y % PLANET_NAME_SUFFIXES.size]
  "#{prefix} #{suffix}"
end

puts "Seeding galaxy grid (#{GRID_SIZE}x#{GRID_SIZE} = #{GRID_SIZE ** 2} planets)..."

now = Time.current

(0...GRID_SIZE).each do |x|
  (0...GRID_SIZE).each do |y|
    Planet.find_or_create_by!(coord_x: x, coord_y: y) do |p|
      p.name                 = generate_planet_name(x, y)
      p.planet_type          = "empty"
      p.visual_type          = Planet::VISUAL_TYPES[(x + y) % Planet::VISUAL_TYPES.size]
      p.is_home              = false
      p.resources_updated_at = now
    end
  end
end

puts "Done - #{Planet.count} planets in galaxy."

puts "Creating Users..."

user = User.create(
  username: "Root",
  email_address: "user@example.com",
  password: "Password1!",
  password_confirmation: "Password1!"
)
Users::OnboardingService.new(user).call

puts "Done - #{User.count} users in galaxy."