require "rails_helper"

RSpec.describe User, type: :model do
  it { is_expected.to have_secure_password }
  it { is_expected.to have_many(:sessions).dependent(:destroy) }

  describe "email normalization" do
    it "strips leading and trailing whitespace" do
      user = create(:user, email_address: "  alice@example.com  ")
      expect(user.email_address).to eq("alice@example.com")
    end

    it "downcases the address" do
      user = create(:user, email_address: "Alice@EXAMPLE.COM")
      expect(user.email_address).to eq("alice@example.com")
    end

    it "applies both strip and downcase together" do
      user = create(:user, email_address: "  Alice@EXAMPLE.COM  ")
      expect(user.email_address).to eq("alice@example.com")
    end
  end

  describe "validations" do
    describe "email_address" do
      it "requires presence" do
        user = build(:user, email_address: "")
        expect(user).not_to be_valid
        expect(user.errors[:email_address]).to be_present
      end

      it "requires a valid format" do
        user = build(:user, email_address: "not-an-email")
        expect(user).not_to be_valid
        expect(user.errors[:email_address]).to be_present
      end

      it "requires uniqueness" do
        create(:user, email_address: "alice@example.com")
        user = build(:user, email_address: "alice@example.com")
        expect(user).not_to be_valid
        expect(user.errors[:email_address]).to be_present
      end

      it "accepts a valid address" do
        expect(build(:user, email_address: "valid@example.com")).to be_valid
      end
    end

    describe "username" do
      it "requires presence" do
        user = build(:user, username: "")
        expect(user).not_to be_valid
        expect(user.errors[:username]).to be_present
      end

      it "rejects usernames longer than 14 characters" do
        user = build(:user, username: "a" * 15)
        expect(user).not_to be_valid
        expect(user.errors[:username]).to be_present
      end

      it "accepts a username of exactly 14 characters" do
        expect(build(:user, username: "a" * 14)).to be_valid
      end

      it "requires uniqueness" do
        create(:user, username: "taken")
        user = build(:user, username: "taken")
        expect(user).not_to be_valid
        expect(user.errors[:username]).to be_present
      end
    end

    describe "password" do
      it "rejects passwords shorter than 8 characters" do
        user = build(:user, password: "Ab1!", password_confirmation: "Ab1!")
        expect(user).not_to be_valid
        expect(user.errors[:password]).to be_present
      end

      it "rejects passwords without an uppercase letter" do
        user = build(:user, password: "password1!", password_confirmation: "password1!")
        expect(user).not_to be_valid
        expect(user.errors[:password]).to be_present
      end

      it "rejects passwords without a digit" do
        user = build(:user, password: "Password!!", password_confirmation: "Password!!")
        expect(user).not_to be_valid
        expect(user.errors[:password]).to be_present
      end

      it "rejects passwords without a special character" do
        user = build(:user, password: "Password1A", password_confirmation: "Password1A")
        expect(user).not_to be_valid
        expect(user.errors[:password]).to be_present
      end

      it "rejects passwords without a lowercase letter" do
        user = build(:user, password: "PASSWORD1!", password_confirmation: "PASSWORD1!")
        expect(user).not_to be_valid
        expect(user.errors[:password]).to be_present
      end

      it "accepts a password meeting all requirements" do
        expect(build(:user, password: "Password1!", password_confirmation: "Password1!")).to be_valid
      end
    end
  end

  describe ".authenticate_by" do
    let!(:user) { create(:user, email_address: "bob@example.com") }

    it "returns the user with correct credentials" do
      expect(User.authenticate_by(email_address: "bob@example.com", password: "Password1!")).to eq(user)
    end

    it "returns nil with wrong password" do
      expect(User.authenticate_by(email_address: "bob@example.com", password: "wrong")).to be_nil
    end

    it "returns nil for unknown email" do
      expect(User.authenticate_by(email_address: "ghost@example.com", password: "any")).to be_nil
    end
  end
end
