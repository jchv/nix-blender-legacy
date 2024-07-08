{
  config,
  stdenv,
  lib,
  fetchurl,
  fetchFromGitHub,
  boost,
  cmake,
  c-blosc,
  ffmpeg_4,
  fmt_8,
  gettext,
  giflib,
  glew,
  hdf5-threadsafe,
  ilmbase,
  libXi,
  libX11,
  libXext,
  libXrender,
  libjpeg,
  libpng,
  libsamplerate,
  libsndfile,
  libtiff,
  libGLU,
  libGL,
  ninja,
  openal,
  opencolorio_1,
  openexr_2,
  openimagedenoise,
  openjpeg,
  python39Packages,
  libXxf86vm,
  robin-map,
  tbb,
  unzip,
  zlib,
  fftw,
  opensubdiv,
  freetype,
  jemalloc,
  ocl-icd,
  addOpenGLRunpath,
  jackaudioSupport ? false,
  libjack2,
  cudaSupport ? config.cudaSupport or false,
  cudatoolkit,
  colladaSupport ? true,
  opencollada,
  makeWrapper,
  pugixml,
  SDL,
  Cocoa,
  CoreGraphics,
  ForceFeedback,
  OpenAL,
  OpenGL,
}:

let
  python3Packages = python39Packages;
  python = python3Packages.python;
  openexr = openexr_2.overrideAttrs {
    doCheck = false;
    postFixup = ''
      ln -s $dev/include/OpenEXR/Imath $dev/include/OpenEXR
    '';
  };
  opencolorio = opencolorio_1;
  openimageio2 = stdenv.mkDerivation rec {
    pname = "openimageio";
    version = "2.2.17.0";
    src = fetchFromGitHub {
      owner = "OpenImageIO";
      repo = "oiio";
      rev = "Release-${version}";
      hash = "sha256-0MCRIidWVcPXThuu/wDUH/UuqW5NIZFq4yGkyH5YF0s=";
    };
    outputs = [
      "bin"
      "out"
      "dev"
      "doc"
    ];
    nativeBuildInputs = [
      cmake
      ninja
      unzip
    ];
    buildInputs = [
      boost
      giflib
      ilmbase
      libjpeg
      libpng
      libtiff
      opencolorio
      openexr
      robin-map
      fmt_8
    ];
    doCheck = false;
    cmakeFlags = [
      "-DUSE_PYTHON=OFF"
      "-DUSE_QT=OFF"
      "-DCMAKE_INSTALL_LIBDIR=lib"
      "-GNinja"
    ];
    postFixup = ''
      substituteInPlace $dev/lib/cmake/OpenImageIO/OpenImageIOTargets-*.cmake \
        --replace "\''${_IMPORT_PREFIX}/lib/lib" "$out/lib/lib"
    '';
    meta = {
      homepage = "http://www.openimageio.org";
      description = "A library and tools for reading and writing images";
      license = lib.licenses.bsd3;
      platforms = lib.platforms.unix;
    };
  };
  openvdb = stdenv.mkDerivation rec {
    pname = "openvdb";
    version = "7.0.0";
    src = fetchFromGitHub {
      owner = "AcademySoftwareFoundation";
      repo = "openvdb";
      rev = "v${version}";
      hash = "sha256-NCsmWlzPlDFGkMV8U5UKFi7R9eJslGh5kG/CAhwoGkI=";
    };
    outputs = [ "out" ];
    buildInputs = [
      unzip
      openexr
      boost
      tbb
      jemalloc
      c-blosc
      ilmbase
    ];
    setSourceRoot = ''
      sourceRoot=$(echo */openvdb)
    '';
    installTargets = [ "install_lib" ];
    enableParallelBuilding = true;
    buildFlags = [
      "lib"
      "DESTDIR=$(out)"
      "HALF_LIB=-lHalf"
      "TBB_LIB=-ltbb"
      "BLOSC_LIB=-lblosc"
      "LOG4CPLUS_LIB="
      "BLOSC_INCLUDE_DIR=${c-blosc}/include/"
      "BLOSC_LIB_DIR=${c-blosc}/lib/"
    ];
    installFlags = [ "DESTDIR=$(out)" ];
    NIX_CFLAGS_COMPILE = "-I${openexr.dev}/include/OpenEXR -I${ilmbase.dev}/include/OpenEXR/";
    NIX_LDFLAGS = "-lboost_iostreams";
    meta = {
      description = "An open framework for voxel";
      homepage = "https://www.openvdb.org";
      platforms = lib.platforms.linux;
      license = lib.licenses.mpl20;
    };
  };
  alembic = stdenv.mkDerivation rec {
    pname = "alembic";
    version = "1.7.14";
    src = fetchFromGitHub {
      owner = "alembic";
      repo = "alembic";
      rev = version;
      hash = "sha256-pczPZYS4axBcLkjawF4rRYUmHASZ07rw1rLIs4cBMXs=";
    };
    outputs = [
      "bin"
      "dev"
      "out"
      "lib"
    ];
    nativeBuildInputs = [
      unzip
      cmake
      ninja
    ];
    buildInputs = [
      openexr
      hdf5-threadsafe
    ];
    cmakeFlags = [
      "-GNinja"
      "-DUSE_HDF5=ON"
      "-DUSE_TESTS=OFF"
    ];
    enableParallelBuilding = true;
    preBuild = ''
      cmake -DCMAKE_INSTALL_PREFIX=$out/ .
      mkdir $out
      mkdir -p $bin/bin
      mkdir -p $dev/include
      mkdir -p $lib/lib
    '';
    postInstall = ''
      mv $out/bin $bin/
      mv $out/lib $lib/
      mv $out/include $dev/
    '';
    meta = {
      description = "An open framework for storing and sharing scene data";
      homepage = "http://alembic.io/";
      license = lib.licenses.bsd3;
      platforms = lib.platforms.all;
    };
  };
in
stdenv.mkDerivation rec {
  pname = "blender";
  version = "2.83.5";

  src = fetchurl {
    url = "https://download.blender.org/source/${pname}-${version}.tar.xz";
    sha256 = "0xyawly00a59hfdb6b7va84k5fhcv2mxnzd77vs22bzi9y7sap43";
  };

  patches = [ ./fix-compile.patch ] ++ lib.optional stdenv.isDarwin ./darwin.patch;

  nativeBuildInputs = [
    cmake
    ninja
  ] ++ lib.optional cudaSupport addOpenGLRunpath;
  buildInputs =
    [
      boost
      ffmpeg_4
      gettext
      glew
      ilmbase
      freetype
      libjpeg
      libpng
      libsamplerate
      libsndfile
      libtiff
      opencolorio
      openexr
      openimagedenoise
      openimageio2
      openjpeg
      pugixml
      python
      zlib
      fftw
      jemalloc
      alembic
      (opensubdiv.override { inherit cudaSupport; })
      tbb
      makeWrapper
    ]
    ++ (
      if (!stdenv.isDarwin) then
        [
          libXi
          libX11
          libXext
          libXrender
          libGLU
          libGL
          openal
          libXxf86vm
          # OpenVDB currently doesn't build on darwin
          openvdb
        ]
      else
        [
          SDL
          Cocoa
          CoreGraphics
          ForceFeedback
          OpenAL
          OpenGL
        ]
    )
    ++ lib.optional jackaudioSupport libjack2
    ++ lib.optional cudaSupport cudatoolkit
    ++ lib.optional colladaSupport opencollada;

  postPatch =
    if stdenv.isDarwin then
      ''
        : > build_files/cmake/platform/platform_apple_xcode.cmake
        substituteInPlace source/creator/CMakeLists.txt \
          --replace-fail '${"$"}{LIBDIR}/python' '${python}'
        substituteInPlace build_files/cmake/platform/platform_apple.cmake \
          --replace-fail 'set(PYTHON_VERSION 3.7)' 'set(PYTHON_VERSION ${python.pythonVersion})' \
          --replace-fail '${"$"}{PYTHON_VERSION}m' '${"$"}{PYTHON_VERSION}' \
          --replace-fail '${"$"}{LIBDIR}/python' '${python}' \
          --replace-fail '${"$"}{LIBDIR}/opencollada' '${opencollada}' \
          --replace-fail '${"$"}{PYTHON_LIBPATH}/site-packages/numpy' '${python3Packages.numpy}/${python.sitePackages}/numpy' \
          --replace-fail 'set(OPENJPEG_INCLUDE_DIRS ' 'set(OPENJPEG_INCLUDE_DIRS "'$(echo ${openjpeg.dev}/include/openjpeg-*)'") #' \
          --replace-fail 'set(OPENJPEG_LIBRARIES ' 'set(OPENJPEG_LIBRARIES "${openjpeg}/lib/libopenjp2.dylib") #' \
          --replace-fail 'set(OPENIMAGEIO ' 'set(OPENIMAGEIO "${openimageio2.out}") #' \
          --replace-fail 'set(OPENEXR_INCLUDE_DIRS ' 'set(OPENEXR_INCLUDE_DIRS "${openexr.dev}/include/OpenEXR") #'
      ''
    else
      ''
        substituteInPlace extern/clew/src/clew.c --replace-fail '"libOpenCL.so"' '"${ocl-icd}/lib/libOpenCL.so"'
      '';

  cmakeFlags =
    [
      "-GNinja"
      "-DWITH_ALEMBIC=ON"
      "-DWITH_MOD_OCEANSIM=ON"
      "-DWITH_CODEC_FFMPEG=ON"
      "-DWITH_CODEC_SNDFILE=ON"
      "-DWITH_INSTALL_PORTABLE=OFF"
      "-DWITH_FFTW3=ON"
      "-DWITH_SDL=OFF"
      "-DWITH_OPENCOLORIO=ON"
      "-DWITH_OPENSUBDIV=ON"
      "-DPYTHON_LIBRARY=${python.libPrefix}"
      "-DPYTHON_LIBPATH=${python}/lib"
      "-DPYTHON_INCLUDE_DIR=${python}/include/${python.libPrefix}"
      "-DPYTHON_VERSION=${python.pythonVersion}"
      "-DWITH_PYTHON_INSTALL=OFF"
      "-DWITH_PYTHON_INSTALL_NUMPY=OFF"
      "-DPYTHON_NUMPY_PATH=${python3Packages.numpy}/${python.sitePackages}"
      "-DWITH_OPENVDB=ON"
      "-DWITH_TBB=ON"
      "-DWITH_IMAGE_OPENJPEG=ON"
      "-DWITH_OPENCOLLADA=${if colladaSupport then "ON" else "OFF"}"
      "-DCMAKE_SKIP_BUILD_RPATH=ON"
    ]
    ++ lib.optionals stdenv.isDarwin [
      "-DWITH_CYCLES_OSL=OFF" # requires LLVM
      "-DWITH_OPENVDB=OFF" # OpenVDB currently doesn't build on darwin

      "-DLIBDIR=/does-not-exist"
    ]
    # Clang doesn't support "-export-dynamic"
    ++ lib.optional stdenv.cc.isClang "-DPYTHON_LINKFLAGS="
    ++ lib.optional jackaudioSupport "-DWITH_JACK=ON"
    ++ lib.optional cudaSupport "-DWITH_CYCLES_CUDA_BINARIES=ON";

  NIX_CFLAGS_COMPILE = "-I${ilmbase.dev}/include/OpenEXR -I${python}/include/${python.libPrefix}";

  # Since some dependencies are built with gcc 6, we need gcc 6's
  # libstdc++ in our RPATH. Sigh.
  NIX_LDFLAGS = lib.optionalString cudaSupport "-rpath ${stdenv.cc.cc.lib}/lib";

  enableParallelBuilding = true;

  blenderExecutable =
    placeholder "out"
    + (if stdenv.isDarwin then "/Blender.app/Contents/MacOS/Blender" else "/bin/blender");
  # --python-expr is used to workaround https://developer.blender.org/T74304
  postInstall = ''
    wrapProgram $blenderExecutable \
      --prefix PYTHONPATH : ${python3Packages.numpy}/${python.sitePackages} \
      --add-flags '--python-use-system-env'
  '';

  # Set RUNPATH so that libcuda and libnvrtc in /run/opengl-driver(-32)/lib can be
  # found. See the explanation in libglvnd.
  postFixup = lib.optionalString cudaSupport ''
    for program in $out/bin/blender $out/bin/.blender-wrapped; do
      isELF "$program" || continue
      addOpenGLRunpath "$program"
    done
  '';

  meta = {
    description = "3D Creation/Animation/Publishing System";
    homepage = "https://www.blender.org";
    license = lib.licenses.gpl2Plus;
    platforms = [
      "x86_64-linux"
      "x86_64-darwin"
    ];
  };
}
