require "rails_helper"

RSpec.describe "Combats::Missions", type: :request do
  let(:attacker) { create(:user) }
  let(:defender) { create(:user) }
  let(:planet)        { create(:planet, :player, user: attacker, resources_updated_at: Time.current) }
  let(:target_planet) { create(:planet, :player, user: defender, resources_updated_at: Time.current) }

  let!(:source_portal)  { create(:building, planet: planet,        building_type: "quantum_portal", level: 1, slot_index: 1) }
  let!(:target_portal)  { create(:building, planet: target_planet, building_type: "quantum_portal", level: 1, slot_index: 1) }
  let!(:maraudeur_unit) { create(:unit, planet: planet, unit_type: "maraudeur", count: 10) }

  let(:other_user)   { create(:user) }
  let(:other_planet) { create(:planet, :player, user: other_user) }

  def launch(target: target_planet, force: { maraudeur: 5 }, headers: {})
    post planet_combats_path(planet), params: { target_planet_id: target.id, force: force }, headers: headers
  end

  describe "POST /planets/:planet_id/combats" do
    context "when authenticated" do
      before { sign_in(attacker) }

      context "with a valid force" do
        it "launches the attack and redirects with a notice" do
          launch
          expect(response).to redirect_to(planet_combats_path(planet))
          expect(flash[:notice]).to eq(I18n.t("flash.combats.started"))
        end

        it "creates a traveling mission" do
          expect { launch }.to change { planet.combat_missions.traveling.count }.by(1)
        end

        it "deducts the sent units from the source planet" do
          launch
          expect(maraudeur_unit.reload.count).to eq(5)
        end

        it "schedules CompleteCombatJob" do
          expect { launch }.to have_enqueued_job(CompleteCombatJob)
        end

        context "via turbo_stream" do
          let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

          it "returns 200 with turbo-stream content type" do
            launch(headers: turbo_headers)
            expect(response).to have_http_status(:ok)
            expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          end

          it "includes resources_bar and outgoing-missions-section replacements" do
            launch(headers: turbo_headers)
            expect(response.body).to include('target="resources_bar"')
            expect(response.body).to include('target="outgoing-missions-section"')
          end

          it "includes the success flash notice" do
            launch(headers: turbo_headers)
            expect(response.body).to include(I18n.t("flash.combats.started"))
          end
        end
      end

      context "when the target planet has no quantum portal" do
        before { target_portal.destroy! }

        it "fails, redirects with an alert, and does not deduct units" do
          launch
          expect(flash[:alert]).to eq(I18n.t("flash.combats.no_quantum_portal_target"))
          expect(maraudeur_unit.reload.count).to eq(10)
        end
      end

      context "when the source planet has no quantum portal" do
        before { source_portal.destroy! }

        it "fails and redirects with an alert" do
          launch
          expect(flash[:alert]).to eq(I18n.t("flash.combats.no_quantum_portal_source"))
        end
      end

      context "when attacking one's own planet" do
        it "fails and redirects with an alert" do
          own_planet = create(:planet, :player, user: attacker)
          create(:building, planet: own_planet, building_type: "quantum_portal", level: 1, slot_index: 1)

          launch(target: own_planet)

          expect(flash[:alert]).to eq(I18n.t("flash.combats.cannot_attack_own_planet"))
        end
      end

      context "with insufficient units" do
        it "fails and does not deduct any unit" do
          launch(force: { maraudeur: 20 })
          expect(flash[:alert]).to eq(I18n.t("flash.combats.insufficient_units"))
          expect(maraudeur_unit.reload.count).to eq(10)
        end
      end

      context "with an empty force" do
        it "fails and redirects with an alert" do
          launch(force: {})
          expect(flash[:alert]).to eq(I18n.t("flash.combats.empty_force"))
        end
      end

      context "security — another user's planet" do
        it "returns 404" do
          post planet_combats_path(other_planet), params: { target_planet_id: target_planet.id, force: { maraudeur: 5 } }
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when not authenticated" do
      it "redirects to root" do
        launch
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
