require 'rubygems'
require 'active_record'
require 'active_record/fixtures'



DATA_DIRECTORY = File.join(RAILS_ROOT, "lib", "tasks", "scrap")

namespace :scrap do
  desc "Scraping used cars details from the car wale site "   
  task :load_ctgy_spoteazy => :environment do
    scrap_ctgy_spot_eazy    
  end
  task :load_products => :environment do    
    taxons = Taxon.find(:all)
    taxons.each do |taxon|
      puts taxon.name
      scrap_products_spot_eazy(taxon.name)  
    end    
  end
end

def scrap_ctgy_spot_eazy
  require "rexml/document"
  require 'scrubyt'
  
  Scrubyt.logger = Scrubyt::Logger.new
  Hpricot.buffer_size = 204800 
  include REXML  
  Scrubyt.logger = Scrubyt::Logger.new
      categories = Scrubyt:: Extractor.define do        
          fetch 'http://www.spoteazy.com/'
          cat_row "//div[@class='browsebycaterow']" do 
              cat_col "//div[@class='browsebycatecol']" do 
                category_head "//div[@class='browsecatehead']"
                child_category "//div[@class='browsecatecontent']" do 
                  category_name "//a"
                end
              end  
          end
  end
  puts categories.class
 categories_s = categories.to_xml
categories_s = categories_s.gsub('&', '')
 categories_document = REXML::Document.new categories_s
   categories_document.elements.each("root/cat_row/cat_col") { |element|
      category_head  = element.elements['category_head'].text
      save_taxon(category_head, 'Categories')
      element.elements.each("child_category/category_name") {|child_ctgy|
        child_ctgy_name = child_ctgy.text
        child_ctgy_name = child_ctgy_name.gsub(",","")
        save_taxon(child_ctgy_name, category_head)
      }        
  }
  return categories
end

def save_taxon(name, parent_name)
 parent = Taxon.find_by_name(parent_name)
 @taxon = Taxon.find_by_name_and_parent_id(name, parent.id)
 @taxon = Taxon.new if @taxon.nil? 
 @taxon.name= name
 @taxon.parent_id = parent.id unless parent.nil?
 @taxon.taxonomy = Taxonomy.find_by_name("Categories")
 @taxon.position = parent.children.length unless parent.nil?
 @taxon.save
 puts "#{@taxon.name} saved successfully"
end  

def scrap_products_spot_eazy(taxon_name) 
  require 'scrubyt'
  require "rexml/document"
  include REXML 
  Scrubyt.logger = Scrubyt::Logger.new
      categories = Scrubyt:: Extractor.define do
          fetch 'http://www.spoteazy.com/'
          fill_textfield "q", taxon_name
          submit
          prod_container "//div[@class='bdyrightcontainer']"  do
              product "//div[1]/a" do
                product_detail  do
                    prod_body "//html/body/div/div[7]" do
                        name "//div/div/h1"
                        image_url "//div[3]/img" do
                          url 'src' , :type=> :attribute
                        end 
                        price "//div[5]/div[2]/div[2]/span" 
                        description "//div[5]/div[2]/div[4]/span" 
                        product_store_url "//div[5]/div[2]/div[3]/a"  do
                          url 'href' , :type=> :attribute
                        end
                        store_url "//div[5]/div[2]/div[3]/a/img"  do
                          url 'src' , :type=> :attribute
                          name'alt' , :type=> :attribute
                        end 
                    end
                 end  
              end
          end  
         #next_page "next >>"
  end
  categories_s = categories.to_xml
  puts categories_s
  categories_s = categories_s.gsub("&", "&amp;")
  
  categories_document = REXML::Document.new categories_s
   categories_document.elements.each("root/prod_container/product/prod_body") { |element|
      product_name  = element.elements['name'].text unless element.elements['name'].nil?
      price  = element.elements['price'].text  unless element.elements['price'].nil?
      description  = element.elements['description'].text unless element.elements['description'].nil?
      product_img_url = "";
      element.elements.each('image_url')  {|img_element|
          product_img_url = img_element.elements['url'].text
          product_img_url = product_img_url.gsub("&amp;", "&")
      }
      product_store_url = "";
      element.elements.each('product_store_url')  {|store_element|          
          product_store_url = store_element.elements['url'].text
          product_store_url = product_store_url.gsub("&amp;", "&")          
          product_store_url_arr= product_store_url.split(",");
          product_store_url =  product_store_url_arr[1].gsub("'","")
          product_store_url =  product_store_url.gsub(");","")          
      }
      store_name = "";
      store_image_url = "";
      element.elements.each('store_url')  {|store_element|
          store_image_url = store_element.elements['url'].text
          store_image_url = store_image_url.gsub("&amp;", "&")
          store_name = store_element.elements['name'].text    
      }
      save_product(product_name ,description, price, taxon_name, product_img_url, store_name,store_image_url, product_store_url)
    }
end

def save_product(product_name, description ,price , taxon_name,product_img_url, store_name, store_url, product_store_url)
 @taxon = Taxon.find_by_name(taxon_name) 
 unless price.nil?
   prices = price.split(' ') 
   price = prices[1]
 end 
 @product = Product.find_by_name(product_name)
 @product = Product.new if @product.nil? 
 if @product.variants.empty?
    @product.available_on = Time.now
    @product.variants << Variant.new(:product => @product)
 end
 @product.name= product_name
 @product.description = description
 if price.nil? 
   @product.master_price = 0.0
 else  
   @product.master_price = price.to_d
 end 
 @product.taxons << @taxon 
 @store = Store.find_by_name(store_name)
 @store = Store.new if @store.nil? 
 @store.name = store_name
 @store.image_url = store_url
 @store.save 
 @product.save
 
 @product_stores = ProductStore.find_by_product_id_and_store_id(@product.id, @store.id)
 @product_stores = ProductStore.new if @product_stores.nil? 
 @product_stores.store = @store
 @product_stores.product = @product
 @product_stores.description_url = product_store_url
 @product_stores.save
 @product.product_stores << @product_stores
 @product.save
 
 #delete old image of products
 @product.images.destroy_all
 @product.save
 
 @image = Image.new
 @image.viewable_type= "product"
 @image.viewable_id= @product.id
 @image.attachment_file_name= product_img_url
 @image.attachment_content_type = "image/jpg"
 @image.save
 
 puts "#{@product.name} saved successfully"
end 