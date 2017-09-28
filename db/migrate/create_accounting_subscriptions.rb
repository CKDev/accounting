class CreateAccountingSubscriptions < ActiveRecord::Migration[5.1]
  def change
    create_table :accounting_subscriptions do |t|
      t.integer :profile_id
      t.integer :payment_id
      t.string :job_id
      t.string :subscription_id
      t.string :name
      t.text :description
      t.string :unit
      t.integer :length
      t.datetime :start_date
      t.integer :total_occurrences
      t.integer :trial_occurrences
      t.decimal :amount, precision: 16, scale: 4
      t.decimal :trial_amount, precision: 16, scale: 4
      t.string :invoice_number
      t.datetime :submitted_at
      t.integer :status, default: 0
      t.datetime :next_transaction_at

      t.timestamps
    end

    add_index :accounting_subscriptions, :subscription_id, unique: true
  end
end
