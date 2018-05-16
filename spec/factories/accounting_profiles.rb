require_relative '../../lib/accounting/test/create_card'

FactoryGirl.define do
  factory :accounting_profile, class: 'Accounting::Profile' do
    authnet_id { SecureRandom.uuid[0..19] }
    authnet_email { FFaker::Internet.email }
    authnet_description { FFaker::Lorem.sentence(2) }

    trait :with_all_cards do
      transient do
        card_numbers ['370000000000002', '6011000000000012', '3088000000000017', '4007000000027', '5424000000000015']
      end

      after :create do |profile, evaluator|
        evaluator.card_numbers.each do |number|
          payment = FactoryGirl.build(:accounting_payment, :with_card, profile: profile, number: number)
          payment.save
          profile.payments << payment
        end
      end
    end

    trait :with_payment do
      transient do
        payment_count 1
      end

      after :create do |profile, evaluator|
        evaluator.payment_count.times do
          payment = FactoryGirl.build(:accounting_payment, :with_card, profile: profile)
          payment.save
          profile.payments << payment
        end
      end
    end
  end
end
