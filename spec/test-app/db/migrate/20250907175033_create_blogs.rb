class CreateBlogs < ActiveRecord::Migration[8.0]
  def change
    create_table :blogs do |t|
      t.string :title
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
