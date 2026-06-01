require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "POST /session" do
    let(:user) { create(:user) }

    context "with valid credentials" do
      it "sets a session cookie" do
        sign_in(user)
        expect(cookies[:session_id]).to be_present
      end

      it "redirects to the stored return_to URL" do
        sign_in(user)
        # sign_in first calls DELETE /session (unauthenticated) which stores that URL as return_to
        expect(response).to redirect_to(session_url)
      end

      it "creates a Session record for the user" do
        expect { sign_in(user) }.to change { user.sessions.count }.by(1)
      end
    end

    context "with wrong password" do
      it "redirects to login with alert" do
        post session_path, params: { email_address: user.email_address, password: "wrong" }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Adresse e-mail ou mot de passe incorrect.")
      end

      it "does not create a Session record" do
        expect {
          post session_path, params: { email_address: user.email_address, password: "wrong" }
        }.not_to change { Session.count }
      end
    end

    context "with unknown email" do
      it "redirects to login with alert" do
        post session_path, params: { email_address: "ghost@example.com", password: "any" }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Adresse e-mail ou mot de passe incorrect.")
      end
    end
  end

  describe "DELETE /session" do
    let(:user) { create(:user) }

    context "when authenticated" do
      before { sign_in(user) }

      it "redirects to login" do
        delete session_path
        expect(response).to redirect_to(root_path)
      end

      it "clears the session cookie" do
        delete session_path
        expect(cookies[:session_id]).to be_blank
      end

      it "destroys the Session record" do
        expect { delete session_path }.to change { user.sessions.count }.by(-1)
      end
    end

    context "when not authenticated" do
      it "redirects to login (Authentication concern)" do
        delete session_path
        expect(response).to redirect_to(root_path)
      end

      it "stores the requested URL for redirect after login" do
        delete session_path
        expect(session[:return_to_after_authenticating]).to be_present
      end
    end
  end
end
