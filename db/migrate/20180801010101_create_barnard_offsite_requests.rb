class CreateBarnardOffsiteRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :barnard_offsite_requests do |t|

      t.timestamps null: false
    end
  end
end
