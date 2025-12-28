class Setting < ApplicationRecord
  # Validations
  validates :key, presence: true, uniqueness: true

  # Class methods for easy access to settings
  def self.voting_deadline
    find_by(key: "voting_deadline")&.value&.to_datetime || DateTime.new(2025, 1, 8, 23, 59, 59)
  end

  def self.voting_open?
    Time.current < voting_deadline
  end

  def self.results_intro
    find_by(key: "results_intro")&.value || "Bekijk de definitieve ranking van de 52 kunstwerken."
  end

  def self.set_value(key, value)
    setting = find_or_initialize_by(key: key)
    setting.value = value.to_s
    setting.save
  end
end
