module Spree::DependenciesExtension
  def self.included(base) #:nodoc:
    base.class_eval { alias_method_chain :require_or_load, :extensions_additions }
  end
 
  def require_or_load_with_extensions_additions(file_name, const_path=nil)
    file_loaded = false
 
    # TODO: Ugly hack. Fix this. We only know how to handle models, if the path include the word models.
    # If the file_name match we can start working on it.
    if file_name =~ /^(.*app\/controllers\/)?(.*_controller)(\.rb)?$/
      base_name = $2
      file_type = 'controller'
    elsif file_name =~ /^(.*app\/helpers\/)?(.*_helper)(\.rb)?$/
      base_name = $2
      file_type = 'helper'
    elsif file_name =~ /^(.*app\/models\/)(.*)(\.rb)?$/
      split = $2.split('.', 2)
      base_name = split[0]
      file_type = 'model'
    else
      # The file has a type that we don't know how to handle.'
      file_type = 'unknown'
    end
 
    # If the file is of a know type.
    if file_type != 'unknown'
      # First load code from Spree.
      spree_file_name = File.join(SPREE_ROOT, 'app', "#{file_type}s", base_name)
      if File.file?("#{spree_file_name}.rb")
        file_loaded = true if require_or_load_without_extensions_additions(spree_file_name, const_path)
      end
 
      # Then load code from extensions in the order they were loaded.
      paths_to_extensions = Spree::ExtensionLoader.instance.load_extension_roots
      paths_to_extensions.each do |extension_path|
        extension_file_name = File.expand_path(File.join(extension_path, 'app', "#{file_type}s", base_name))
        if File.file?("#{extension_file_name}.rb")
          file_loaded = true if require_or_load_without_extensions_additions(extension_file_name, const_path)
        end
      end
 
    end
 
    # If the file was not found or not handled (and so, not loaded) in any other place, just load it alone.
    file_loaded || require_or_load_without_extensions_additions(file_name, const_path)
  end
end
 
module ActiveSupport::Dependencies #:nodoc:
  include Spree::DependenciesExtension
end
 

