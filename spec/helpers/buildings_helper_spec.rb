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
end
