module ExaFMM
  class Vector
    include Enumerable

    def each &block
      @vector.each(&block)
    end

    def initialize size, data=nil
      @size = size
      @vector = Array.new size, 0.0
      if data
        @vector = data.dup
      end
    end

    def []= index, num
      raise "#{index} > #{@size}" if index >= @size
      @vector[index] = num
    end

    def [] index
      @vector[index]
    end

    # Tries to give us a notion of the magnitude. That's why
    #  it is squared so that magnitude will not depend on the
    #  sign of the number in the norm.
    def norm
      temp = 0
      @size.times {temp += @vector[i] * @vector[i]}
      temp
    end

    [:/, :*, :+, :-, :exp, :sin, :cos, :&, :|].each do |op|
      define_method(op) do |num|
        self.new @size, @vector.map { |v| v.send(op, num) }
      end
    end

    [:max, :min].each do |m|
      define_method(m) do |num|
        self.new @size, @vector.send(m, num)
      end
    end

    def sincos
      s = self.sin
      c = self.cos

      return [s, c]
    end
end
