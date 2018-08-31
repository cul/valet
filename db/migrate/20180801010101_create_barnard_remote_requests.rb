class CreateBarnardRemoteRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :barnard_remote_requests do |t|

      t.timestamps null: false
    end
  end
end
