FactoryBot.define do
  factory :user, class: 'User' do

    email { FFaker::Internet.email }
    name { FFaker::Name.name }

    trait :with_payment do
      transient do
        numbers { ['370000000000002', '6011000000000012', '3088000000000017', '4111111111111111', '5424000000000015'] }
        payments { 1 }
      end

      after :create do |user, evaluator|
        evaluator.payments.times do
          payment = FactoryBot.build(:accounting_payment, :with_card, profile: user.profile)
          payment.save
          user.payments << payment
        end
      end
    end

    trait :with_transactions do
      after :create do |user, evaluator|
        VCR.use_cassette(:valid_hold, record: :new_episodes) { user.hold(1.00, user.payments.default).process_now! }

        VCR.use_cassette(:valid_charge, record: :new_episodes) { user.charge(1.00, user.payments.default).process_now! }

        VCR.use_cassette(:valid_void, record: :new_episodes) { user.void(user.transactions.charges.last).process_now! }

        # Refund fails here because settled transactions can be refunded only the next day
        # VCR.use_cassette(:valid_refund, record: :new_episodes) { user.refund(1.00, user.transactions.captured.last, user.payments.default).process_now }

        VCR.use_cassette(:valid_capture, record: :new_episodes) { user.capture(user.transactions.holds.last).process_now! }
      end
    end

  end
end
