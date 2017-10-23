# ExaFMM 1_traversal code
include Math

NUM_BODIES_PER_LEAF = 4
NUM_BODIES = 100

# Calculate the qudrant of body w.r.t x0.
def quadrant_of x0, body
  a = body.x[0] > x0[0] ? 1 : 0
  b = body.x[1] > x0[1] ? 1 : 0
  a + (b << 1)
end

class Cell
  attr_accessor :nbody,
                :nchild,
                :body,
                :child,
                :center,
                :radius,
                :multipole,
                :local,
                :first_child_index, # useful only in cells array
                :first_body_index   # useful only in body array

  def initialize
    @center = [0.0,0.0]
    @multipole = 0.0
    @local = 0.0
  end
end

class Body
  attr_reader :x, :q

  def initialize a, b
    @x = [a, b]
    @q = 1.0
  end
end

def build_tree bodies, cells, cell, x_min, x0, r0, start, finish, ncrit
  # Init cell parameters
  cell.body = bodies[start]
  cell.first_body_index = start
  cell.nbody = finish - start
  cell.nchild = 0
  2.times { |d| cell.center[d] = x0[d] }
  cell.radius = r0

  return if finish - start < ncrit
  # count bodies in each quadrant
  size = Array.new 4, 0
  start.upto(finish-1) do |i|
    quadrant = quadrant_of x0, bodies[i]
    size[quadrant] += 1
  end
  cell.nchild = 0
  # update number of children if there are elements in the quadrant
  4.times { |i| cell.nchild += 1 if size[i] != 0 }

  # Calculate offsets
  counter = Array.new 4, start
  1.upto(3) do |i|
    counter[i] = size[i-1] + counter[i-1]
  end

  # sort bodies. buffer is temp
  buffer = bodies.dup
  start.upto(finish-1) do |n|
    quadrant = quadrant_of x0, buffer[n]
    bodies[counter[quadrant]] = buffer[n]
    counter[quadrant] += 1
  end

  # The counter variable in the above case is being updated twice. This seems weird
  #   because it seems like it is being only used for knowing the place in the bodies
  #   array where bodies of each quadrant start or end. However, it has two uses -
  #   First to calculate the offsets of each qudrant, and second to calculate the index
  #   each body starting from that offset.

  # In the second use (i.e the 2nd line of above .times loop) the counter[qudrant] is first
  #   used for knowing the offset. Once that is known, we increment that value by 1 (the
  #   next line) so that it points to the index of the next value and then we can refer
  #   to the next to-be-sorted body from the bodies array in the 2nd line of the loop in
  #   in the next iteration.

  # Below we increase the size of the cells array by the number of children that this particular
  #   cell contains for accomodating the children.
  cell.nchild.times { cells << Cell.new  }
  cells_size = cells.size
  child = cells[cells_size - cell.nchild]
  # Calculate new center and radius for the child cells.
  cell.child = child
  cell.first_child_index = cells_size - cell.nchild
  center = [0.0, 0.0]
  c = 0
  4.times do |i|
    radius = r0 / 2
    2.times do |d|
      # Change the quadrant index into a 2D index for the X and Y dimension by
      #   bit shifting and then deinterleaving the bits. Then use this for calculating
      #   center of the child cells.
      center[d] = x0[d] + radius * (((i & 1 << d) >> d) * 2 - 1)
    end

    if size[i] != 0
      # We use counter[i] - size[i] as the second last arg because by this time the
      #   counter has reached the max index by now and size[i] contains the number of
      #   bodies in this qudrant. So their difference will give us the starting point of
      #   of the ith qudrant that is to be further subdivided.
      build_tree(
        bodies, cells, cells[cells_size-cell.nchild+c],
        x_min, center, radius,
        counter[i] - size[i], counter[i], ncrit)
      c += 1
    end
    # Since this function is being called recursively, it will keep further dividing
    #  each qudrant until there are less than 4 bodies inside the innermost qudrant.
    #  This will also be adaptive since we divide quadrants dynamically depending on the
    #  size of the quadrant.
  end
end

def p2m cells, bodies, parent_cell_index
  cell = cells[parent_cell_index]
  first_body_index = cell.first_body_index
  first_body_index.upto(first_body_index + cell.nbody - 1) do |i|
    cells[parent_cell_index].multipole += bodies[i].q
  end
end

def m2m cells, bodies, parent_cell_index
  cell = cells[parent_cell_index]
  first_child_index = cell.first_child_index
  first_child_index.upto(first_child_index + cell.nchild - 1) do |i|
    cell.multipole += cells[i].multipole
  end
end

# parent_cell_index - identifies the index of parent in the cells array.
def upward_pass cells, bodies, parent_cell_index
  cell = cells[parent_cell_index]
  if cell.nchild != 0
    max_child_index = cell.first_child_index + cell.nchild - 1
    cell.first_child_index.upto(max_child_index) do |child_index|
      upward_pass cells, bodies, child_index
    end
  end

  if cell.nchild == 0 # reached the leaf cell so make multipoles from particles
    p2m(cells, bodies, parent_cell_index)
  else
    m2m(cells, bodies,parent_cell_index)
  end
end

ncrit = 4

# Init bodies
bodies = NUM_BODIES.times.map do |n|
  Body.new(rand, rand)
end

# Build tree
# Get bounds
x_min = [0.0,0.0]
x_max = [0.0,0.0]

x_min[0] = x_max[0] = bodies[0].x[0]
x_min[1] = x_max[1] = bodies[0].x[1]
NUM_BODIES.times do |n|
  2.times do |d|
    x_min[d] = x_min[d] > bodies[n].x[d] ? bodies[n].x[d] : x_min[d]
    x_max[d] = x_max[d] < bodies[n].x[d] ? bodies[n].x[d] : x_max[d]
  end
end

# get center and radius
x0 = [0.0, 0.0]
x0[0] = (x_min[0] + x_max[0]) / 2
x0[1] = (x_min[1] + x_max[1]) / 2
# The radius is calculated like this because the boxes need to be square.
#   We can just calcuate the longest side, and use that to calculate the
#   radius by taking its half. You also need to account for rounding errors
#   give some leeway for that. Therefore we use 0.50001 and not 0.5.
r0 = [x_max[0] - x_min[0], x_max[1] - x_min[1]].max * 0.50001

x_min[0] = x0[0] - r0
x_max[0] = x0[0] + r0
x_min[1] = x0[1] - r0
x_max[1] = x0[1] + r0

cells = [Cell.new]
cells[0].center[0] = x0[0]
cells[0].center[1] = x0[1]
cells[0].radius = r0

build_tree bodies, cells, cells[0],  x_min, x0, r0, 0, NUM_BODIES, ncrit
upward_pass cells, bodies, 0

puts "multipoles: #{cells.map { |c| c.multipole }}"
