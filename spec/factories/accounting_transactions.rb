FactoryBot.define do
  factory :accounting_transaction, class: 'Accounting::Transaction' do
    transaction_id { "MyString" }
    transaction_type { "auth_capture" }
    transaction_method { "MyString" }
    authorization_code { "MyString" }
  end
end
