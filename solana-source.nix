{ stdenv, fetchFromGitHub }:
let
  version = "3.1.10";
  sha256 = "sha256-9fVjwEnZqleeS5CAA4IB1ZGCljUNTT0HhxUGu3Bm8Zg=";
in
{
  inherit version;
  src = fetchFromGitHub {
    owner = "anza-xyz";
    repo = "agave";
    rev = "v${version}";
    fetchSubmodules = true;
    inherit sha256;
  };
}
