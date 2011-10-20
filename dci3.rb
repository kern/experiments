require 'unextendable'

class RoleExtender
  def self.for(obj)
    role_extender = obj.instance_variable_get(:@__role_extender__)
    role_extender || new(obj)
  end

  def initialize(obj)
    @obj = obj
    @roles = []
    infect
  end

  def as(klasses)
    return unless block_given?
    extend_obj(klasses)
    yield
  ensure
    unextend_obj(klasses)
  end

  private

  def infect
    @obj.instance_variable_set(:@__role_extender__, self)
  end

  def extend_obj(klasses)
    klasses.each do |k|
      k.unextendable
      @obj.extend(k) unless extended?(k)
      add_role(k)
    end
  end

  def unextend_obj(klasses)
    klasses.each do |k|
      @obj.unextend(k) if extended?(k)
      remove_role(k)
    end
  end

  def extended?(klass)
    @roles.include?(klass)
  end

  def add_role(klass)
    @roles.push(klass)
  end

  def remove_role(klass)
    @roles.delete(klass)
  end
end

module HasRoles
  def as(*klasses, &block)
    role_extender = RoleExtender.for(self)
    role_extender.as(klasses, &block)
  end
end

module Firefighter
  def occupation
    'firefighter'
  end
end

module Programmer
  def occupation
    'programmer'
  end
end

class Person
  include HasRoles

  def greet!
    puts "Hello! I'm a #{occupation}."
  end

  def occupation
    'regular person'
  end
end

p = Person.new
p.greet!

# Now, we'll make it a firefighter.
p.as(Firefighter) do
  p.greet!
end

# Back to being a regular person again.
p.greet!

# Now this person is both a firefighter and a programmer.
p.as(Firefighter, Programmer) do
  p.greet!
end

# You can also nest roles.
p.as(Firefighter) do
  p.as(Programmer) do
    p.greet!
  end
end
