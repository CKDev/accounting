require_relative '../../lib/accounting/test/create_card'

FactoryGirl.define do
  factory :accounting_payment, class: 'Accounting::Payment' do
    title ['American Express', 'Discover', 'JCB', 'Visa', 'MasterCard'].sample
    profile { FactoryGirl.create(:accounting_profile) }
    last_four { [*1000..9999].sample.to_s }
    profile_type 'card'

    transient do
      card_numbers ['370000000000002', '6011000000000012', '3088000000000017', '4007000000027', '5424000000000015']
      routing_numbers ['102003154', '272477694', '231386137', '102006025', '102102864', '102105353', '102189324']
      number { card_numbers.sample }
      address { FactoryGirl.build(:accounting_address) }
    end

    after :build do |payment|
      if payment.address.blank?
        payment.address = FactoryGirl.build(:accounting_address, payment: payment)
      end
    end

    trait :with_card do
      initialize_with do
        Accounting::Test::CreateCard.new(
          profile,
          number,
          number == '370000000000002' ? 1234 : 123,
          nil,
          nil,
          address
        ).create_payment
      end
    end

    trait :with_ach do
      profile_type 'ach'
      routing { routing_numbers.sample }
      account { [*1_000_000..9_999_999].sample }
      bank_name { FFaker::Company.name }
      account_holder { FFaker::Name.name }
      account_type { ['checking', 'savings'].sample }
      check_number { [*1000..9999].sample }
    end

    trait :default do
      default true
    end

  end
end
