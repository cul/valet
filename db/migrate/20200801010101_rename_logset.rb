class RenameLogset < ActiveRecord::Migration[5.2]
  def change
    rename_column :logs, :set, :logset
  end
end
