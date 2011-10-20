require 'force_bind'

class RoleProxy < BasicObject
  instance_methods.each { |m| undef_method m unless m =~ /^__/ }

  def initialize(obj, mixins = [])
    @obj = obj
    @mixins = mixins
  end

  def method_missing(sym, *args, &block)
    mixin = @mixins.find { |m| m.instance_methods.include?(sym) }

    if mixin
      original_method = mixin.instance_method(sym)
      bound_method = original_method.force_bind(@obj)
      result = bound_method.call(*args, &block)
    else
      result = @obj.send(sym, *args, &block)
    end

    result.equal?(@obj) ? self : result
  end

  def methods
    (@mixins.map(&:instance_methods) + @obj.methods).flatten.uniq
  end

  def kind_of?(klass)
     @obj.kind_of?(klass) || @mixins.any? { |m| klass >= m }
  end
  alias_method :is_a?, :kind_of?

  def method(sym)
    mixin = @mixins.find { |m| m.instance_methods.include?(sym) }

    if mixin
      original_method = mixin.instance_method(sym)
      original_method.force_bind(@obj)
    else
      @obj.method(sym)
    end
  end

  def public_method(sym)
    mixin = @mixins.find { |m| m.public_instance_methods.include?(sym) }

    if mixin
      original_method = mixin.private_instance_method(sym)
      original_method.force_bind(@obj)
    else
      @obj.public_instance_method(sym)
    end
  end

  def public_send(sym, *args, &block)
    
  end

  def send(sym, *args, &block)

  end

  def clone
    self.class.new(@obj.clone, @mixins)
  end

  def dup
    self.class.new(@obj.dup, @mixins)
  end
end

module LOL
  def did_it_work?
    true
  end
end

module ROFL
  def did_it_work?
    'nyan'
  end
end

obj = []
pxy = RoleProxy.new(obj, [ROFL, LOL, ROFL])
p pxy.kind_of?(LOL)
