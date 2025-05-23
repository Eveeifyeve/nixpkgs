# Getdns and Stubby are released together, see https://getdnsapi.net/releases/

{
  lib,
  stdenv,
  fetchurl,
  cmake,
  darwin,
  doxygen,
  libidn2,
  libyaml,
  openssl,
  systemd,
  unbound,
  yq,
}:
let
  metaCommon = {
    maintainers = with lib.maintainers; [
      leenaars
      ehmry
    ];
    license = lib.licenses.bsd3;
    platforms = lib.platforms.all;
  };
in
rec {

  getdns = stdenv.mkDerivation rec {
    pname = "getdns";
    version = "1.7.3";
    outputs = [
      "out"
      "dev"
      "lib"
      "man"
    ];

    src = fetchurl {
      url = "https://getdnsapi.net/releases/${pname}-${lib.concatStringsSep "-" (lib.splitVersion version)}/${pname}-${version}.tar.gz";
      # upstream publishes hashes in hex format
      sha256 = "f1404ca250f02e37a118aa00cf0ec2cbe11896e060c6d369c6761baea7d55a2c";
    };

    nativeBuildInputs = [
      cmake
      doxygen
    ];

    buildInputs = [
      libidn2
      openssl
      unbound
    ];

    # https://github.com/getdnsapi/getdns/issues/517
    postPatch = ''
      substituteInPlace getdns.pc.in \
        --replace '$'{exec_prefix}/@CMAKE_INSTALL_LIBDIR@ @CMAKE_INSTALL_FULL_LIBDIR@ \
        --replace '$'{prefix}/@CMAKE_INSTALL_INCLUDEDIR@ @CMAKE_INSTALL_FULL_INCLUDEDIR@
    '';

    postInstall = "rm -r $out/share/doc";

    meta = metaCommon // {
      description = "Modern asynchronous DNS API";
      longDescription = ''
        getdns is an implementation of a modern asynchronous DNS API; the
        specification was originally edited by Paul Hoffman. It is intended to make all
        types of DNS information easily available to application developers and non-DNS
        experts. DNSSEC offers a unique global infrastructure for establishing and
        enhancing cryptographic trust relations. With the development of this API the
        developers intend to offer application developers a modern and flexible
        interface that enables end-to-end trust in the DNS architecture, and which will
        inspire application developers to implement innovative security solutions in
        their applications.
      '';
      homepage = "https://getdnsapi.net";
    };
  };

  stubby = stdenv.mkDerivation {
    pname = "stubby";
    version = "0.4.3";
    outputs = [
      "out"
      "man"
      "stubbyExampleJson"
    ];

    inherit (getdns) src;
    sourceRoot = "${getdns.pname}-${getdns.version}/stubby";

    nativeBuildInputs = [
      cmake
      doxygen
      yq
    ];

    buildInputs =
      [
        getdns
        libyaml
        openssl
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [ systemd ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [ darwin.Security ];

    postInstall = ''
      rm -r $out/share/doc
      yq \
        < $NIX_BUILD_TOP/$sourceRoot/stubby.yml.example \
        > $stubbyExampleJson
    '';

    passthru.settingsExample = builtins.fromJSON (builtins.readFile stubby.stubbyExampleJson);

    meta = metaCommon // {
      description = "Local DNS Privacy stub resolver (using DNS-over-TLS)";
      mainProgram = "stubby";
      longDescription = ''
        Stubby is an application that acts as a local DNS Privacy stub
        resolver (using RFC 7858, aka DNS-over-TLS). Stubby encrypts DNS
        queries sent from a client machine (desktop or laptop) to a DNS
        Privacy resolver increasing end user privacy. Stubby is developed by
        the getdns team.
      '';
      homepage = "https://dnsprivacy.org/dns_privacy_daemon_-_stubby/";
    };
  };

}
