{ lib, stdenv, fetchFromGitHub, fetchpatch, kernel }:

let
  sourceAttrs = (import ./source.nix) { inherit fetchFromGitHub; };
in

stdenv.mkDerivation rec {
  name = "rtpengine-${version}-${kernel.version}";
  version = "11.3.1.8";

  src = fetchFromGitHub {
    owner = "sipwise";
    repo = "rtpengine";
    rev = "mr${version}";
    hash = "sha256-wp4uwyT7jzChzu0SvXzGkc1FnUOjIa33ZYeSA45sYU4=";
  };

  sourceRoot = "source/kernel-module";
  hardeningDisable = [ "pic" ];
  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
  ];

  postPatch = ''
    substituteInPlace Makefile \
      --replace '$(DESTDIR)/lib/modules/$(shell uname -r)' "$out/lib/modules/${kernel.modDirVersion}" \
      --replace '/lib/modules/$(shell uname -r)' "${kernel.dev}/lib/modules/${kernel.modDirVersion}" \
      --replace 'depmod' '#'

    cat Makefile
  '';

  meta = {
    description = "Proxy for RTP and other UDP based media traffic - kernel modules";
    homepage = "https://rtpengine.com/";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ mawis ];
  };

}
