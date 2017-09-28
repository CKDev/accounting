require 'ffaker'
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

@user = User.create(name: FFaker::Name.name, email: FFaker::Internet.email)
# @address1 = @user.addresses.create!(first_name: FFaker::Name.first_name, last_name: FFaker::Name.last_name, street_address: FFaker::Address.street_address, city: FFaker::Address.city, state: FFaker::AddressUS.state, zip: FFaker::AddressUS.zip_code)
# @address2 = @user.addresses.create!(first_name: FFaker::Name.first_name, last_name: FFaker::Name.last_name, street_address: FFaker::Address.street_address, city: FFaker::Address.city, state: FFaker::AddressUS.state, zip: FFaker::AddressUS.zip_code)
@user.payments.create!(profile_type: :card, number: '4012888818888', ccv: 123, month: 5, year: 2020, address_attributes: { first_name: FFaker::Name.first_name, last_name: FFaker::Name.last_name, street_address: FFaker::Address.street_address, city: FFaker::Address.city, state: FFaker::AddressUS.state, zip: FFaker::AddressUS.zip_code })
@user.payments.create!(profile_type: :card, number: '6011000000000012', ccv: 123, month: 2, year: 2018, address_attributes: { first_name: FFaker::Name.first_name, last_name: FFaker::Name.last_name, street_address: FFaker::Address.street_address, city: FFaker::Address.city, state: FFaker::AddressUS.state, zip: FFaker::AddressUS.zip_code })
@user.payments.create!(profile_type: :ach, routing: 124000054, account: [*1000000..4000000].sample, bank_name: FFaker::Name.name, account_holder: FFaker::Name.name, account_type: ['checking', 'savings'].sample, address_attributes: { first_name: FFaker::Name.first_name, last_name: FFaker::Name.last_name, street_address: FFaker::Address.street_address, city: FFaker::Address.city, state: FFaker::AddressUS.state, zip: FFaker::AddressUS.zip_code })
@user.payments.create!(profile_type: :ach, routing: 124000054, account: [*1000000..4000000].sample, bank_name: FFaker::Name.name, account_holder: FFaker::Name.name, account_type: ['checking', 'savings'].sample, address_attributes: { first_name: FFaker::Name.first_name, last_name: FFaker::Name.last_name, street_address: FFaker::Address.street_address, city: FFaker::Address.city, state: FFaker::AddressUS.state, zip: FFaker::AddressUS.zip_code })
# @user.subscribe!(FFaker::Lorem.sentence, [*10..100].sample, [*1..9].sample, @user.payments.default)
puts @user.name, @user.email