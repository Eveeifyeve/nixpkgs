{
  lib,
  newScope,
  stdenv,
  fetchzip,
  replaceVars,
  bash,
  pkg-config,
  gfortran,
  bison,
  mpi, # generic mpi dependency
  mpiCheckPhaseHook,
  python3,
  python3Packages,

  # Build options
  debug ? false,
  scalarType ? "real",
  precision ? "double",
  mpiSupport ? true,
  fortranSupport ? true,
  pythonSupport ? false, # petsc python binding
  withExamples ? false,
  withFullDeps ? false, # full External libraries support
  withCommonDeps ? true, # common External libraries support

  # External libraries options
  withHdf5 ? withCommonDeps,
  withMetis ? withCommonDeps,
  withZlib ? (withP4est || withPtscotch),
  withScalapack ? withCommonDeps && mpiSupport,
  withParmetis ? withFullDeps, # parmetis is unfree
  withPtscotch ? withCommonDeps && mpiSupport,
  withMumps ? withCommonDeps,
  withP4est ? withFullDeps,
  withHypre ? withCommonDeps && mpiSupport,
  withFftw ? withCommonDeps,
  withSuperLu ? withCommonDeps,
  withSuitesparse ? withCommonDeps,

  # External libraries
  blas,
  lapack,
  hdf5,
  metis,
  parmetis,
  scotch,
  scalapack,
  mumps,
  p4est,
  zlib, # propagated by p4est but required by petsc
  hypre,
  fftw,
  superlu,
  suitesparse,

  # Used in passthru.tests
  petsc,
}:
assert withFullDeps -> withCommonDeps;

# This version of PETSc does not support a non-MPI p4est build
assert withP4est -> (mpiSupport && withZlib);

# Package parmetis depend on metis and mpi support
assert withParmetis -> (withMetis && mpiSupport);

assert withPtscotch -> (mpiSupport && withZlib);
assert withScalapack -> mpiSupport;
assert (withMumps && mpiSupport) -> withScalapack;
assert withHypre -> mpiSupport;

let
  petscPackages = lib.makeScope newScope (self: {
    inherit
      # global override options
      mpiSupport
      fortranSupport
      pythonSupport
      precision
      ;
    enableMpi = self.mpiSupport;

    petscPackages = self;
    # external libraries
    mpi = self.callPackage mpi.override { };
    blas = self.callPackage blas.override { };
    lapack = self.callPackage lapack.override { };
    hdf5 = self.callPackage hdf5.override {
      fortran = gfortran;
      cppSupport = !mpiSupport;
    };
    metis = self.callPackage metis.override { };
    parmetis = self.callPackage parmetis.override { };
    scotch = self.callPackage scotch.override { };
    scalapack = self.callPackage scalapack.override { };
    mumps = self.callPackage mumps.override { };
    p4est = self.callPackage p4est.override { };
    hypre = self.callPackage hypre.override { };
    fftw = self.callPackage fftw.override { };
    superlu = self.callPackage superlu.override { };
    suitesparse = self.callPackage suitesparse.override { };
  });
in
stdenv.mkDerivation (finalAttrs: {
  pname = "petsc";
  version = "3.23.0";

  src = fetchzip {
    url = "https://web.cels.anl.gov/projects/petsc/download/release-snapshots/petsc-${finalAttrs.version}.tar.gz";
    hash = "sha256-OcI4iyDOR0YTVV+JoOhbfutoW00EmfapNaMnD/JJFsI=";
  };

  strictDeps = true;

  nativeBuildInputs =
    [
      python3
      gfortran
      pkg-config
      bison
    ]
    ++ lib.optional mpiSupport mpi
    ++ lib.optionals pythonSupport [
      python3Packages.setuptools
      python3Packages.cython
    ];

  buildInputs =
    [
      petscPackages.blas
      petscPackages.lapack
    ]
    ++ lib.optional withZlib zlib
    ++ lib.optional withHdf5 petscPackages.hdf5
    ++ lib.optional withP4est petscPackages.p4est
    ++ lib.optional withMetis petscPackages.metis
    ++ lib.optional withParmetis petscPackages.parmetis
    ++ lib.optional withPtscotch petscPackages.scotch
    ++ lib.optional withScalapack petscPackages.scalapack
    ++ lib.optional withMumps petscPackages.mumps
    ++ lib.optional withHypre petscPackages.hypre
    ++ lib.optional withSuperLu petscPackages.superlu
    ++ lib.optional withFftw petscPackages.fftw
    ++ lib.optional withSuitesparse petscPackages.suitesparse;

  propagatedBuildInputs = lib.optional pythonSupport python3Packages.numpy;

  patches = [
    (replaceVars ./fix-petsc4py-install-prefix.patch {
      PYTHON_SITEPACKAGES = python3.sitePackages;
    })
  ];

  postPatch = ''
    patchShebangs ./lib/petsc/bin

    substituteInPlace config/example_template.py \
      --replace-fail "/usr/bin/env bash" "${bash}/bin/bash"
  '';

  configureFlags =
    [
      "--with-blas=1"
      "--with-lapack=1"
      "--with-scalar-type=${scalarType}"
      "--with-precision=${precision}"
      "--with-mpi=${if mpiSupport then "1" else "0"}"
    ]
    ++ lib.optionals mpiSupport [
      "--CC=mpicc"
      "--with-cxx=mpicxx"
      "--with-fc=mpif90"
    ]
    ++ lib.optionals (!debug) [
      "--with-debugging=0"
      "COPTFLAGS=-O3"
      "FOPTFLAGS=-O3"
      "CXXOPTFLAGS=-O3"
      "CXXFLAGS=-O3"
    ]
    ++ lib.optional (!fortranSupport) "--with-fortran-bindings=0"
    ++ lib.optional pythonSupport "--with-petsc4py=1"
    ++ lib.optional withMetis "--with-metis=1"
    ++ lib.optional withParmetis "--with-parmetis=1"
    ++ lib.optional withPtscotch "--with-ptscotch=1"
    ++ lib.optional withScalapack "--with-scalapack=1"
    ++ lib.optional withMumps "--with-mumps=1"
    ++ lib.optional (withMumps && !mpiSupport) "--with-mumps-serial=1"
    ++ lib.optional withP4est "--with-p4est=1"
    ++ lib.optional withZlib "--with-zlib=1"
    ++ lib.optional withHdf5 "--with-hdf5=1"
    ++ lib.optional withHypre "--with-hypre=1"
    ++ lib.optional withSuperLu "--with-superlu=1"
    ++ lib.optional withFftw "--with-fftw=1"
    ++ lib.optional withSuitesparse "--with-suitesparse=1";

  hardeningDisable = lib.optionals debug [
    "fortify"
    "fortify3"
  ];

  installTargets = [ (if withExamples then "install" else "install-lib") ];

  enableParallelBuilding = true;

  # This is needed as the checks need to compile and link the test cases with
  # -lpetsc, which is not available in the checkPhase, which is executed before
  # the installPhase. The installCheckPhase comes after the installPhase, so
  # the library is installed and available.
  doInstallCheck = true;
  installCheckTarget = "check_install";

  # The PETSC4PY=no flag disables the ex100 test,
  # which compiles C code to load Python modules for solving a math problem.
  # This test fails on the Darwin platform but is rarely a common use case for petsc4py.
  installCheckFlags = lib.optional stdenv.hostPlatform.isDarwin "PETSC4PY=no";

  nativeInstallCheckInputs =
    [
      mpiCheckPhaseHook
    ]
    ++ lib.optionals pythonSupport [
      python3Packages.pythonImportsCheckHook
      python3Packages.unittestCheckHook
    ];

  unittestFlagsArray = [
    "-s"
    "src/binding/petsc4py/test"
    "-v"
  ];

  pythonImportsCheck = [ "petsc4py" ];

  passthru = {
    inherit
      mpiSupport
      pythonSupport
      fortranSupport
      ;
    petscPackages = petscPackages.overrideScope (
      final: prev: {
        petsc = finalAttrs.finalPackage;
      }
    );
    tests =
      {
        serial = petsc.override {
          mpiSupport = false;
        };
      }
      // lib.optionalAttrs stdenv.hostPlatform.isLinux {
        fullDeps = petsc.override {
          withFullDeps = true;
          withParmetis = false;
        };
      };
  };

  setupHook = ./setup-hook.sh;

  meta = {
    description = "Portable Extensible Toolkit for Scientific computation";
    homepage = "https://petsc.org/release/";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [
      cburstedde
      qbisi
    ];
  };
})
