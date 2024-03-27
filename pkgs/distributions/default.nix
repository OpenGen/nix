{
  fetchFromGitHub,
  callPackage,
  fetchPypi,
  eigen,
  parsable,
  goftests,
  protobuf3_20,
  python3Packages,
}:
let
  version = "2.2.1";

  src = fetchFromGitHub {
    owner = "posterior";
    repo = "distributions";
    rev = "c2a9dccb09ab525927037ed59f3ceffb38e8a995"; # there is no tag
    sha256 = "sha256-KP8o5w0PKdcwgmQJqRBRmEPrHesHvPQCp+g22mk5wOs=";
  };

  distributions-shared = callPackage ./distributions-shared.nix { inherit version src; };

  imageio = python3Packages.buildPythonPackage rec {
    pname = "imageio";
    version = "2.6.1";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-9E6yMbnfSFh08v/SLf0MPHEefeB2UWuTdO3qXGW8Z64=";
    };

    doCheck = false;

    nativeBuildInputs = with python3Packages; [
      pytest
    ];

    propagatedBuildInputs = with python3Packages; [
      pillow
    ];

    buildInputs = with python3Packages; [
      enum34
      numpy
    ];
  };
in
python3Packages.buildPythonPackage {
  pname = "distributions";

  inherit version src;

  nativeBuildInputs = [
    protobuf3_20
    python3Packages.pyflakes
  ];

  buildInputs = [
    eigen
    # TODO: we're not sure if this is even needed
    distributions-shared
    protobuf3_20
  ];

  propagatedBuildInputs = with python3Packages; [
    protobuf3_20
    cython
    numpy
    parsable
    scipy
    simplejson
  ];

  # TODO: be more precise. Some tests seem to be still in Python 2.
  doCheck = false;
  nativeCheckInputs = with python3Packages; [
    imageio
    nose
    goftests
  ];

  preBuild = ''
    make protobuf
  '';

  patches = [
    #./distributions-01-imread.patch
  ];

  DISTRIBUTIONS_USE_PROTOBUF = 1;

  # https://github.com/numba/numba/issues/8698#issuecomment-1584888063 
  NUMPY_EXPERIMENTAL_DTYPE_API = 1;

  pythonImportsCheck = [
    "distributions"
    "distributions.io"
    "distributions.io.stream"
  ];

  passthru = {
    # TODO: we're not sure if this is even needed
    inherit distributions-shared;
  };
}
