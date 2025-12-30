class UpdateSettingsForExhibitions < ActiveRecord::Migration[8.1]
  def change
    add_reference :settings, :exhibition, foreign_key: true
    add_column :settings, :setting_type, :string, default: 'global'
  end
end
