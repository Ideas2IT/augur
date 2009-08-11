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
    scrap_products_spot_eazy
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
  
 categories_s = categories.to_xml
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
 @taxon = Taxon.find_by_name(name, parent.id)
 @taxon = Taxon.new if @taxon.nil? 
 @taxon.name= name
 @taxon.parent_id = parent.id unless parent.nil?
 @taxon.taxonomy = Taxonomy.find_by_name("Categories")
 @taxon.position = parent.children.length unless parent.nil?
 @taxon.save
 puts "#{@taxon.name} saved successfully"
end  

def scrap_products_spot_eazy
  
end
