class Product < ApplicationRecord
  acts_as_tenant :tenant

  belongs_to :tenant
  has_many :order_items, dependent: :destroy

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :stock_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :in_stock, -> { where('stock_quantity > 0') }

  def available?
    stock_quantity > 0
  end

  def decrease_stock(quantity)
    with_lock do
      if stock_quantity >= quantity
        decrement!(:stock_quantity, quantity)
        true
      else
        false
      end
    end
  end
end
