class AddDeletedAtToAccountingPayments < ActiveRecord::Migration[5.1]
  def change
    add_column :accounting_payments, :deleted_at, :datetime
    add_index :accounting_payments, :deleted_at
  end
end
