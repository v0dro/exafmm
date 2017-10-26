module ExaFMM
  class Vector
    include Enumerable

    def each &block
      @vector.each(&block)
    end

    def initialize size
      @size = size
      @vector = Array.new size, 0.0
    end

    def []= index, num
      raise "#{index} > #{@size}" if index >= @size
      @vector[index] = num
    end

    def [] index
      @vector[index]
    end

    def / num
      
    end

  end
end
