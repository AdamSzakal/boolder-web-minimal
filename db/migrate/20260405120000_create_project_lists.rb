class CreateProjectLists < ActiveRecord::Migration[8.0]
  def change
    create_table :project_lists do |t|
      t.string :slug, null: false
      t.string :name
      t.integer :problem_ids, array: true, default: [], null: false

      t.timestamps
    end

    add_index :project_lists, :slug, unique: true
  end
end
