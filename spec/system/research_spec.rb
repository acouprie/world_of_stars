require "rails_helper"

RSpec.describe "Research system", type: :system do
  let(:user)   { create(:user) }
  let(:planet) { create(:planet, user: user) }

  before do
    # All technologies require exploration: 1 (exploration_xp >= 1000).
    user.update!(exploration_xp: 1000)
    create(:building, planet: planet, building_type: "research_lab", level: 1, slot_index: 1)
    planet.update!(metal_stock: 5_000, food_stock: 5_000, thorium_stock: 5_000)
    sign_in_as(user)
  end

  it "affiche la page de recherche avec l'arbre de technologies" do
    visit planet_research_path(planet)

    expect(page).to have_text("Production")
    expect(page).to have_text("Exploration niveau 1")
    expect(page).to have_text("Aucune recherche en cours")
  end

  it "lance une recherche et affiche le timer de la file", :js do
    visit planet_research_path(planet)

    find(:xpath, "//form[.//input[@name='tech_key' and @value='forage_cristallin']]//input[@type='submit']").click

    expect(page).to have_text("Forage cristallin")
    expect(page).to have_selector("[data-controller='queue-timer']")
    expect(ResearchQueue.pending.count).to eq(1)
  end

  it "annule une recherche en cours et rembourse les ressources", :js do
    create(:research_queue,
           planet:       planet,
           tech_key:     "hydroponie",
           target_level: 1,
           status:       "pending",
           started_at:   Time.current,
           completes_at: 1.hour.from_now,
           metal_cost:   500,
           food_cost:    300,
           thorium_cost: 0)
    # Start from 0 so calculate_resources! (called by CancelService) doesn't
    # exceed capacity and the refund is simply metal_cost.
    planet.update!(metal_stock: 0, food_stock: 0, thorium_stock: 0)

    visit planet_research_path(planet)
    expect(page).to have_text("Hydroponie")

    # Opens the Stimulus confirm-dialog, then confirms.
    within("#research-queue-bar") { click_on "Annuler" }
    click_button "Confirmer"

    expect(page).to have_text("Aucune recherche en cours")
    expect(ResearchQueue.cancelled.count).to eq(1)
    expect(planet.reload.metal_stock).to be >= 500
  end

  it "désactive le bouton des technos dont les prérequis ne sont pas satisfaits" do
    planet.buildings.find_by(building_type: "research_lab").update!(level: 0)

    visit planet_research_path(planet)

    expect(page).to have_text("Prérequis non remplis")
    expect(page).not_to have_selector("input[type='submit'][value='Rechercher']:not([disabled])")
  end

  it "redirige si on tente d'accéder à la page research d'une planète adverse" do
    other_planet = create(:planet, user: create(:user))

    visit planet_research_path(other_planet)

    expect(page.status_code).to eq(404)
  end

  it "affiche correctement le niveau d'exploration et la barre de progression" do
    user.update!(exploration_xp: 1_200)

    visit planet_research_path(planet)

    expect(page).to have_text("Exploration niveau 2")
    expect(page).to have_selector("div[style*='background: var(--color-quantum)']")
  end
end
