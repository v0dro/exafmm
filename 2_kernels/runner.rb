require_relative 'base.rb'
require_relative 'kernel.rb'

module ExaFMM
  class Runner < Base
    def self.run
      # step1 code:
      p = 10

      jbodies = [Body.new(2,2)]
      jbodies[0].q = 1
      jbodies[0].index = 0

      # P2M
      cells = []
      4.times = {cells << Cell.new}
      cells[0].center[0] = 3
      cells[0].center[1] = 1
      cells[0].radius = 1
      cells[0].body = jbodies[0]
      cells[0].first_body_index
      cells[0].nbody = jbodies.size
      cells[0].multipole = Array.new p, 0.0
      ExaFMM.Kernel.p2m cells, 0

      # M2M
      cells[0].child = cells[1]
      cells[0].first_child_index = 1
      cells[1].center[0] = 4
      cells[1].center[1] = 0
      cells[1].radius = 2
      cells[1].multipole = Array.new p, 0.0
      ExaFMM::Kernel.m2m cells, 1

      # M2L
      cells[2].center[0] = -4
      cells[2].center[1] = 0
      cells[2].radius = 2
      cells[2].l = Array.new p, 0.0
      ExaFMM::Kernel.m2l cells, 2, 1

      # L2L
      cells[2].child = cells[3]
      cells[2].first_child_index = 3
      cells[3].center[0] = -3
      cells[3].center[1] = 1
      cells[3].radius = 1
      cells[3].l = Array.new p, 0.0
      ExaFMM::Kernel.l2l cells, 2

      # L2P
      bodies = [Body.new(-2,2)]
      bodies[0].q = 1
      bodies[0].p = 0
      bodies[0].index = 0
      2.times { |d| bodies[0].force[d] = 0 }
      cells[3].body = bodies[0]
      cells[3].nbody = bodies.size
      ExaFMM::Kernel.l2p cells, 3

      # P2P
      bodies2 = [Body.new(bodies[0].center[0], bodies[0].center[1])]
      bodies2.size.times do |b|
        bodies2[b].index = b
        bodies2[b] = bodies[b]
        bodies2[b].p = 0
        2.times do |d|
          bodies2[b].force[d] = 0
        end
      end
      cells[0].nbody = jbodies.size
      cells[3].nbody = bodies2.size
      cells[3].body = bodies2[0]
      ExaFMM::Kernel.p2p cells, 3, 0

      # Verification
      p_dif, p_nrm, f_dif, p_nrm = 0.0,0.0,0.0,0.0
      bodies.size.times do |b|
        p_dif += (bodies[b].p - bodies2[b].p) * (bodies[b].p - bodies2[b].p)
        p_nrm += bodies[b].p * bodies[b].p
        f_dif += (bodies[b].force[0] - bodies2[b].force[0]) *
                 (bodies[b].force[0] - bodies2[b].force[0]) +
                 (bodies[b].force[1] - bodies2[b].force[1]) *
                 (bodies[b].force[1] - bodies2[b].force[1])
        f_nrm += bodies[b].force[0] * bodies[b].force[0] +
                 bodies[b].force[1] * bodies[b].force[1]

        puts "p: #{sqrt(p_dif/p_nrm)}"
        puts "f: #{sqrt(f_dif/f_nrm)}"
      end
    end
  end
end
