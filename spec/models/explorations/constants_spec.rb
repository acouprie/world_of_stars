require "rails_helper"

RSpec.describe "Explorations constants" do
  it "defines EXPLORATION_LEVEL_BASE as 400" do
    expect(Explorations::EXPLORATION_LEVEL_BASE).to eq(400)
  end

  it "defines EXPLORATION_LEVEL_FACTOR as 1.7" do
    expect(Explorations::EXPLORATION_LEVEL_FACTOR).to eq(1.7)
  end

  it "defines EXPLORATION_GAIN_PER_LEVEL as 1.0292" do
    expect(Explorations::EXPLORATION_GAIN_PER_LEVEL).to eq(1.0292)
  end

  it "defines MAX_SIMULTANEOUS_EXPLORATIONS as 5" do
    expect(Explorations::MAX_SIMULTANEOUS_EXPLORATIONS).to eq(5)
  end
end
