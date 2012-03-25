class A
  def self.inherited(child)
    puts "A: #{child} has inherited me (#{self})."
  end
end

class B
  def self.inherited(child)
    puts "B: #{child} has inherited me (#{self})."
  end
end

class C < B; end
