class CreateAccountingProfiles < ActiveRecord::Migration[5.1]
  def change
    create_table :accounting_profiles do |t|
      t.string :authnet_id
      t.string :authnet_email
      t.string :authnet_description
      t.integer :profile_id
      t.references :accountable, polymorphic: true, index: { name: 'index_accounting_profiles_on_accountable_type_and_id' }

      t.timestamps null: false
    end

    add_index :accounting_profiles, :profile_id, unique: true
  end
end
