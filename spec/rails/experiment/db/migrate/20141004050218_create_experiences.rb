class CreateExperiences < ActiveRecord::Migration
  def change
    create_table :experiences do |t|
      t.text :impression

      t.timestamps
    end
  end
end
