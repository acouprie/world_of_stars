require "rails_helper"

RSpec.describe "Users", type: :request do
  describe "POST /users" do
    let(:valid_params) do
      {
        email_address: "nova@example.com",
        username: "nova",
        password: "Password1!",
        password_confirmation: "Password1!"
      }
    end

    context "with valid params and an available planet" do
      before { create(:planet) }

      it "creates a User record" do
        expect { post users_path, params: valid_params }.to change(User, :count).by(1)
      end

      it "logs the user in (sets session cookie)" do
        post users_path, params: valid_params
        expect(cookies[:session_id]).to be_present
      end

      it "creates a Session record" do
        expect { post users_path, params: valid_params }.to change(Session, :count).by(1)
      end

      it "assigns a home planet via OnboardingService" do
        post users_path, params: valid_params
        user = User.find_by(email_address: valid_params[:email_address])
        expect(user.planets.where(is_home: true).count).to eq(1)
      end

      it "redirects to planet url after registration" do
        post users_path, params: valid_params
        user = User.find_by(email_address: "nova@example.com")
        planet = user.planets.first
        expect(response).to redirect_to(planet_url(planet))
      end
    end

    context "with a duplicate email" do
      before do
        create(:planet)
        create(:user, email_address: "nova@example.com")
      end

      it "does not create a User" do
        expect { post users_path, params: valid_params }.not_to change(User, :count)
      end

      it "redirects to the register tab with an alert" do
        post users_path, params: valid_params
        expect(response).to redirect_to(root_path(tab: :register))
        expect(flash[:alert]).to be_present
      end
    end

    context "with a duplicate username" do
      before do
        create(:planet)
        create(:user, username: "nova")
      end

      it "does not create a User" do
        expect { post users_path, params: valid_params }.not_to change(User, :count)
      end

      it "redirects to the register tab with an alert" do
        post users_path, params: valid_params
        expect(response).to redirect_to(root_path(tab: :register))
        expect(flash[:alert]).to be_present
      end
    end

    context "with a username longer than 14 characters" do
      let(:params) { valid_params.merge(username: "a" * 15) }

      it "does not create a User" do
        expect { post users_path, params: params }.not_to change(User, :count)
      end

      it "redirects to the register tab with an alert" do
        post users_path, params: params
        expect(response).to redirect_to(root_path(tab: :register))
        expect(flash[:alert]).to be_present
      end
    end

    context "with a password that is too short" do
      let(:params) { valid_params.merge(password: "Ab1!", password_confirmation: "Ab1!") }

      it "does not create a User" do
        expect { post users_path, params: params }.not_to change(User, :count)
      end

      it "redirects to the register tab with an alert" do
        post users_path, params: params
        expect(response).to redirect_to(root_path(tab: :register))
        expect(flash[:alert]).to be_present
      end
    end

    context "with a password that fails complexity rules" do
      let(:params) { valid_params.merge(password: "alllowercase1", password_confirmation: "alllowercase1") }

      it "does not create a User" do
        expect { post users_path, params: params }.not_to change(User, :count)
      end

      it "redirects to the register tab with an alert" do
        post users_path, params: params
        expect(response).to redirect_to(root_path(tab: :register))
        expect(flash[:alert]).to be_present
      end
    end

    context "when password and confirmation do not match" do
      let(:params) { valid_params.merge(password_confirmation: "Different1!") }

      it "does not create a User" do
        expect { post users_path, params: params }.not_to change(User, :count)
      end

      it "redirects to the register tab with an alert" do
        post users_path, params: params
        expect(response).to redirect_to(root_path(tab: :register))
        expect(flash[:alert]).to be_present
      end
    end

    context "with a missing email" do
      let(:params) { valid_params.except(:email_address) }

      it "does not create a User" do
        expect { post users_path, params: params }.not_to change(User, :count)
      end

      it "redirects to the register tab with an alert" do
        post users_path, params: params
        expect(response).to redirect_to(root_path(tab: :register))
        expect(flash[:alert]).to be_present
      end
    end

    context "with a missing username" do
      let(:params) { valid_params.except(:username) }

      it "does not create a User" do
        expect { post users_path, params: params }.not_to change(User, :count)
      end

      it "redirects to the register tab with an alert" do
        post users_path, params: params
        expect(response).to redirect_to(root_path(tab: :register))
        expect(flash[:alert]).to be_present
      end
    end
  end
end
