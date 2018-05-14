FactoryGirl.define do
  factory :accounting_payment, class: 'Accounting::Payment' do
    title FFaker::Lorem.sentence(2)
    profile { FactoryGirl.create(:accounting_profile) }
    last_four { [*1000..9999].sample.to_s }
    profile_type 'card'

    transient do
      card_numbers ['370000000000002', '6011000000000012', '3088000000000017', '4007000000027', '5424000000000015']
      routing_numbers ['102003154', '272477694', '231386137', '102006025', '102102864', '102105353', '102189324']
    end

    after :build do |payment|
      unless payment.address.present?
        payment.address = FactoryGirl.build(:accounting_address, payment: payment)
      end
    end

    trait :with_card do
      profile_type 'card'
      number { card_numbers.sample }
      ccv { number == '370000000000002' ? 1234 : 123 }
      month { Time.now.month }
      year { Time.now.year + [*1..5].sample }
    end

    trait :with_ach do
      profile_type 'ach'
      routing { routing_numbers.sample }
      account { [*1000000..9999999].sample }
      bank_name { FFaker::Company.name }
      account_holder { FFaker::Name.name }
      account_type { ['checking', 'savings'].sample }
      check_number { [*1000..9999].sample }
    end

    trait :with_card_opaque_data do
      accept true
      profile_type 'card'
      month { Time.now.month }
      year { Time.now.year + [*1..5].sample }
    end

    trait :with_ach_opaque_data do
      accept true
      profile_type 'ach'
    end

    trait :default do
      default true
    end
  end
end
