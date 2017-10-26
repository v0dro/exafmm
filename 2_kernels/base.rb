module ExaFMM
  class Base
    class Cell
      attr_accessor :nbody,
                    :nchild,
                    :body,
                    :child,
                    :center,
                    :radius,
                    :multipole,
                    :local,
                    :first_child_index,  # useful only in cells array
                    :first_body_index,   # useful only in body array
                    :index               # index of cell is cells array

      def initialize
        @center = [0.0,0.0]
        @multipole = 0.0
        @local = 0.0
        @nchild = 0
      end
    end

    class Body
      attr_reader :x, :q
      attr_accessor :p

      def initialize a, b, c
        @x = [a, b, c]
        @q = 1.0
        @p = 0.0
      end
    end
  end
end
