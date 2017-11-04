require_relative 'base.rb'

module ExaFMM
  class Kernel < Base
    self << class
      # convert cartesian co-ords to spherical.
      def cart2sph dx, rho, alpha, beta
        r = sqrt(dx.norm) # length of vector
        theta = r == 0 ? 0 : acos(dx[2]/r)
        phi = atan2(dx[1], dx[0])

        [r, theta, phi]
      end
 
      # Multipole evaluation algorithm taken from
      #  "Treecode and fast multipole method for N-body simulation with CUDA".
      #
      # Find a simplified version of the multipole expansion in "The Rapid Evaluation of Potential Fields in Particle Systems".
      #
      # I think, that in this code there is no distinction between a point (x,y) from set R and a complex number x + iy = z from
      #   a set of complex numbers C.
      def eval_multipole rho, alpha, beta, ynm, ynm_theta
        x = cos(alpha)
        y = sin(alpha)

        # unoptimized code examples based on my understanding
        0.upto(P) do |m|
          (m+1).upto do |n|
          end
        end
      end

      def p2m cells, index
        # whats this?
        cell = cells[index]
        ynm = Array.new(Complex(0.0), P*P)
        ynm_theta = Array.new(Complex(0.0), P*P)

        body = cell.body
        while body
          dx = body.center - cell.center
          rho, alpha, beta = cart2sph(dx)
          eval_multipole(rho, alpha, -beta, ynm, ynm_theta)
          P.times do |n|
            0.upto(n) do |m|
              nm = n * n + n + m
              nms = n * (n + 1) / 2 + m
              cell.multipole += body.q * ynm[nm]
            end
          end
          body = body.next
        end
      end
    end
  end
end
