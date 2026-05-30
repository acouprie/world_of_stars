FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    email_address { Faker::Internet.unique.email }
    password { "Password1!" }
    password_confirmation { "Password1!" }
  end
end
