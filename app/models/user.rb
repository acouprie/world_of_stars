class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :planets, dependent: :nullify

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, uniqueness: true, length: { maximum: 14 }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validate :password_complexity

  def password_complexity
    return if password.blank? || password.length < 8
    return if password =~ /(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#$%^&*(),.?":{}|<>])/
    errors.add :password, 'must include at least one lowercase letter, one uppercase letter, one digit, and one special character (!@#$%^&*(),.?":{}|<>)'
  end
end
