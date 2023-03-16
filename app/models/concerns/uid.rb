# frozen_string_literal: true

module Uid
  extend ActiveSupport::Concern

  included do
    before_validation :generate_uid, on: :create
    validates :uid,
              presence: true,
              uniqueness: {case_sensitive: false}
  end

  private

  def generate_uid
    return if uid.present?

    self.uid = loop do
      uuid = SecureRandom.uuid
      break uuid unless self.class.exists?(uid: uuid)
    end
  end
end
