require "rails_helper"

RSpec.describe "ConstructionQueues", type: :request do
  let(:user) { create(:user) }
  let(:planet) do
    create(:planet, :home, user: user,
      metal_stock:          750,
      food_stock:           775,
      thorium_stock:        400,
      resources_updated_at: Time.current)
  end
  let(:building) { create(:building, planet: planet, building_type: "command_center", level: 0, slot_index: 0) }
  let!(:queue) do
    create(:construction_queue,
      planet:       planet,
      building:     building,
      target_level: 1,
      status:       "pending",
      started_at:   Time.current,
      completes_at: 1.hour.from_now)
  end

  let(:other_user)   { create(:user) }
  let(:other_planet) { create(:planet, :player, user: other_user) }

  describe "DELETE /planets/:planet_id/construction_queue" do
    context "when authenticated" do
      before { sign_in(user) }

      it "cancels the construction and redirects with a notice" do
        delete planet_construction_queue_path(planet)
        expect(response).to redirect_to(planet_path(planet))
        expect(flash[:notice]).to eq(I18n.t("flash.construction_queues.cancelled"))
      end

      it "destroys the queue record for a new building" do
        delete planet_construction_queue_path(planet)
        expect { queue.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "destroys the level-0 building to free the slot" do
        delete planet_construction_queue_path(planet)
        expect { building.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "refunds metal to the planet" do
        cost = Buildings::Calculator.cost("command_center", 1)
        delete planet_construction_queue_path(planet)
        expect(planet.reload.metal_stock.to_f).to be_within(1).of(750 + cost[:metal])
      end

      context "via turbo_stream" do
        let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

        it "returns 200 with turbo-stream content type" do
          delete planet_construction_queue_path(planet), headers: turbo_headers
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end

        it "includes queue-bar replacement" do
          delete planet_construction_queue_path(planet), headers: turbo_headers
          expect(response.body).to include('target="queue-bar"')
        end

        it "includes resources_bar replacement" do
          delete planet_construction_queue_path(planet), headers: turbo_headers
          expect(response.body).to include('target="resources_bar"')
        end

        it "includes the success flash notice" do
          delete planet_construction_queue_path(planet), headers: turbo_headers
          expect(response.body).to include(I18n.t("flash.construction_queues.cancelled"))
        end
      end

      context "when no construction is in progress" do
        before { queue.update!(status: "completed") }

        it "redirects with an alert" do
          delete planet_construction_queue_path(planet)
          expect(response).to redirect_to(planet_path(planet))
          expect(flash[:alert]).to be_present
        end

        context "via turbo_stream" do
          it "returns a flash alert stream" do
            delete planet_construction_queue_path(planet),
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
            expect(response).to have_http_status(:ok)
            expect(response.body).to include('target="flash-messages"')
          end
        end
      end

      context "when accessing another user's planet" do
        it "returns 404" do
          delete planet_construction_queue_path(other_planet)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when not authenticated" do
      it "redirects to root" do
        delete planet_construction_queue_path(planet)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
