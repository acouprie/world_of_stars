require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  describe "#reset" do
    let(:user) { create(:user) }
    let(:mail) { described_class.reset(user) }

    it "is sent to the user's email address" do
      expect(mail.to).to eq([user.email_address])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Reset your password")
    end

    it "includes a link to the password reset page in the HTML part" do
      expect(mail.html_part.decoded).to match(%r{/passwords/.+/edit})
    end

    it "includes a link to the password reset page in the text part" do
      expect(mail.text_part.decoded).to match(%r{/passwords/.+/edit})
    end
  end
end
