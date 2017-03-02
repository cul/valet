class CreateOffsiteRequests < ActiveRecord::Migration
  def change
    create_table :offsite_requests do |t|

      t.timestamps null: false
    end
  end
end
