class ProductsController < Spree::BaseController
  def compare
    @products = []
    @features = []
    products = params[:product_compare]
    products.each do |product|
      product = Product.find(product)
      @products << product
      product.properties.each do |feature|
        @features << feature
      end  
    end
    @products = @products.uniq
    @features = @features.uniq
  end
end