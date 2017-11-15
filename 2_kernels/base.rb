require_relative 'vector.rb'
include Math

module ExaFMM
  class Base
    P = 10

    class Cell
      attr_accessor :nbody,
                    :nchild,
                    :body,
                    :child,
                    :center,
                    :radius,
                    :multipole, # multipole co-effs Array
                    :local,     # local co-effs Array
                    :first_child_index,  # useful only in cells array
                    :first_body_index,   # useful only in body array
                    :index               # index of cell is cells array

      def initialize
        @center = ExaFMM::Vector.new 3
        @multipole = 0.0
        @local = 0.0
        @nchild = 0
      end
    end

    class Body
      attr_reader :center
      attr_accessor :p, :q,:index, :next

      def initialize a, b, c=0.0
        @center = ExaFMM::Vector.new 3, [a, b, c]
        @q = 1.0
        @p = 0.0
        @next = nil
      end
    end

    def factorial n
      return 1 if n == 0
      m = 1
      1.upto(n) do |i|
        m *= i
      end
      m
    end
  end
end
