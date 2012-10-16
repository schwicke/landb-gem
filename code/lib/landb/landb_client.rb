class LandbClient
  
  def self.instance
    @@instance ||= LandbClient.new
  end
  
  def self.set_config(config)
    @@config = config
  end
  
  def self.flush
    @@instance = LandbClient.new
  end
  
  def initialize
    # Get the configurations. arguments are: wsdl, username, password.
    if !@@config 
      return
    end
    
    # Make HTTPI silent.
    HTTPI.log = false
    
    # Make savon silent.
    Savon.configure do |savon_config|
      savon_config.log = false
    end
    
    # Getting the SOAP client with WSDL specifications.
    @client = Savon.client(@@config["wsdl"])
  
    # Create a hash that contains all the operations and arguments that SOAP server supports.
    # e.g. The get_auth_token action is taking 3 arguments: Login, Password, Type.
    @operations_to_arguments_hash = get_all_operations_and_arguments
    
    # For each action the SOAP server supports, we create a dynamic method for our class.
    @client.wsdl.soap_actions.each do |method_name|
      # Ruby method "send" helps us to create the methods of the class.
      self.class.send :define_method, method_name do |arg|
        
        # Error handling for arguments.
        arg = arg.to_a unless arg.instance_of? Array
        
        if arg.count != @operations_to_arguments_hash[method_name].count
          puts "Arguments are: #{@operations_to_arguments_hash[method_name].inspect}"
          puts 'Arguments should be in an array. e.g. ["test", "test2"]'
          return
        end
        
        # For each action we have, we must integrate it with Savon.
        response = @client.request(:message, method_name) do |soap|
          # We are dynamically creating the content of the SOAP request.
          soap.header = {"Auth" => {"token" => @auth_token } } if @auth_token
          
          soap.body = {}
          
          i = 0
          # The operations_to_arguments_hash hash has all the needed arguments for the request.
          # We populate the soap arguments with the user arguments.
          @operations_to_arguments_hash[method_name].each do |soap_argument|
            soap.body.merge! soap_argument => arg[i]
            i+=1
          end
          
          # Savon tutorials infoms that if you are using ruby<1.9 there might be problems with the order.
          # This is a workaround to this problem.
          soap.body.merge! :order! => @operations_to_arguments_hash[method_name]
          
        end
        
        # We are setting the auth token automatically when existes.
        if response.to_hash[:get_auth_token_response]
          @auth_token = response.to_hash[:get_auth_token_response][:token]
        end
        
        LandbResponse.new(response.to_hash["#{method_name}_response".to_sym])
      end
    end
          
    # There is a bug in the current version of Savon.(?)(i am using 1.1.0) This is a workarround. 
    # Ref: https://github.com/rubiii/savon/pull/275
    @client = Savon.client do |wsdl|
      wsdl.endpoint = @client.wsdl.endpoint.to_s
      wsdl.namespace = @client.wsdl.namespace
    end
    
    # Initialize the token, so the client would be ready for usage.
    self.get_auth_token [@@config["username"], @@config["password"], "NICE"]
    
  end
  
  def print_auth_token
    @auth_token
  end
  
  def help_all_operations
    @operations_to_arguments_hash.keys
  end
  
  def help_arguments_for_operation(operation)
    @operations_to_arguments_hash[operation.to_sym]
  end
  
  private
  
  # This method is mapping all operations, that are declared at WSDL, and their arguments in order.
  # e.g. Gets get_auth_token and find that the arguments of this operation is: [:login, :password, :type].
  def get_all_operations_and_arguments
    hash = {}

    @client.wsdl.parser.document.xpath('wsdl:definitions/wsdl:binding/wsdl:operation').each do |action|      
      action.children.each do |child_node|
        next unless child_node.element? && child_node.name == "input"

        child_node.children.each do |att| 
          next unless att.element?
          next if att.attributes["parts"] == nil
          hash[action.attributes["name"].value.snakecase.to_sym] = att.attributes["parts"].value.split(" ").collect {|p| p.snakecase.to_sym }
        end
      end
    end
    
    hash
  end
end