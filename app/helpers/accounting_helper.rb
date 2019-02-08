module AccountingHelper
  include AuthorizeNet::API

  def value_from(arg, context, *args)
    if arg.respond_to?(:call)
      return arg.call(*args)
    elsif arg.is_a?(Symbol)
      return context.send(arg, *args)
    elsif arg.is_a?(String)
      return arg
    elsif arg.nil?
      nil
    else
      raise ArgumentError, "Argument #{arg} is not a valid callback argument, must be one of symbol, string, proc, or lambda"
    end
  end

  def api_options(accountable)
    return {} if accountable.nil?
    {
      api_login: value_from(option(:api_login, accountable), accountable, accountable),
      api_key: value_from(option(:api_key, accountable), accountable, accountable)
    }
  end

  def api_validation_mode(accountable)
    value_from(option(:api_validation_mode, accountable), accountable, accountable)
  end

  def option(key, accountable)
    accountable.instance_variable_get('@_accountable_options').try(:[], key.to_sym)
  end

  def authnet(type, opts={})
    raise 'Define accountable in the class' unless respond_to? :accountable
    Accounting.api(type, accountable.present? ? api_options(accountable) : opts)
  end

end
