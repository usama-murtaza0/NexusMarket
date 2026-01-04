class Order < ApplicationRecord
  acts_as_tenant :tenant

  belongs_to :tenant
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_one :platform_fee, dependent: :destroy

  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending completed cancelled] }

  PLATFORM_FEE_PERCENTAGE = 0.05 # 5%

  def calculate_platform_fee
    total_amount * PLATFORM_FEE_PERCENTAGE
  end

  def create_platform_fee!
    fee_amount = calculate_platform_fee
    PlatformFee.create!(
      order: self,
      tenant: tenant,
      amount: fee_amount
    )
  end
end
