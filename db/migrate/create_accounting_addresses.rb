class CreateAccountingAddresses < ActiveRecord::Migration[5.1]
  def change
    create_table :accounting_addresses do |t|
      t.integer :payment_id
      t.string :address_id
      t.string :first_name
      t.string :last_name
      t.string :company
      t.string :street_address
      t.string :city
      t.string :state
      t.string :zip
      t.string :country
      t.string :phone
      t.string :fax

      t.timestamps
    end
  end
end
