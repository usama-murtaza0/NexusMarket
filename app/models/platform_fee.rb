class PlatformFee < ApplicationRecord
  belongs_to :order
  belongs_to :tenant

  validates :amount, presence: true, numericality: { greater_than: 0 }

  # Platform fees are NOT tenant-scoped - they're global
  # We don't use acts_as_tenant here
end
