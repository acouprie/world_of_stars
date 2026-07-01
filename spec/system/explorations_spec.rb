require "rails_helper"

RSpec.describe "Explorations page", type: :system do
  let(:user)           { create(:user) }
  let!(:planet)        { create(:planet, user: user) }
  let!(:target_planet) { create(:planet) }

  before { sign_in_as(user) }

  context "sans mission" do
    it "affiche l'état vide" do
      visit planet_explorations_path(planet)

      expect(page).to have_text("Explorations")
      expect(page).to have_text("0 / 5 missions actives")
      expect(page).to have_text("Aucune mission lancée pour l'instant.")
    end
  end

  context "avec une mission en cours", :js do
    before do
      create(:exploration_mission,
             planet:        planet,
             target_planet: target_planet,
             status:        "pending",
             started_at:    5.minutes.ago,
             finishes_at:   25.minutes.from_now,
             force_snapshot: { "sonde" => 3 })
    end

    it "affiche la carte de mission avec le timer et la barre de progression" do
      visit planet_explorations_path(planet)

      expect(page).to have_text("1 / 5 missions actives")
      expect(page).to have_text(/missions en cours/i)
      expect(page).to have_text(target_planet.name)
      expect(page).to have_text("3 Sonde")
      expect(page).to have_selector("[data-controller='queue-timer']")
      expect(page).to have_selector("[data-queue-timer-target='bar']")
      expect(page).not_to have_text("Aucune mission lancée pour l'instant.")
    end
  end

  context "avec une mission complétée" do
    before do
      create(:exploration_mission, :completed,
             planet:            planet,
             target_planet:     target_planet,
             force_snapshot:    { "sonde" => 2 },
             losses_snapshot:   { "sonde" => 1 },
             exploration_points: 80,
             metal_gained:      500,
             food_gained:       0,
             thorium_gained:    0)
    end

    it "affiche l'historique des missions" do
      visit planet_explorations_path(planet)

      expect(page).to have_text("Historique des missions")
      expect(page).to have_text(target_planet.name)
      expect(page).to have_text("+80 XP")
      expect(page).to have_text("Sonde: 1/2")
      expect(page).not_to have_text("Aucune mission lancée pour l'instant.")
    end
  end

  context "avec missions en cours et historique" do
    before do
      create(:exploration_mission,
             planet:         planet,
             target_planet:  target_planet,
             force_snapshot: { "maraudeur" => 5 })
      create(:exploration_mission, :completed,
             planet:         planet,
             target_planet:  target_planet,
             force_snapshot: { "sonde" => 2 },
             losses_snapshot: {})
    end

    it "n'affiche pas l'état vide" do
      visit planet_explorations_path(planet)

      expect(page).not_to have_text("Aucune mission lancée pour l'instant.")
      expect(page).to have_text("Missions en cours")
      expect(page).to have_text("Historique des missions")
    end
  end
end
