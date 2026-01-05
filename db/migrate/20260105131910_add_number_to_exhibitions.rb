class AddNumberToExhibitions < ActiveRecord::Migration[8.1]
  def change
    add_column :exhibitions, :number, :integer
    add_index :exhibitions, :number, unique: true

    # Set existing exhibitions to have numbers based on their order
    reversible do |dir|
      dir.up do
        Exhibition.order(:created_at).each_with_index do |exhibition, index|
          exhibition.update_column(:number, index + 1)
        end
      end
    end
  end
end
