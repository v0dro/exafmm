#ifndef types_h
#define types_h
#include <assert.h>                                             // Some compilers don't have cassert
#include <complex>
#include "kahan.h"
#include "namespace.h"
#include <stdint.h>
#include <vector>
#include <map>
#include "vec.h"

namespace EXAFMM_NAMESPACE {
  // Basic type definitions
#if EXAFMM_SINGLE
  typedef float real_t;                                         //!< Floating point type is single precision
  const real_t EPS = 1e-8f;                                     //!< Single precision epsilon
#else
  typedef double real_t;                                        //!< Floating point type is double precision
  const real_t EPS = 1e-16;                                     //!< Double precision epsilon
#endif
  typedef std::complex<real_t> complex_t;                       //!< Complex type
  const complex_t I(0.,1.);                                     //!< Imaginary unit

  typedef vec<3,int> ivec3;                                     //!< Vector of 3 int types
  typedef vec<3,real_t> vec3;                                   //!< Vector of 3 real_t types
  typedef vec<4,real_t> vec4;                                   //!< Vector of 4 real_t types
  typedef vec<3,float> fvec3;                                   //!< Vector of 3 float types
  typedef vec<3,complex_t> cvec3;                               //!< Vector of 3 complex_t types


  // Kahan summation types (Achieves quasi-double precision using single precision types)
#if EXAFMM_USE_KAHAN
  typedef kahan<real_t> kreal_t;                                //!< Real type with Kahan summation
  typedef kahan<complex_t> kcomplex_t;                          //!< Complex type with Kahan summation
#else
  typedef real_t kreal_t;                                       //!< Real type (dummy Kahan)
  typedef complex_t kcomplex_t;                                 //!< Complex type (dummy Kahan)
#endif
  typedef vec<4,kreal_t> kvec4;                                 //!< Vector of 4 real types with Kahan summaiton
  typedef vec<4,kcomplex_t> kcvec4;                             //!< Vector of 4 complex types with Kahan summaiton

  //! Structure of aligned source for SIMD
  struct Source {                                               //!< Base components of source structure
    vec3      X;                                                //!< Position
#if EXAFMM_LAPLACE
    real_t    Q;                                              //!< Scalar real values
#elif EXAFMM_HELMHOLTZ
    complex_t Q;                                              //!< Scalar complex values
#elif EXAFMM_BIOTSAVART
    vec4      Q;                                              //!< Vector real values
#endif
  };

  //! Structure of bodies
  struct Target {      //!< Base components of body structure
    vec3      X;                                                //!< Position
#if EXAFMM_LAPLACE
    kvec4     F;                                                //!< Scalar+vector3 real values
#elif EXAFMM_HELMHOLTZ
    kcvec4    F;                                                //!< Scalar+vector3 complex values
#elif EXAFMM_BIOTSAVART
    kvec4     F;                                                //!< Scalar+vector3 real values
#endif
  };

  typedef std::vector<Source> Sources;                           //!< Vector of bodies
  typedef std::vector<Target> Targets;
  typedef typename Sources::iterator S_iter;                     //!< Iterator of body vector
  typedef typename Targets::iterator T_iter;

  /*
#ifdef EXAFMM_PMAX
  const int Pmax = EXAFMM_PMAX;                                 //!< Max order of expansions
#else
  const int Pmax = 10;                                          //!< Max order of expansions
#endif
  const int Pmin = 4;                                           //!< Min order of expansions
  */

  //! Base components of cells
  struct CellBase {
    int IPARENT;                                                //!< Index of parent cell
    int ICHILD;                                                 //!< Index of first child cell
    int NCHILD;                                                 //!< Number of child cells
    
    int S_IBODY;                                                  //!< Index of first body
    int T_IBODY;                                                  //!< Index of first body
    int S_NBODY;                                                  //!< Number of descendant bodies
    int T_NBODY;                                                  //!< Number of descendant bodies
#if EXAFMM_COUNT_LIST
    int numP2P;                                                 //!< Size of P2P interaction list per cell
    int numM2L;                                                 //!< Size of M2L interaction list per cell
#endif
    uint64_t ICELL;                                             //!< Cell index
    real_t   WEIGHT;                                            //!< Weight for partitioning
    vec3     X;                                                 //!< Cell center
    real_t   R;                                                 //!< Cell radius
    S_iter   S_BODY;                                              //!< Iterator of first body
    T_iter   T_BODY;                                              //!< Iterator of first body
  };
  
  typedef std::vector<complex_t> Coefs;
  typedef std::map<uint64_t, Coefs> CoefMap;
  
  //! Structure of cells
  struct Cell : public CellBase {
    std::vector<complex_t> M;                                   //!< Multipole expansion coefs
    std::vector<complex_t> L;                                   //!< Local expansion coefs
    using CellBase::operator=;
  };
  typedef std::vector<Cell> Cells;                              //!< Vector of cells
  typedef std::vector<CellBase> CellBases;                      //!< Vector of cell bases
  typedef typename Cells::iterator C_iter;                      //!< Iterator of cell vector
  typedef typename CellBases::iterator CB_iter;                 //!< Iterator of cell vector
}
#endif