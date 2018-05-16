FactoryGirl.define do
  factory :user, class: 'User' do

    profile { FactoryGirl.create(:accounting_profile, :with_all_cards) }
    email { FFaker::Internet.email }
    name { FFaker::Name.name }

    trait :with_payment do
      transient do
        numbers ['370000000000002', '6011000000000012', '3088000000000017', '4111111111111111', '5424000000000015']
        payments 1
      end

      before :create do |user, evaluator|
        evaluator.payments.times do
          payment = FactoryGirl.build(:accounting_payment, :with_card, profile: user.profile)
          payment.save
          user.payments << payment
        end
      end
    end

    trait :with_transactions do
      after :create do |user, evaluator|
        user.hold(1.00, user.payments.default).save!
        VCR.use_cassette(:valid_hold, record: :new_episodes) { user.transactions.holds.map(&:process_now!) }

        user.charge(1.00, user.payments.default).save!
        VCR.use_cassette(:valid_charge, record: :new_episodes) { user.transactions.charges.map(&:process_now!) }

        user.void(user.transactions.charges.last).save!
        VCR.use_cassette(:valid_void, record: :new_episodes) { user.transactions.voids.map(&:process_now!) }

        user.refund(1.00, user.transactions.captured.last, user.payments.default).save!
        VCR.use_cassette(:valid_refund, record: :new_episodes) { user.transactions.refunds.map(&:process_now!) }

        user.capture(user.transactions.holds.last).save!
        VCR.use_cassette(:valid_capture, record: :new_episodes) { user.transactions.captures.map(&:process_now!) }
      end
    end
  end
end
