require "rails_helper"

RSpec.describe "Combats page", type: :system do
  let(:user)           { create(:user) }
  let!(:planet)        { create(:planet, :home, user: user, resources_updated_at: Time.current) }
  let!(:target_planet) { create(:planet, :player, user: create(:user)) }

  before { sign_in_as(user) }

  context "with no mission and no selected target" do
    it "renders the empty state" do
      visit planet_combats_path(planet)

      expect(page).to have_text("Combats")
      expect(page).to have_text("Aucune attaque lancée pour l'instant.")
    end
  end

  context "with a selected target", :js do
    before do
      create(:building, planet: planet,        building_type: "quantum_portal", level: 1, slot_index: 1)
      create(:building, planet: target_planet, building_type: "quantum_portal", level: 1, slot_index: 1)
      create(:unit, planet: planet, unit_type: "maraudeur", count: 10)
    end

    it "keeps the submit button disabled until a unit is selected, then launches the attack" do
      visit planet_combats_path(planet, target_planet_id: target_planet.id)

      expect(page).to have_text(/composer la force d.assaut/i)
      expect(page).to have_button("Attaquer", disabled: true)

      fill_in "force[maraudeur]", with: "5"
      expect(page).to have_button("Attaquer", disabled: false)

      click_button "Attaquer"

      expect(page).to have_text("Attaque lancée")
      expect(page).to have_text(/missions en cours/i)
      expect(page).to have_text(target_planet.name)
      expect(page).to have_selector("[data-controller='queue-timer']")
      expect(planet.combat_missions.traveling.count).to eq(1)
    end
  end

  context "with a completed mission" do
    before do
      create(:combat_mission, :completed,
             planet:                  planet,
             target_planet:           target_planet,
             attacker_losses:         { "maraudeur" => 2 },
             defender_losses:         { "sentinelle" => 5 },
             attacker_xp_gained:      120,
             metal_pillaged:          300)
    end

    it "renders the history entry with outcome, losses, and pillage" do
      visit planet_combats_path(planet)

      expect(page).to have_text(/historique des rapports/i)
      expect(page).to have_text(target_planet.name)
      expect(page).to have_text("Victoire")
      expect(page).to have_text("+120 XP gagnée")
      expect(page).not_to have_text("Aucune attaque lancée pour l'instant.")
    end
  end

  context "security — another user's planet" do
    it "returns 404" do
      other_planet = create(:planet, :player, user: create(:user))

      visit planet_combats_path(other_planet)

      expect(page.status_code).to eq(404)
    end
  end
end
