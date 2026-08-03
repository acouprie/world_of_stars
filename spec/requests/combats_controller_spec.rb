require "rails_helper"

RSpec.describe "Combats", type: :request do
  let(:user)   { create(:user) }
  let(:planet) { create(:planet, :player, user: user, resources_updated_at: Time.current) }

  let(:other_user)   { create(:user) }
  let(:other_planet) { create(:planet, :player, user: other_user) }

  describe "GET /planets/:planet_id/combats" do
    context "when authenticated" do
      before { sign_in(user) }

      it "renders successfully" do
        get planet_combats_path(planet)
        expect(response).to have_http_status(:success)
      end

      it "renders the empty state when there is no mission and no selected target" do
        get planet_combats_path(planet)
        expect(response.body).to include(ERB::Util.html_escape(I18n.t("combats.no_missions_yet")))
      end

      it "does not render the launch form when target_planet_id is absent" do
        get planet_combats_path(planet)
        expect(response.body).not_to include(ERB::Util.html_escape(I18n.t("combats.launch_form.title")))
      end

      it "renders the launch form when target_planet_id is provided" do
        create(:unit, planet: planet, unit_type: "maraudeur", count: 5)
        get planet_combats_path(planet), params: { target_planet_id: other_planet.id }
        expect(response.body).to include(other_planet.name)
        expect(response.body).to include(ERB::Util.html_escape(I18n.t("combats.launch_form.title")))
      end

      it "lists outgoing traveling missions" do
        create(:combat_mission, planet: planet, target_planet: other_planet, status: "traveling")
        get planet_combats_path(planet)
        expect(response.body).to include(I18n.t("combats.active_section"))
        expect(response.body).to include(other_planet.name)
      end

      it "lists completed mission history" do
        create(:combat_mission, :completed, planet: planet, target_planet: other_planet)
        get planet_combats_path(planet)
        expect(response.body).to include(I18n.t("combats.history_section"))
      end

      it "returns 404 when accessing another user's planet" do
        get planet_combats_path(other_planet)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "redirects to root" do
        get planet_combats_path(planet)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "completed mission loss labels" do
    let!(:mission) do
      create(:combat_mission, :completed,
             planet:          planet,
             target_planet:   other_planet,
             outcome:         "attacker_wins",
             attacker_losses: {},
             defender_losses: { "maraudeur" => 20, "mule" => 5 })
    end

    it "labels the defender's losses as defender losses on the attacker's report" do
      sign_in(user)
      get planet_combats_path(planet)
      expect(response.body).to include(I18n.t("combats.defender_losses"))
      expect(response.body).not_to include(I18n.t("combats.attacker_losses"))
    end

    it "labels the defender's own losses as defender losses on the defender's report" do
      sign_in(other_user)
      get planet_combats_path(other_planet)
      expect(response.body).to include(I18n.t("combats.defender_losses"))
      expect(response.body).not_to include(I18n.t("combats.attacker_losses"))
    end
  end

  describe "completed mission troops sent and survivors" do
    let!(:mission) do
      create(:combat_mission, :completed,
             planet:                  planet,
             target_planet:           other_planet,
             outcome:                 "defender_holds",
             attacker_force:          { "maraudeur" => 20, "mule" => 5 },
             defender_force_snapshot: { "sentinelle" => 10 },
             attacker_losses:         { "maraudeur" => 5 },
             defender_losses:         {})
    end

    it "shows the sent force and the attacker's own survivors on the attacker's report" do
      sign_in(user)
      get planet_combats_path(planet)

      expect(response.body).to include(I18n.t("combats.troops_sent"))
      expect(response.body).to include("Maraudeur 20")
      expect(response.body).to include("Mule 5")
      expect(response.body).to include(I18n.t("combats.attacker_survivors"))
      expect(response.body).to include("Maraudeur 15")
    end

    it "shows the same sent force and the defender's own survivors on the defender's report" do
      sign_in(other_user)
      get planet_combats_path(other_planet)

      expect(response.body).to include(I18n.t("combats.troops_sent"))
      expect(response.body).to include("Maraudeur 20")
      expect(response.body).to include(I18n.t("combats.defender_survivors"))
      expect(response.body).to include("Sentinelle 10")
    end
  end
end
