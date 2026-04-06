class EnablePostgis < ActiveRecord::Migration[8.0]
  def up
    execute "CREATE EXTENSION IF NOT EXISTS postgis"
  end

  def down
    execute "DROP EXTENSION IF EXISTS postgis"
  end
end
