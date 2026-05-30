require "rails_helper"

RSpec.describe Users::OnboardingService do
  let(:user) { create(:user) }

  subject(:service) { described_class.new(user) }

  context "when empty planets exist" do
    before { create_list(:planet, 3) }

    it "assigns a planet to the user" do
      planet = service.call
      expect(planet.user).to eq(user)
    end

    it "sets planet_type to player" do
      planet = service.call
      expect(planet.planet_type).to eq("player")
    end

    it "sets is_home to true" do
      planet = service.call
      expect(planet.is_home).to be true
    end

    it "sets initial metal_stock" do
      planet = service.call
      expect(planet.metal_stock.to_f).to eq(Users::OnboardingService::STARTING_RESOURCES[:metal_stock].to_f)
    end

    it "sets initial food_stock" do
      planet = service.call
      expect(planet.food_stock.to_f).to eq(Users::OnboardingService::STARTING_RESOURCES[:food_stock].to_f)
    end

    it "sets initial thorium_stock" do
      planet = service.call
      expect(planet.thorium_stock.to_f).to eq(Users::OnboardingService::STARTING_RESOURCES[:thorium_stock].to_f)
    end

    it "creates no buildings on the planet" do
      planet = service.call
      expect(planet.buildings.count).to eq(0)
    end

    it "sets resources_updated_at to now" do
      planet = service.call
      expect(planet.resources_updated_at).to be_within(5.seconds).of(Time.current)
    end
  end

  context "when no empty planets are available" do
    it "raises an error" do
      expect { service.call }.to raise_error(RuntimeError, /No empty planet available/)
    end
  end

  context "when planets are already assigned to users" do
    before do
      other_user = create(:user)
      create(:planet, :player, user: other_user)
    end

    it "raises an error if no unassigned planets remain" do
      expect { service.call }.to raise_error(RuntimeError, /No empty planet available/)
    end
  end
end
