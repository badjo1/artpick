class CheckIn < ApplicationRecord
  # Associations
  belongs_to :checkable, polymorphic: true
  belongs_to :user, optional: true
  belongs_to :voting_session, optional: true
  belongs_to :exhibition, optional: true
  belongs_to :screen, optional: true

  # Validations
  validates :action_type, presence: true

  # Constants
  ACTIONS = %w[view vote favorite share comparison_start comparison_complete].freeze

  validates :action_type, inclusion: { in: ACTIONS }

  # Scopes
  scope :for_exhibition, ->(exhibition) { where(exhibition: exhibition) }
  scope :by_action, ->(action) { where(action_type: action) }
  scope :recent, ->(days = 7) { where("created_at >= ?", days.days.ago) }
  scope :today, -> { where("created_at >= ?", Time.zone.now.beginning_of_day) }

  # Class method for easy logging
  def self.log(action_type, checkable, context = {})
    create!(
      action_type: action_type,
      checkable: checkable,
      user: context[:user],
      voting_session: context[:voting_session],
      exhibition: context[:exhibition],
      screen: context[:screen],
      ip_address: context[:ip_address],
      user_agent: context[:user_agent],
      metadata: context[:metadata] || {}
    )
  rescue => e
    # Log error but don't fail the operation
    Rails.logger.error("Failed to create check-in: #{e.message}")
    nil
  end
end
