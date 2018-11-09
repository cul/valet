class Logs < ActiveRecord::Migration[5.2]

  def change

    create_table :logs do |t|

      # request data
      t.text :user_agent, null: true
      t.string :browser_name, null: true
      t.string :browser_version, null: true
      t.text :referrer, null: true
      t.string :remote_ip, null: true

      # log data
      t.string :set, null: false
      t.text :logdata, null: true

      t.timestamps null: false

    end

  end

end

