# ExaFMM 1_traversal code

# Note: This code does not produce the kind of p outputs that the lecture codes produced
# since there is no distance calculation happening.
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

  def initialize a, b
    @x = [a, b]
    @q = 1.0
    @p = 0.0
  end
end

@@ddd= 0

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

def m2l icell, jcell
  icell.local += jcell.multipole
end

def p2p cells, bodies, i, j
  cells[i].first_body_index.upto(
    cells[i].first_body_index + cells[i].nbody-1) do |ibody|

    cells[j].first_body_index.upto(
      cells[j].first_body_index + cells[j].nbody-1) do |jbody|

      bodies[ibody].p += bodies[jbody].q
    end
  end
end

def l2l cells, index
  cell = cells[index]
  if cell.nchild != 0
    cell.first_child_index.upto(
      cell.first_child_index + cell.nchild  - 1) do |i|

      cells[i].local += cell.local
    end
  end
end

def l2p cells, bodies, index
  cell = cells[index]
  cell.first_body_index.upto(
    cell.first_body_index + cell.nbody - 1) do |ibody|
    bodies[ibody].p += cell.local
  end
end

def downward_pass cells, bodies, parent_index
  l2l(cells, parent_index)
  cell = cells[parent_index]
  if cell.nchild == 0
    l2p(cells, bodies, parent_index)
  else
    cell.first_child_index.upto(
      cell.first_child_index + cell.nchild - 1) do |child_index|
      downward_pass cells, bodies, child_index
    end
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

def horizontal_pass cells, bodies, i, j
  icell = cells[i]
  jcell = cells[j]
  dx = icell.center[0] - jcell.center[0]
  dy = icell.center[1] - jcell.center[1]
  radius = sqrt(dx * dx + dy * dy)
  # if cells are far enough calculate the m2l
  if radius.round(5) >= (icell.radius + jcell.radius).round(5)
    m2l(icell, jcell)
  elsif icell.nchild == 0 && jcell.nchild == 0
    p2p(cells, bodies, i, j)
  # icell is a larger (parent) cell.
  elsif icell.radius.round(5) >= jcell.radius.round(5)
    if icell.nchild != 0
      icell.first_child_index.upto(
        icell.first_child_index + icell.nchild - 1) do |child_index|
        horizontal_pass cells, bodies, child_index, j
      end
    end
  else
    if jcell.nchild != 0
      jcell.first_child_index.upto(
        jcell.first_child_index + jcell.nchild - 1) do |child_index|
        horizontal_pass cells, bodies, i, child_index
      end
    end
  end
end

ncrit = 4
a = [0.48661618835155596, 0.38041924128339455, 0.4579439958484244, 0.6562511436940598, 0.6054569696321374, 0.2563855785306062, 0.275844587759729, 0.8849196646620664, 0.1726573968256362, 0.46368685822805644, 0.056843263123329546, 0.10973330739042297, 0.7460986415826186, 0.9821952503411928, 0.5811647684612279, 0.9065142303691455, 0.5959021348165422, 0.9299582744701893, 0.4622551297502938, 0.7362509477988896, 0.5553277088845858, 0.5060595862474705, 0.6186133822382341, 0.3541183663815983, 0.33437846390964054, 0.9723767815844623, 0.6083558671582855, 0.79735549380934, 0.6365414111039737, 0.9442970619478402, 0.9304942035831671, 0.8095956094066481, 0.568655308315092, 0.5236422226278551, 0.9802951997562893, 0.03541158578661274, 0.8318041335751722, 0.2254423747662071, 0.31026371457050617, 0.1641967941980509, 0.43459456523791284, 0.9079313390191112, 0.21893909079508156, 0.8697760342403882, 0.4387977692676608, 0.591712806593258, 0.2014569023475341, 0.4626933989884786, 0.497105045866578, 0.046574565537634616, 0.274891993475034, 0.9156533101946716, 0.7989442842574802, 0.07884109510756965, 0.06571491194765844, 0.28689435922209106, 0.5004468818838681, 0.3050741560620832, 0.5350438797305657, 0.38174996291358343, 0.3700756578251837, 0.28352827102697964, 0.5664921453474603, 0.7269263269089707, 0.464908619374646, 0.4369484184101692, 0.1071733934029162, 0.022152423217953965, 0.9778867269194804, 0.12610193575058692, 0.21958304636170534, 0.20654720219931222, 0.3665430092043027, 0.2821927344979487, 0.8931137376474145, 0.07382244346202604, 0.5941662655255985, 0.13118909855054417, 0.09208951406988719, 0.8143078066714761, 0.5541322116347099, 0.17621714116126297, 0.14631021504226405, 0.24952750354360054, 0.42695066212906574, 0.5610901235989305, 0.9678591307588116, 0.1467726293384396, 0.5114023787185794, 0.6557037956301124, 0.12132937753184303, 0.7919481653033968, 0.4032019197941016, 0.8297872552900855, 0.4294947882822415, 0.8572225389241336, 0.8443724973002463, 0.318193629352962, 0.21011872736190496, 0.9186683252940929]
b = [0.18813102319770925, 0.7458194564167703, 0.22969425181145675, 0.813572142226676, 0.8521380182992365, 0.7035693331941247, 0.665588334045401, 0.2763237405982252, 0.42655693255849003, 0.9604529121663936, 0.188029064406657, 0.36251350176124963, 0.09409057635871765, 0.0922125826405753, 0.30291082391768764, 0.14154525806489193, 0.9008100294265493, 0.2509588841503576, 0.2805096721549134, 0.1357923140655467, 0.1500649444580039, 0.48899872788379395, 0.7104683109871975, 0.44493688453140456, 0.21315297118833976, 0.7868397117974432, 0.4574085846037511, 0.03419927527039368, 0.9237230768009922, 0.5523912901979503, 0.8033342833210826, 0.8877610094103318, 0.9212162823931881, 0.6905523295720186, 0.10133240334027027, 0.7708600416809547, 0.7626600279133319, 0.9920991829025484, 0.3593825896756052, 0.6834997736585413, 0.32273124888911153, 0.5902411410624585, 0.09246154653972816, 0.3700627428441081, 0.7934311554263974, 0.9910565064632068, 0.22783030798902948, 0.8764249784241112, 0.08343425837590124, 0.8733433364470363, 0.9402574154563329, 0.42658359121730993, 0.17802689443436515, 0.6475397200110181, 0.7116678867036057, 0.4591646149487093, 0.8654493949705514, 0.015141112731990036, 0.9604642663310857, 0.7747702377028679, 0.241029367981214, 0.4493348723379642, 0.9685629681890975, 0.874296886644058, 0.6874822049824914, 0.5665496641195719, 0.1355650396371043, 0.5014539276234519, 0.40192270768643945, 0.4038020051023501, 0.7233863483647851, 0.2790123268999808, 0.7582718858680498, 0.2413777501278659, 0.46594878244389415, 0.3502621037610085, 0.9355877960212722, 0.3697974242163389, 0.10445602718964087, 0.6633114150824858, 0.35177536290433986, 0.15250884867194014, 0.07263426889113622, 0.8978572232721289, 0.49655526489810564, 0.7519018731773182, 0.054294935192848226, 0.9320205457576729, 0.6042790209086606, 0.5220828132923707, 0.585445486630186, 0.382233732559501, 0.5677045064211419, 0.9985069409197121, 0.9002330171512904, 0.14186923663626394, 0.8975436644001886, 0.24580724590429892, 0.9564134210357432, 0.9200192451151866]

# Init bodies
bodies = NUM_BODIES.times.map do |n|
  Body.new(a[n], b[n])
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

# Going from 'root' of the tree to the leaves for calculating multipoles.
upward_pass cells, bodies, 0

cells.each_with_index { |c, i| c.index = i }
# Iterate over children and neighbours to find out m2l for non-leaf cells
# and p2p for bodies within the same cell.
horizontal_pass cells, bodies, 0, 0
downward_pass cells, bodies, 0

puts "#{bodies.map { |a| a.p }}"
