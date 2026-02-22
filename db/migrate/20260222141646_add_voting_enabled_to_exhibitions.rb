class AddVotingEnabledToExhibitions < ActiveRecord::Migration[8.1]
  def change
    add_column :exhibitions, :voting_enabled, :boolean, default: false, null: false
  end
end
