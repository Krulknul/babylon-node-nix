{
  pkgs ? import <nixpkgs> { },
}:
let
  lib = pkgs.lib;
  fetchFromGitHub = pkgs.fetchFromGitHub;
  stdenv = pkgs.stdenv;
  fetchzip = pkgs.fetchzip;
  makeWrapper = pkgs.makeWrapper;
  jdk = pkgs.jdk17;
  systemToBinary = {
    "x86_64-darwin" = {
      url = "https://github.com/radixdlt/babylon-node/releases/download/v1.2.2/babylon-node-rust-arch-darwin-x86_64-release-v1.2.2.zip";
      sha256 = "sha256-uagSpOm9frNOrqn52UfTG7kd3AZ6Rh6gJCT/93chF/g=";
      libraryExtension = "dylib";
    };
    "aarch64-darwin" = {
      url = "https://github.com/radixdlt/babylon-node/releases/download/v1.2.2/babylon-node-rust-arch-darwin-aarch64-release-v1.2.2.zip";
      sha256 = "sha256-obnMoN0YusOlOi4Ri5peP/UaPbfjnmvs80qmbr2wtEI=";
      libraryExtension = "dylib";
    };
    "x86_64-linux" = {
      url = "https://github.com/radixdlt/babylon-node/releases/download/v1.2.2/babylon-node-rust-arch-linux-x86_64-release-v1.2.2.zip";
      sha256 = "sha256-F8QcKjZFpfowMF/weGAXxg90+iT9Kr/YhoSImkZfSiQ=";
      libraryExtension = "so";
    };
    "aarch64-linux" = {
      url = "https://github.com/radixdlt/babylon-node/releases/download/v1.2.2/babylon-node-rust-arch-linux-aarch64-release-v1.2.2.zip";
      sha256 = "sha256-Qvi6nJrVkr+Nb8oE7g8tcvOFVxLtAuxN5oXcRIzt6Y4=";
      libraryExtension = "so";
    };
  };
  binary = systemToBinary.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation rec {
  pname = "babylon-node";
  version = "1.2.3";

  srcs = [
    (fetchzip {
      url = "https://github.com/radixdlt/babylon-node/releases/download/v1.2.3/babylon-node-v1.2.3.zip";
      sha256 = "sha256-v1JuHu+ty5U2RzNDDri44OSMo1+lkpcv4Upkq5DHk8Q=";
      name = "babylon-node";
    })
    (fetchzip {
      url = binary.url;
      sha256 = binary.sha256;
      name = "library";
    })
  ];

  buildInputs = [
    jdk
    makeWrapper
  ];

  sourceRoot = "babylon-node";

  installPhase = ''
    mkdir -p $out/jni
    cp ../library/libcorerust.${binary.libraryExtension} $out/jni/
    cp -r . $out

    # Wrapping the executable with environment variables
    wrapProgram $out/bin/core \
      --set JAVA_HOME "${jdk}" \
      --set JAVA_OPTS "-server -Xms12g -Xmx12g -XX:MaxDirectMemorySize=2048m -XX:+HeapDumpOnOutOfMemoryError -XX:+UseCompressedOops -Djavax.net.ssl.trustStoreType=jks -Djava.security.egd=file:/dev/urandom -DLog4jContextSelector=org.apache.logging.log4j.core.async.AsyncLoggerContextSelector -Djava.library.path=$out/jni" \
      --run 'export JAVA_OPTS="$JAVA_OPTS $OVERRIDE_JAVA_OPTS"' \
      --set LD_PRELOAD "$out/jni/libcorerust.${binary.libraryExtension}" \
      --set LD_LIBRARY_PATH "${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH"
    mv $out/bin/core $out/bin/babylon-node

    wrapProgram $out/bin/keygen \
      --set JAVA_HOME "${jdk}"
  '';

  meta = with lib; {
    description = "The RadixDLT node software for the Babylon network";
    homepage = "https://github.com/radixdlt/babylon-node";
  };
}
