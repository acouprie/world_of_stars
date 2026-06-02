require "rails_helper"

RSpec.describe "Planets", type: :request do
  let(:user)   { create(:user) }
  let(:planet) { create(:planet, :home, user: user) }

  let(:other_user)   { create(:user) }
  let(:other_planet) { create(:planet, :player, user: other_user) }

  describe "authentication" do
    it "redirects unauthenticated user to root" do
      get planet_path(planet)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /planets/:id" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns http success" do
        get planet_path(planet)
        expect(response).to have_http_status(:success)
      end

      it "displays the planet name" do
        get planet_path(planet)
        expect(response.body).to include(planet.name)
      end

      it "returns 404 for an unknown planet" do
        get planet_path(id: 0)
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 when accessing another user's planet" do
        get planet_path(other_planet)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /planets/:id/edit" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns http success" do
        get edit_planet_path(planet)
        expect(response).to have_http_status(:success)
      end

      it "returns 404 when editing another user's planet" do
        get edit_planet_path(other_planet)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "redirects to root" do
        get edit_planet_path(planet)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /planets/:id" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns http success" do
        patch planet_path(planet)
        expect(response).to have_http_status(:success)
      end

      it "returns 404 when updating another user's planet" do
        patch planet_path(other_planet)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "redirects to root" do
        patch planet_path(planet)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
