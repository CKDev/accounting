class CreateAccountingTransactions < ActiveRecord::Migration[5.1]
  def change
    create_table :accounting_transactions do |t|
      t.integer :profile_id
      t.integer :payment_id
      t.string :job_id
      t.string :transaction_id
      t.string :transaction_type
      t.string :transaction_method
      t.integer :original_transaction_id
      t.string :authorization_code
      t.string :avs_response
      t.decimal :amount, precision: 16, scale: 4
      t.integer :status, default: 0
      t.text :options
      t.datetime :submitted_at
      t.integer :subscription_id
      t.integer :subscription_payment
      t.boolean :settled, default: false

      t.timestamps
    end

    # add_index :accounting_transactions, :transaction_id, unique: true
  end
end
