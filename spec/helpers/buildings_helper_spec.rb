require "rails_helper"

RSpec.describe BuildingsHelper, type: :helper do
  describe "#building_name" do
    it "returns the translated name for a known type (string)" do
      expect(helper.building_name("command_center")).to eq(I18n.t("buildings.types.command_center"))
    end

    it "returns the translated name for a known type (symbol)" do
      expect(helper.building_name(:solar_station)).to eq(I18n.t("buildings.types.solar_station"))
    end

    it "falls back to humanize for an unknown type" do
      expect(helper.building_name("laser_cannon")).to eq("Laser cannon")
    end
  end

  describe "#format_duration" do
    it "formats seconds under a minute" do
      expect(helper.format_duration(45)).to eq("45 s")
    end

    it "formats whole minutes" do
      expect(helper.format_duration(120)).to eq("2 min")
    end

    it "formats minutes and seconds" do
      expect(helper.format_duration(90)).to eq("1 min 30 s")
    end

    it "formats whole hours" do
      expect(helper.format_duration(7200)).to eq("2 h")
    end

    it "formats hours and minutes" do
      expect(helper.format_duration(7500)).to eq("2 h 5 min")
    end
  end

  describe "#building_icon" do
    it "returns the icon for a known building type (string)" do
      expect(helper.building_icon("solar_station")).to eq("☀")
    end

    it "returns the icon for a known building type (symbol)" do
      expect(helper.building_icon(:military_camp)).to eq("✦")
    end

    it "returns '?' for an unknown type" do
      expect(helper.building_icon("laser_cannon")).to eq("?")
    end

    it "returns icons for all registered building types" do
      Buildings::REGISTRY.each_key do |type|
        expect(helper.building_icon(type)).not_to eq("?"), "Missing icon for #{type}"
      end
    end
  end

  describe "#building_category_color_class" do
    it "returns text-energy for energy buildings" do
      expect(helper.building_category_color_class("solar_station")).to eq("text-energy")
      expect(helper.building_category_color_class("nuclear_plant")).to eq("text-energy")
    end

    it "returns text-production for production buildings" do
      expect(helper.building_category_color_class("metal_mine")).to eq("text-production")
      expect(helper.building_category_color_class("farm")).to eq("text-production")
    end

    it "returns text-infra for infrastructure buildings" do
      expect(helper.building_category_color_class("command_center")).to eq("text-infra")
      expect(helper.building_category_color_class("research_lab")).to eq("text-infra")
    end

    it "returns text-orbital for orbital buildings" do
      expect(helper.building_category_color_class("radar_satellite")).to eq("text-orbital")
    end

    it "returns text-military for military buildings" do
      expect(helper.building_category_color_class("bunker")).to eq("text-military")
      expect(helper.building_category_color_class("ship_factory")).to eq("text-military")
    end

    it "returns text-storage for storage buildings" do
      expect(helper.building_category_color_class("food_silo")).to eq("text-storage")
    end

    it "falls back to text-text-muted for unknown types" do
      expect(helper.building_category_color_class("laser_cannon")).to eq("text-text-muted")
    end
  end

  describe "#building_category_badge_classes" do
    it "returns energy badge classes for energy buildings" do
      classes = helper.building_category_badge_classes("solar_station")
      expect(classes).to include("text-energy")
    end

    it "returns military badge classes for military buildings" do
      classes = helper.building_category_badge_classes("training_camp")
      expect(classes).to include("text-military")
    end

    it "returns orbital badge classes for orbital buildings" do
      classes = helper.building_category_badge_classes("radar_satellite")
      expect(classes).to include("text-orbital")
    end

    it "returns neutral classes for storage buildings" do
      classes = helper.building_category_badge_classes("food_silo")
      expect(classes).to include("text-storage")
    end

    it "falls back to neutral classes for unknown types" do
      classes = helper.building_category_badge_classes("laser_cannon")
      expect(classes).to include("text-text-muted")
    end
  end

  describe "#building_production_info" do
    subject(:info) { helper.building_production_info(building) }

    context "with an energy building" do
      let(:building) { build(:building, building_type: "solar_station", level: 1) }

      it "returns the energy output" do
        expect(info).to include("+55")
        expect(info).to include(I18n.t("resources.energy").downcase)
      end

      it "does not include '/h'" do
        expect(info).not_to include("/h")
      end
    end

    context "with a production building (metal mine)" do
      let(:building) { build(:building, building_type: "metal_mine", level: 1) }

      it "returns the production rate with '/h'" do
        expect(info).to include("+24")
        expect(info).to include(I18n.t("resources.metal").downcase)
        expect(info).to include("/h")
      end
    end

    context "with a production building (farm)" do
      let(:building) { build(:building, building_type: "farm", level: 2) }

      it "returns the production rate for the correct level" do
        expect(info).to include("+21")
        expect(info).to include(I18n.t("resources.food").downcase)
      end
    end

    context "with a storage building" do
      let(:building) { build(:building, building_type: "food_silo", level: 1) }

      it "returns the storage capacity" do
        expect(info).to include("21")
        expect(info).to include(I18n.t("resources.food").downcase)
      end

      it "does not include '/h'" do
        expect(info).not_to include("/h")
      end
    end

    context "with a bunker" do
      let(:building) { build(:building, building_type: "bunker", level: 1) }

      it "returns resources and soldiers capacity" do
        expect(info).to include("5")
        expect(info).to include("50")
      end
    end

    context "with an infrastructure building" do
      let(:building) { build(:building, building_type: "command_center", level: 1) }

      it "returns nil" do
        expect(info).to be_nil
      end
    end

    context "with a non-bunker military building" do
      let(:building) { build(:building, building_type: "training_camp", level: 1) }

      it "returns nil" do
        expect(info).to be_nil
      end
    end

    context "with a level 0 building" do
      let(:building) { build(:building, building_type: "solar_station", level: 0) }

      it "returns nil" do
        expect(info).to be_nil
      end
    end
  end
end
