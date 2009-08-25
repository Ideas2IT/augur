require 'rubygems'
require 'active_record'
require 'active_record/fixtures'
DATA_DIRECTORY = File.join(RAILS_ROOT, "lib", "tasks", "scrap")
STORE_NAME ="Viveks"
STORE_URL = ""
ROOT_CTGY_NAME = "Categories"
namespace :scrap do
  desc "Scraping used cars details from the car wale site "   
  task :load_products_viveks=> :environment do
     #load_products('http://www.viveks.com/Category/36-air-conditioners.aspx', 'Home Appliances')
    ctgy_ids = getRootCtgys
    ctgy_ids.each do |key, value| 
      scrap_sub_ctgy_products(key, value)
    end

  end
end
def scrap_sub_ctgy_products(ctgy_name, sub_ctgy_id)
  Hpricot.buffer_size = 204800
  Scrubyt.logger = Scrubyt::Logger.new
    ctgy= Scrubyt:: Extractor.define do
      fetch 'http://www.viveks.com/default.aspx'    
      categories "//table[@id='#{sub_ctgy_id}']" do
          ctgy_links "//a" do
             ctgy_url 'href', :type=>:attribute           
          end     
      end           
    end
    puts ctgy.to_xml
    ctgy_s = ctgy.to_xml
    save_taxon(ctgy_name, ROOT_CTGY_NAME)
    ctgy_document = REXML::Document.new ctgy_s  
    ctgy_document.elements.each("root/categories/ctgy_links")  {|element|
      ctgy_url = element.elements['ctgy_url'].text
      load_products(ctgy_url, ctgy_name)
    }
end 

def load_products(ctgy_url, parent_taxon_name) 
     Hpricot.buffer_size = 204800
    Scrubyt.logger = Scrubyt::Logger.new
    produts = Scrubyt:: Extractor.define do     
    fetch ctgy_url
      categories "//td[@class='pR5']" do
          sub_ctgy_name  "//table/tr[1]/td/h1/a"        
          sub_ctgy "//table/tr[2]/td/a" do
              ctgy_details do
                  products_cols "//td[@class='pR15']" do       
                   product "/table/tr/td/div/div/a"  do          
                      product_detail do                     
                        specification "//table[@id='ctl00_cph1_ctl00_ctrlProductInfo_dlstFeatures']" do
                          spec_det "/tr" do
                            property_dim_name "/td/table/tr[1]/td[1]"
                            properties "/td/table/tr[2]/td/table"  do
                                name "/tr"
                             end
                          end
                        end
                        prod_main "//td[@class='innerCSSingleColWitBrScrum']" do
                          name "/table/tr/td/table/tr[1]/td/table/tr[1]/td[1]"              
                          imageurl "//img[@id ='ctl00_cph1_ctl00_ctrlProductInfo_defaultImage']" do
                               url 'src' , :type=> :attribute
                          end
                          price "//span[@id='ctl00_cph1_ctl00_ctrlProductInfo_lblPrice']"   
                        end  
                      end
                    product_store_url 'href',:type=>:attribute
                   end  
                end
              end  
           end 
      end 
    end    
    prodcuts_s = produts.to_xml  
    prodcuts_document = REXML::Document.new prodcuts_s  
    prodcuts_document.elements.each("root/categories") { |element|
      sub_ctgy_name  = element.elements['sub_ctgy_name'].text      
      #save the sub category
      save_taxon(sub_ctgy_name, parent_taxon_name)
      properties_array = Array.new    
      element.elements.each('sub_ctgy/products_cols/product') {|product_doc|
        product_name ="";
        product_image_url=""
        product_price=""
        product_store_url = product_doc.elements['product_store_url'].text
        product_doc.elements.each('prod_main')  {|prodoct_deatil|
          product_name= prodoct_deatil.elements['name'].text         
          product_image_url=prodoct_deatil.elements['imageurl'].elements['url'].text 
          product_price = prodoct_deatil.elements['price'].text        
        }
        product_properties = Hash.new
        product_doc.elements.each('specification/spec_det')  {|prodoct_spec_deatil|
          prop_heading_name = prodoct_spec_deatil.elements['property_dim_name'].text
          prop_array = Array.new        
          prodoct_spec_deatil.elements.each('properties/name') {|property|
            prop_hash_value = Hash.new
            property_string = property.text
            property_string_arr = property_string.split(':') 
            prop_hash_value[property_string_arr[0]] =property_string_arr[1]
            prop_array << prop_hash_value          
          }
          product_properties[prop_heading_name] = prop_array
        }      
        save_product(product_name, product_name ,product_price,sub_ctgy_name,product_image_url, STORE_NAME, STORE_URL, product_store_url, product_properties)
      }
    }
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
 puts "taxon #{@taxon.name} saved successfully"
end  


def save_product(product_name, description ,price , taxon_name,product_img_url, store_name, store_url, product_store_url, product_properties)
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

 if !@product.taxons.exists?(@taxon)
    puts "3333333333333333333333333333333#{@product.id} and #{@taxon.id} saved"
   @product.taxons << @taxon
 end
 #delete old image of products
 @product.images.destroy_all
 @product.save
 
 @image = Image.new
 @image.viewable_type= "product"
 @image.viewable_id= @product.id
 @image.attachment_file_name= product_img_url
 @image.attachment_content_type = "image/jpg"
 @image.save
 
 

 product_properties.each do |key, value| 
  puts "property type #{key}"
  value.each do |property_details|
    property_details.each do |prop_name, prop_value|
      app_property = Property.find_by_name_and_presentation(prop_name,key)
      app_property = Property.new if app_property.nil? 
      app_property.name = prop_name
      app_property.presentation = key
      app_property.save
      app_product_property = ProductProperty.find_by_product_id_and_property_id(@product.id, app_property.id)
      app_product_property = ProductProperty.new if app_product_property.nil?      
      app_product_property.product = @product
      app_product_property.property = app_property
      app_product_property.value = prop_value
      app_product_property.save
      puts "property #{prop_name} saved successfully #{app_product_property.id}"
    end  
  end
end
 puts "product #{@product.name} saved successfully"
end

def getRootCtgys
  ctgy_ids = Hash.new
  ctgy_ids['Home Appliances'] = "ctl00_ctrlCategoryNavigation_ctl07_aspxMenuSubCategory"
  ctgy_ids['Consumer Electronics'] = "ctl00_ctrlCategoryNavigation_ctl10_aspxMenuSubCategory"
  ctgy_ids['Kitchenware and Appliances'] = "ctl00_ctrlCategoryNavigation_ctl13_aspxMenuSubCategory"
  ctgy_ids['Gadgets'] = "ctl00_ctrlCategoryNavigation_ctl16_aspxMenuSubCategory"  
  return ctgy_ids
end