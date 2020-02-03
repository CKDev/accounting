# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20200203150438) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounting_addresses", force: :cascade do |t|
    t.integer "payment_id"
    t.string "address_id"
    t.string "first_name"
    t.string "last_name"
    t.string "company"
    t.string "street_address"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "country"
    t.string "phone"
    t.string "fax"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "accounting_payments", force: :cascade do |t|
    t.integer "profile_id"
    t.integer "payment_profile_id"
    t.string "title"
    t.string "last_four"
    t.date "expiration"
    t.integer "profile_type"
    t.boolean "default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_accounting_payments_on_deleted_at"
    t.index ["payment_profile_id"], name: "index_accounting_payments_on_payment_profile_id", unique: true
  end

  create_table "accounting_profiles", force: :cascade do |t|
    t.string "authnet_id"
    t.string "authnet_email"
    t.string "authnet_description"
    t.integer "profile_id"
    t.string "accountable_type"
    t.bigint "accountable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["accountable_type", "accountable_id"], name: "index_accounting_profiles_on_accountable_type_and_id"
    t.index ["profile_id"], name: "index_accounting_profiles_on_profile_id", unique: true
  end

  create_table "accounting_subscriptions", force: :cascade do |t|
    t.integer "profile_id"
    t.integer "payment_id"
    t.string "job_id"
    t.string "subscription_id"
    t.string "name"
    t.text "description"
    t.string "unit"
    t.integer "length"
    t.datetime "start_date"
    t.integer "total_occurrences"
    t.integer "trial_occurrences"
    t.decimal "amount", precision: 16, scale: 4
    t.decimal "trial_amount", precision: 16, scale: 4
    t.string "invoice_number"
    t.datetime "submitted_at"
    t.integer "status", default: 0
    t.datetime "next_transaction_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subscription_id"], name: "index_accounting_subscriptions_on_subscription_id", unique: true
  end

  create_table "accounting_transactions", force: :cascade do |t|
    t.integer "profile_id"
    t.integer "payment_id"
    t.string "job_id"
    t.string "transaction_id"
    t.string "transaction_type"
    t.string "transaction_method"
    t.integer "original_transaction_id"
    t.string "authorization_code"
    t.string "avs_response"
    t.decimal "amount", precision: 16, scale: 4
    t.integer "status", default: 0
    t.text "options"
    t.datetime "submitted_at"
    t.integer "subscription_id"
    t.integer "subscription_payment"
    t.boolean "settled", default: false
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
