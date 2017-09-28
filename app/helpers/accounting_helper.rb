module AccountingHelper

  def value_from(arg, context, *args)
    if arg.respond_to?(:call)
      return arg.call(*args)
    elsif arg.is_a?(Symbol)
      return context.send(arg, *args)
    elsif arg.is_a?(String)
      return arg
    else
      raise ArgumentError, "Argument #{arg} is not a valid callback argument, must be one of symbol, string, proc, or lambda"
    end
  end

end
