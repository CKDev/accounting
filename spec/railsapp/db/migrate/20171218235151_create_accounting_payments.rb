class CreateAccountingPayments < ActiveRecord::Migration[5.1]
  def change
    create_table :accounting_payments do |t|
      t.integer :profile_id
      t.integer :payment_profile_id
      t.string :title
      t.string :last_four
      t.date :expiration
      t.string :profile_type
      t.boolean :default, null: false, default: false

      t.timestamps null: false
    end

    add_index :accounting_payments, :payment_profile_id, unique: true
  end
end
