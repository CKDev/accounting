FactoryGirl.define do
  factory :accounting_transaction, class: 'Accounting::Transaction' do
    transaction_id "MyString"
    transaction_type "MyString"
    transaction_method "MyString"
    auth_code "MyString"
    accountable nil
  end
end
