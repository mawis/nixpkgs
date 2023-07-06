{ callPackage
, fetchFromGitHub
, fetchurl
, lib
, perlPackages
, pkgs
, stdenv
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rtpengine";
  version = "11.3.1.8";

  meta = {
    description = "Proxy for RTP and other UDP based media traffic";
    homepage = "https://rtpengine.com/";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ mawis ];
    platforms = lib.platforms.linux;
  };

  src = fetchFromGitHub {
    owner = "sipwise";
    repo = "rtpengine";
    rev = "mr${finalAttrs.version}";
    hash = "sha256-wp4uwyT7jzChzu0SvXzGkc1FnUOjIa33ZYeSA45sYU4=";
  };

  bashBin = "${pkgs.bash}/bin/bash";
  perlBin = "${pkgs.perl}/bin/perl";

  buildInputs = with pkgs; [
    ffmpeg-headless.dev
    glib.dev
    hiredis
    iptables.dev
    json-glib.dev
    libevent.dev
    libpcap
    libwebsockets.dev
    libxml2.dev
    mariadb-connector-c.dev
    openssl.dev
    opusfile.dev
    pcre.dev
    spandsp3.dev
    xmlrpc_c
  ];

  nativeBuildInputs = with pkgs; [
    gperf
    makeWrapper
    perl
    pkg-config
  ];

  postPatch = ''
    for f in utils/const_str_hash utils/rtpengine-ctl utils/rtpengine-ng-client utils/rtpengine-get-table; do
      substituteInPlace $f \
        --replace '/usr/bin/perl' '${finalAttrs.perlBin}'
    done

    substituteInPlace utils/build_test_wrapper \
      --replace '/bin/bash' '${finalAttrs.bashBin}'

    for f in Makefile daemon/Makefile recording-daemon/Makefile ; do
      substituteInPlace $f --replace usr/bin bin
      substituteInPlace $f --replace usr/share share
    done

    substituteInPlace Makefile --replace usr/libexec libexec
  '';

  preConfigure = ''
    export DESTDIR="$out"
  '';

  postFixup = let
    ExporterTidy = perlPackages.buildPerlPackage {
      pname = "ExporterTidy";
      version = "0.08";
      src = fetchurl {
        url = "mirror://cpan/authors/id/J/JU/JUERD/Exporter-Tidy-0.08.tar.gz";
        hash = "sha256-foRywyseR9DZDftRfAOSgSRsOlK+MCLjz9V6n7nk5Ys=";
      };
      meta = {
      };
    };
    Bencode = perlPackages.buildPerlPackage {
      pname = "Bencode";
      version = "1.502";
      src = fetchurl {
        url = "mirror://cpan/authors/id/A/AR/ARISTOTLE/Bencode-1.502.tar.gz";
        hash = "sha256-tCtUQiaN2c1X2CEOjr3Y/iVsJYvj4aoettMflDb45HY=";
      };
      buildInputs = [ perlPackages.TestDifferences ];
      propagatedBuildInputs = [ ExporterTidy ];
      meta = {
      };
    };
  in
  ''
    for f in $out/bin/rtpengine-ctl $out/libexec/rtpengine/rtpengine-get-table; do
      wrapProgram $f --prefix PERL5LIB : "${with perlPackages; makePerlPath [ ConfigTiny ]}"
    done

    wrapProgram $out/bin/rtpengine-ng-client \
      --prefix PERL5LIB : "$out/lib/perl:${with perlPackages; makePerlPath [ Bencode ExporterTidy JSON Socket6 ]}"
  '';

  postInstall = ''
    find perl -type f -exec install -D -m 0444 "{}" "$out/lib/{}" \;
  '';
})
