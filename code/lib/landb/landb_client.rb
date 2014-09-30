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

    # Getting the SOAP client with WSDL specifications.
    @client = Savon.client do
      wsdl @@config["wsdl"]
      log false
      ssl_verify_mode :none
    end

    # Create a hash that contains all the operations and arguments that SOAP server supports.
    # e.g. The get_auth_token action is taking 3 arguments: Login, Password, Type.
    @operations_to_arguments_hash = get_all_operations_and_arguments
    
    # For each action the SOAP server supports, we create a dynamic method for our class.
    @client.operations.each do |method_name|
      # Ruby method "send" helps us to create the methods of the class.
      self.class.send :define_method, method_name do |arg|
        
        # Error handling for arguments.
        arg = arg.to_a unless arg.instance_of? Array
        
        if arg.count != @operations_to_arguments_hash[method_name].count
          puts "Arguments are: #{@operations_to_arguments_hash[method_name].inspect}"
          puts 'Arguments should be in an array. e.g. ["test", "test2"]'
          return
        end

        # First we create the body of the request
        body = {}

        # The operations_to_arguments_hash hash has all the needed arguments for the request.
        # We populate the soap arguments with the user arguments.
        @operations_to_arguments_hash[method_name].each_with_index do |soap_argument, index|
          body.merge! soap_argument => arg[index]
        end

        response = @client.call(method_name, :message => body)

        # We are setting the auth token automatically when existes.
        if response.to_hash[:get_auth_token_response]
          @auth_token = response.to_hash[:get_auth_token_response][:token]
        end

        LandbResponse.new(response.to_hash["#{method_name}_response".to_sym])
      end
    end

    # Initialize the token, so the client would be ready for usage
    # only if name and password have been provided
    if (!@@config['username'].nil? || !@@config['password'].nil?)
      self.get_auth_token [@@config["username"], @@config["password"], "NICE"] 
    end

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

    nok = Nokogiri::XML(open(@@config["wsdl"]))
    nok.xpath('wsdl:definitions/wsdl:binding/wsdl:operation').each do |action|
      action.children.each do |child_node|
        next unless child_node.element? && child_node.name == "input"

        child_node.children.each do |att| 
          hash[action.attributes["name"].value.snakecase.to_sym] ||= []
          next unless att.element?
          next if att.attributes["parts"].nil?
          hash[action.attributes["name"].value.snakecase.to_sym] = att.attributes["parts"].value.split(" ").collect {|p| p.snakecase.to_sym }
        end
      end
    end
    
    hash
  end
end
