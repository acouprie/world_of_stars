require "rails_helper"

RSpec.describe Planet, type: :model do
  describe "biome production bonuses" do

    # ── 1. Bonus correct par ressource ────────────────────────────────────────

    describe "bonus application per resource" do
      Planet::BIOME_BONUSES.each do |biome_sym, bonuses|
        context "biome: #{biome_sym}" do
          let(:planet) { create(:planet, biome: biome_sym.to_s) }

          %i[metal food thorium].each do |resource|
            mine_type = { metal: "metal_mine", food: "farm", thorium: "thorium_mine" }[resource]
            rate_method = :"#{resource}_rate"

            if bonuses.key?(resource)
              it "#{resource}_rate is greater than base_rate (bonus applied)" do
                create(:building, planet: planet, building_type: mine_type, level: 3, slot_index: 2)
                planet.buildings.reload
                base = Buildings::Calculator.production_rate(mine_type.to_sym, 3)
                expect(planet.send(rate_method)).to be > base
              end
            else
              it "#{resource}_rate equals base_rate (no parasitic bonus)" do
                create(:building, planet: planet, building_type: mine_type, level: 3, slot_index: 2)
                planet.buildings.reload
                base = Buildings::Calculator.production_rate(mine_type.to_sym, 3)
                expect(planet.send(rate_method)).to eq base
              end
            end
          end
        end
      end
    end

    # ── 2. Formule dégressive ─────────────────────────────────────────────────

    describe "degressive formula (arid, k=3.0 on metal)" do
      let(:planet) { create(:planet, biome: "arid") }

      it "ratio metal_rate/base_rate strictly decreases as mine level increases" do
        ratios = [1, 5, 10, 20].map do |lvl|
          create(:building, planet: planet, building_type: "metal_mine", level: lvl, slot_index: 2)
          planet.buildings.reload
          base = Buildings::Calculator.production_rate(:metal_mine, lvl)
          ratio = planet.metal_rate / base
          planet.buildings.where(building_type: "metal_mine").destroy_all
          ratio
        end

        ratios.each_cons(2) do |higher, lower|
          expect(higher).to be > lower
        end
      end
    end

    # ── 3. Ressource sans bonus défini ────────────────────────────────────────

    describe "biome_bonus for undefined resource" do
      let(:planet) { create(:planet, biome: "arid") }

      it "returns 0.0" do
        expect(planet.biome_bonus(:food)).to eq 0.0
      end

      it "food_rate equals base_rate" do
        create(:building, planet: planet, building_type: "farm", level: 2, slot_index: 2)
        planet.buildings.reload
        base = Buildings::Calculator.production_rate(:farm, 2)
        expect(planet.food_rate).to eq base
      end
    end

    # ── 4. calculate_resources! intègre le bonus ──────────────────────────────

    describe "calculate_resources! accumulates the biome bonus" do
      it "metal_stock after 3600s is greater than base_rate_lv1 × 3600" do
        planet = create(:planet, biome: "arid", metal_stock: 0, resources_updated_at: Time.current)
        create(:building, planet: planet, building_type: "metal_mine", level: 1, slot_index: 2)
        planet.buildings.reload

        base_rate_lv1 = Buildings::Calculator.production_rate(:metal_mine, 1)
        future = planet.resources_updated_at + 3600.seconds

        planet.with_lock { planet.calculate_resources!(now: future) }

        expect(planet.metal_stock).to be > base_rate_lv1 * 3600
      end
    end

  end
end
