class Setting < ApplicationRecord
  # Associations
  belongs_to :exhibition, optional: true

  # Validations
  validates :key, presence: true
  validates :key, uniqueness: { scope: [:exhibition_id, :setting_type] }
  validates :setting_type, inclusion: { in: %w[global exhibition] }

  # Scopes
  scope :global_settings, -> { where(setting_type: 'global', exhibition_id: nil) }
  scope :for_exhibition, ->(exhibition) { where(exhibition: exhibition, setting_type: 'exhibition') }

  # Class methods for easy access to settings
  def self.get_value(key, exhibition = nil)
    if exhibition
      # First try exhibition-specific setting
      setting = for_exhibition(exhibition).find_by(key: key)
      return setting.value if setting
    end

    # Fall back to global setting
    global_settings.find_by(key: key)&.value
  end

  def self.set_value(key, value, exhibition = nil, setting_type = 'global')
    if exhibition
      setting = find_or_initialize_by(key: key, exhibition: exhibition, setting_type: 'exhibition')
    else
      setting = find_or_initialize_by(key: key, setting_type: setting_type, exhibition_id: nil)
    end

    setting.value = value.to_s
    setting.save
  end

  # Legacy methods (global settings only)
  def self.voting_deadline
    global_settings.find_by(key: "voting_deadline")&.value&.to_datetime || DateTime.new(2025, 1, 8, 23, 59, 59)
  end

  def self.voting_open?
    Time.current < voting_deadline
  end

  def self.results_intro
    global_settings.find_by(key: "results_intro")&.value || "Bekijk de definitieve ranking van de kunstwerken."
  end
end
