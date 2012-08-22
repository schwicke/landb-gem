class LandbResponse

  def initialize(hash)
    hash.each do |k,v|
      next if k.to_s =~ /@|:/
      
      if v.instance_of? Hash
        self.instance_variable_set("@#{k}", LandbResponse.new(v))  ## create and initialize an instance variable for this hash.
      else
        self.instance_variable_set("@#{k}", v)  ## create and initialize an instance variable for this key/value pair.
      end
      self.class.send(:define_method, k, proc{self.instance_variable_get("@#{k}")})  ## create the getter that returns the instance variable
      self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})  ## create the setter that sets the instance variable        
    end
  end
  
  def get_values_for_paths paths_array
    responces = []
    
    paths_array.each do |path|
      responces << get_value_for_path(path)
    end
    
    responces
  end
  
  def get_value_for_path path_array
    responce_runner = self
    
    path_array.each do |domain|
      responce_runner = responce_runner.send domain.to_sym
    end
    
    responce_runner
  end
end