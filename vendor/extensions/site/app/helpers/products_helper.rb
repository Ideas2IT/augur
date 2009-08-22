module ProductsHelper
  # returns the price of the product to show for display purposes
  def product_price(product_or_variant, options={})
    options.assert_valid_keys(:format_as_currency)
    options.reverse_merge! :format_as_currency => true
    
    amount = product_or_variant.is_a?(Product) ? product_or_variant.master_price : product_or_variant.price

    options[:format_as_currency] ? format_price(amount, options) : amount
  end
  
  # returns the formatted change in price (from the master price) for the specified variant (or simply return 
  # the variant price if no master price was supplied)
  def variant_price_diff(variant)
    return product_price(variant) unless variant.product.master_price
    diff = product_price(variant, :format_as_currency => false) - product_price(variant.product, :format_as_currency => false)
    return nil if diff == 0
    if diff > 0
      "(#{t("add")}: #{format_price diff.abs})"
    else
      "(#{t("subtract")}: #{format_price diff.abs})"
    end
  end
  
  def format_price(price)      
    # Don't be fooled - default implementation uses number_to_currency but other extensions may patch into this.  It is
    # suggested that you leave your format_price calls alone.
    number_to_currency(price)
  end
  
  # converts line breaks in product description into <p> tags (for html display purposes)
  def product_description(product)
    product.description.gsub(/^(.*)$/, '<p>\1</p>')
  end  
  
  # generates nested url to product based on supplied taxon
  def seo_url(taxon, product = nil)
    return '/t/' + taxon.permalink if product.nil?
    
    '/t/' + taxon.permalink + "p/" + product.permalink
  end
  
  def show_text_available(product)
    if product.product_stores.size == 0
      available = "Not Available"
    elsif product.product_stores.size >= 1
      available = "Available at "
    end
    return available
  end
  
  def show_text_store(product)
    if product.product_stores.size == 1 
      store = "store"
    elsif product.product_stores.size > 1
      store = "stores"
    end
    return store
  end
  
  def starting_price(product)
    price = ProductStore.find(:first , :conditions => ['product_id = ?' , product.id],:order => 'price asc')
    return price
  end
  
  def check_feature_available(product,feature)
    product_property = ProductProperty.find(:first,:conditions => ['product_id = ? and property_id = ?' , product.id , feature.id]) 
    if product_property.nil?
      return false
    else
      return true
    end
  end
  
end
