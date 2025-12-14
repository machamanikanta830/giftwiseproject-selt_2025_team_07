class AddUnitPriceToCartItems < ActiveRecord::Migration[7.1]
  def change
    add_column :cart_items, :unit_price, :decimal, precision: 10, scale: 2
  end
end
