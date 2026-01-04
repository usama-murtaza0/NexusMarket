class ShopOwner::ProductsController < ApplicationController
  before_action :require_shop_owner

  expose :products, -> { Product.all }
  expose :product

  def create
    product = Product.new(product_params)
    if product.save
      redirect_to shop_owner_products_path, notice: 'Product created successfully'
    else
      render :new, status: :unprocessable_entity
    end
  end


  def update
    if product.update(product_params)
      redirect_to shop_owner_products_path, notice: 'Product updated successfully'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    product.destroy
    redirect_to shop_owner_products_path, notice: 'Product deleted successfully'
  end

  private

  def product_params
    params.require(:product).permit(:name, :price, :stock_quantity)
  end
end
