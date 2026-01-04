class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :tenant, optional: true
  has_many :orders, dependent: :destroy

  # Set default role to customer for new users
  after_initialize :set_default_role, if: :new_record?

  validates :role, presence: true, inclusion: { in: %w[super_admin shop_owner customer] }
  validate :tenant_required_for_shop_owner

  def super_admin?
    role == 'super_admin'
  end

  def shop_owner?
    role == 'shop_owner'
  end

  def customer?
    role == 'customer'
  end

  private

  def set_default_role
    self.role ||= 'customer'
  end

  def tenant_required_for_shop_owner
    if role == 'shop_owner' && tenant_id.nil?
      errors.add(:tenant_id, "is required for Shop Owner users")
    end
  end
end
