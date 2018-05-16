FactoryGirl.define do
  factory :accounting_payment, class: 'Accounting::Payment' do
    title ['American Express', 'Discover', 'JCB', 'Visa', 'MasterCard'].sample
    profile { FactoryGirl.create(:accounting_profile) }
    last_four { [*1000..9999].sample.to_s }
    profile_type 'card'

    transient do
      routing_numbers ['102003154', '272477694', '231386137', '102006025', '102102864', '102105353', '102189324']
    end

    after :build do |payment|
      unless payment.address.present?
        payment.address = FactoryGirl.build(:accounting_address, payment: payment)
      end
    end

    trait :with_card do
      profile_type 'card'
      month { Time.now.month }
      year { Time.now.year + [*1..5].sample }
      payment_profile_id { [*1825701..1825800].sample }
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

    trait :default do
      default true
    end

  end
end
