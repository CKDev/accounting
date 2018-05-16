FactoryGirl.define do
  factory :accounting_address, class: 'Accounting::Address' do
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    company { FFaker::Company.name }
    street_address { FFaker::AddressUS.street_address }
    city { FFaker::AddressUS.city }
    state { FFaker::AddressUS.state }
    zip { FFaker::AddressUS.zip_code }
    country { FFaker::AddressUS.country_code }
    phone { FFaker::PhoneNumber.phone_number }
    fax { FFaker::PhoneNumber.phone_number }

    trait :with_payment do
      payment { FactoryGirl.build(:accounting_payment, :with_card, address: address) }
    end

    trait :with_address_id do
      address_id { rand(1000..9999) }
    end
  end
end
