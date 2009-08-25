# Uncomment this if you reference any of your controllers in activate
require_dependency 'application'

class SiteExtension < Spree::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/site"

  # Please use site/config/routes.rb instead for extension routes.

  # def self.require_gems(config)
  #   config.gem "gemname-goes-here", :version => '1.2.3'
  # end
  
  def activate
    # admin.tabs.add "Site", "/admin/site", :after => "Layouts", :visibility => [:all]
    AppConfiguration.class_eval do 
      #Spree::Config.set(:stylesheets => "compiled/screen,compiled/site")
      #Spree::Config[:stylesheets] => "compiled/screen,compiled/site"
        #preference :stylesheets, :string, :default => 'compiled/screen,compiled/site' 
    end
  end
end