require_relative 'base.rb'
require 'cmath'

module ExaFMM
  class Kernel < Base
    self << class
      I = Complex(0.0, 1.0) 
      # convert cartesian co-ords to spherical.
      def cart2sph dx, rho, alpha, beta
        r = sqrt(dx.norm) # length of vector
        theta = r == 0 ? 0 : acos(dx[2]/r)
        phi = atan2(dx[1], dx[0])

        [r, theta, phi]
      end

      def calculate_prefactor
        prefactor = Array.new 4*P*P

        0.upto(2*P) do |n|
          (-n).upto(n) do |m|

            nm = n*n + n + m

            fnma = factorial n - m.abs
            fnpa = factorial n + m.abs

            prefactor[nm] = sqrt(fnma/fnpa)
          end
        end
      end

      # Multipole evaluation algorithm taken from
      #  "Treecode and fast multipole method for N-body simulation with CUDA".
      #
      # Find a simplified version of the multipole expansion in "The Rapid Evaluation of Potential Fields in Particle Systems".
      #
      # I think, that in this code there is no distinction between a point (x,y) from set R and a complex number x + iy = z from
      #   a set of complex numbers C.
      def eval_multipole rho, alpha, beta, ynm, ynm_theta
        prefactor = calculate_prefactor
        x = cos(alpha)          # init x to cos of alpha
        y = sin(alpha)
        fact = 1                # initialize (2m + 1) factorial. it calculates odd numbers.
        pn =  1                 # Initialize associated legendre polynomial Pmm
        rhom = 1                # init rho (radius power)

        # unoptimized code examples based on my understanding
        (0).upto(P-1) do |m|
          eim = CMath.exp(I*(m*beta).to_f)
          pnm = pn
          npn = m*m + 2*m
          nmn = m*m
          normalizer = sqrt()
          ynm[npn] = rhom * pnm * prefactor[np] * eim
          ynm[nmn] = ynm[npn].conj
          p1 = pnm

          (m+1).upto(P-1) do |n|
            
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

