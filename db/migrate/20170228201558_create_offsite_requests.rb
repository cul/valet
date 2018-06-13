class CreateOffsiteRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :offsite_requests do |t|

      t.timestamps null: false
    end
  end
end
