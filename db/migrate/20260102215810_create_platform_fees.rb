class CreatePlatformFees < ActiveRecord::Migration[8.0]
  def change
    create_table :platform_fees do |t|
      t.references :order, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false

      t.timestamps
    end
  end
end
