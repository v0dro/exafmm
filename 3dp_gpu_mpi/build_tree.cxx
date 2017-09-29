#include "args.h"
#include "build_tree.h"
#include "dataset.h"
#include "local_essential_tree.h"
#include "partition.h"
#include "test.h"
using namespace exafmm;

int main(int argc, char ** argv) {
  Args args(argc, argv);
  P = 1;
  NCRIT = args.ncrit;
  LEVEL = args.level;
  VERBOSE = args.verbose;
  const int numBodies = args.numBodies;
  const char * distribution = args.distribution;

  Bodies bodies = initBodies(numBodies, distribution, MPIRANK, MPISIZE);
  for (size_t b=0; b<bodies.size(); b++) bodies[b].q = 1;

  partition(bodies);
  initKernel();
  Cells cells = buildTree(bodies);
  upwardPass(&cells[0]);
  localEssentialTree(bodies, cells);
  upwardPassLET(&cells[0]);

  print("numBodies", bodies.size());
  print("cells[0].M[0]", cells[0].M[0]);
  assert(bodies.size() == std::real(cells[0].M[0]));
  print("Assertion passed");
  return 0;
}
