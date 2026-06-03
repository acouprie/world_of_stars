require 'rails_helper'

RSpec.describe "Homes", type: :request do
  describe "GET /" do
    context "when unauthenticated" do
      it "is accessible and returns success" do
        get "/"
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated" do
      let(:user) { create(:user) }

      before { sign_in(user) }

      context "with a planet" do
        let!(:planet) { create(:planet, :player, user: user) }

        it "redirects to the planet" do
          get "/"
          expect(response).to redirect_to(planet_path(planet))
        end
      end

    end
  end
end
