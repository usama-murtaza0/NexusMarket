class MakeTenantIdOptionalInUsers < ActiveRecord::Migration[8.0]
  def change
    change_column_null :users, :tenant_id, true
  end
end
