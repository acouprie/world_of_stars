require "rails_helper"

RSpec.describe "Passwords", type: :request do
  describe "GET /passwords/new" do
    it "is accessible without authentication" do
      get new_password_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /passwords" do
    let(:user) { create(:user) }

    context "when the email exists" do
      it "enqueues a reset email" do
        expect {
          post passwords_path, params: { email_address: user.email_address }
        }.to have_enqueued_mail(PasswordsMailer, :reset)
      end

      it "redirects to login with notice" do
        post passwords_path, params: { email_address: user.email_address }
        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq(I18n.t("flash.passwords.instructions_sent"))
      end
    end

    context "when the email does not exist" do
      it "does not enqueue an email" do
        expect {
          post passwords_path, params: { email_address: "nobody@example.com" }
        }.not_to have_enqueued_mail
      end

      it "returns the same response as if the email existed (no info leakage)" do
        post passwords_path, params: { email_address: "nobody@example.com" }
        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq(I18n.t("flash.passwords.instructions_sent"))
      end
    end
  end

  describe "GET /passwords/:token/edit" do
    let(:user) { create(:user) }

    context "with a valid token" do
      it "returns 200" do
        get edit_password_path(user.password_reset_token)
        expect(response).to have_http_status(:ok)
      end
    end

    context "with an invalid token" do
      it "redirects to new_password_path with alert" do
        get edit_password_path("invalid-token")
        expect(response).to redirect_to(new_password_path)
        expect(flash[:alert]).to eq(I18n.t("flash.passwords.invalid_link"))
      end
    end
  end

  describe "PATCH /passwords/:token" do
    let(:user) { create(:user) }

    context "with a valid new password" do
      it "redirects to login with notice" do
        patch password_path(user.password_reset_token),
          params: { password: "NewPassword1!", password_confirmation: "NewPassword1!" }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq(I18n.t("flash.passwords.reset_success"))
      end

      it "destroys all existing sessions" do
        create_list(:session, 2, user: user)

        patch password_path(user.password_reset_token),
          params: { password: "NewPassword1!", password_confirmation: "NewPassword1!" }

        expect(user.sessions.count).to eq(0)
      end

      it "allows login with the new password" do
        patch password_path(user.password_reset_token),
          params: { password: "NewPassword1!", password_confirmation: "NewPassword1!" }

        sign_in(user, password: "NewPassword1!")
        expect(cookies[:session_id]).to be_present
      end
    end

    context "with mismatched passwords" do
      it "redirects back to the edit form with alert" do
        token = user.password_reset_token

        patch password_path(token),
          params: { password: "NewPassword1!", password_confirmation: "different!" }

        expect(response).to redirect_to(edit_password_path(token))
        expect(flash[:alert]).to eq(I18n.t("flash.passwords.mismatch"))
      end

      it "does not change the password" do
        patch password_path(user.password_reset_token),
          params: { password: "NewPassword1!", password_confirmation: "different!" }

        expect(User.authenticate_by(email_address: user.email_address, password: "Password1!")).to eq(user)
      end
    end

    context "with an invalid token" do
      it "redirects to new_password_path with alert" do
        patch password_path("invalid-token"),
          params: { password: "NewPassword1!", password_confirmation: "NewPassword1!" }

        expect(response).to redirect_to(new_password_path)
        expect(flash[:alert]).to eq(I18n.t("flash.passwords.invalid_link"))
      end
    end
  end
end
