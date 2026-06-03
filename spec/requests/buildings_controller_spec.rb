require "rails_helper"

RSpec.describe "Buildings", type: :request do
  let(:user)   { create(:user) }
  let(:planet) do
    create(:planet, :home, user: user,
      metal_stock:          800,
      food_stock:           800,
      thorium_stock:        400,
      resources_updated_at: Time.current)
  end

  let(:other_user)   { create(:user) }
  let(:other_planet) { create(:planet, :player, user: other_user) }

  describe "GET /planets/:planet_id/buildings/new" do
    context "when authenticated" do
      before { sign_in(user) }

      it "rend le panneau avec la liste des bâtiments disponibles" do
        get new_planet_building_path(planet, slot_index: 0)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(I18n.t("buildings.types.command_center"))
      end

      it "n'affiche que les bâtiments dont les prérequis sont satisfaits" do
        get new_planet_building_path(planet, slot_index: 0)
        # Sans command_center, seul command_center doit apparaître
        expect(response.body).to include(I18n.t("buildings.types.command_center"))
        expect(response.body).not_to include(I18n.t("buildings.types.solar_station"))
      end

      it "affiche tous les bâtiments une fois command_center construit" do
        create(:building, planet: planet, building_type: "command_center", level: 1)
        get new_planet_building_path(planet, slot_index: 1)
        expect(response.body).to include(I18n.t("buildings.types.solar_station"))
      end

      it "returns 404 when accessing another user's planet" do
        get new_planet_building_path(other_planet, slot_index: 0)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "redirects to root" do
        get new_planet_building_path(planet, slot_index: 0)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /planets/:planet_id/buildings" do
    context "when authenticated" do
      before { sign_in(user) }

      context "avec les prérequis satisfaits et les ressources suffisantes" do
        it "lance la construction et redirige avec une notice" do
          post planet_buildings_path(planet), params: { building_type: "command_center", slot_index: 0 }
          expect(response).to redirect_to(planet_path(planet))
          expect(flash[:notice]).to eq(I18n.t("flash.buildings.created"))
        end

        it "crée un Building sur la planète" do
          expect {
            post planet_buildings_path(planet), params: { building_type: "command_center", slot_index: 0 }
          }.to change { planet.buildings.count }.by(1)
        end

        it "honore le slot_index demandé" do
          post planet_buildings_path(planet), params: { building_type: "command_center", slot_index: 3 }
          expect(planet.buildings.find_by(building_type: "command_center").slot_index).to eq(3)
        end
      end

      context "quand un prérequis est manquant" do
        it "échoue à construire solar_station sans command_center et redirige avec une alerte" do
          post planet_buildings_path(planet), params: { building_type: "solar_station", slot_index: 0 }
          expect(response).to redirect_to(planet_path(planet))
          expect(flash[:alert]).to be_present
        end

        it "ne crée pas de bâtiment" do
          expect {
            post planet_buildings_path(planet), params: { building_type: "solar_station", slot_index: 0 }
          }.not_to change { planet.buildings.count }
        end
      end

      context "quand une construction est déjà en cours" do
        before do
          # Lance une première construction
          post planet_buildings_path(planet), params: { building_type: "command_center", slot_index: 0 }
        end

        it "échoue et redirige avec une alerte" do
          post planet_buildings_path(planet), params: { building_type: "command_center", slot_index: 1 }
          expect(response).to redirect_to(planet_path(planet))
          expect(flash[:alert]).to be_present
        end
      end

      context "quand les ressources sont insuffisantes" do
        before { planet.update!(metal_stock: 0, food_stock: 0, thorium_stock: 0) }

        it "échoue et redirige avec une alerte" do
          post planet_buildings_path(planet), params: { building_type: "command_center", slot_index: 0 }
          expect(response).to redirect_to(planet_path(planet))
          expect(flash[:alert]).to be_present
        end
      end

      context "sécurité — planète d'un autre joueur" do
        it "retourne 404" do
          post planet_buildings_path(other_planet), params: { building_type: "command_center", slot_index: 0 }
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when not authenticated" do
      it "redirects to root" do
        post planet_buildings_path(planet), params: { building_type: "command_center", slot_index: 0 }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
