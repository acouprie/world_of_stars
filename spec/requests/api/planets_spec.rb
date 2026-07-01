require "rails_helper"

RSpec.describe "Api::Planets", type: :request do
  let(:user)   { create(:user) }
  let(:planet) { create(:planet, user: user) }

  before { sign_in(user) }

  describe "GET /api/planets/:id/exploration_readiness" do
    subject(:readiness) { JSON.parse(response.body) }

    context "sans unités ni mission active" do
      it "retourne une liste vide et can_launch: true" do
        get exploration_readiness_api_planet_path(planet)

        expect(response).to have_http_status(:ok)
        expect(readiness["units"]).to eq([])
        expect(readiness["active_missions"]).to eq(0)
        expect(readiness["max_missions"]).to eq(5)
        expect(readiness["can_launch"]).to be(true)
      end
    end

    context "avec des unités disponibles" do
      before do
        create(:unit, planet: planet, unit_type: "sonde",    count: 10)
        create(:unit, planet: planet, unit_type: "maraudeur", count: 5)
      end

      it "retourne les unités avec leur nom traduit et leur stock" do
        get exploration_readiness_api_planet_path(planet)

        expect(response).to have_http_status(:ok)
        types = readiness["units"].map { |u| u["type"] }
        expect(types).to include("sonde", "maraudeur")

        sonde = readiness["units"].find { |u| u["type"] == "sonde" }
        expect(sonde["count"]).to eq(10)
        expect(sonde["name"]).to be_present
      end

      it "n'inclut pas les unités avec count = 0" do
        create(:unit, planet: planet, unit_type: "scientifique", count: 0)

        get exploration_readiness_api_planet_path(planet)

        types = readiness["units"].map { |u| u["type"] }
        expect(types).not_to include("scientifique")
      end
    end

    context "avec 5 missions actives (limite atteinte)" do
      let(:target) { create(:planet) }

      before do
        5.times { create(:exploration_mission, planet: planet, target_planet: target) }
      end

      it "retourne can_launch: false" do
        get exploration_readiness_api_planet_path(planet)

        expect(readiness["active_missions"]).to eq(5)
        expect(readiness["can_launch"]).to be(false)
      end
    end

    context "avec une planète appartenant à un autre joueur" do
      let(:other_planet) { create(:planet) }

      it "retourne 404" do
        get exploration_readiness_api_planet_path(other_planet)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
