class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :planets, dependent: :nullify

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, uniqueness: true, length: { maximum: 14 }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validate :password_complexity

  # TODO: Returns 0 for all technologies until Technologies are implemented (tech_reference §6, §10).
  # When the Technologies feature lands, replace this with a DB lookup on the player's researched
  # technology levels (e.g. :armement, :chaine_de_production, :blindage_tactique).
  def technology_level(_technology_key)
    0
  end

  def password_complexity
    return if password.blank? || password.length < 8
    return if password =~ /(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#$%^&*(),.?":{}|<>])/
    errors.add :password, 'must include at least one lowercase letter, one uppercase letter, one digit, and one special character (!@#$%^&*(),.?":{}|<>)'
  end
end
