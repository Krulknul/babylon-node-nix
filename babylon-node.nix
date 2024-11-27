{
  pkgs ? import <nixpkgs> { },
}:
let
  lib = pkgs.lib;
  fetchFromGitHub = pkgs.fetchFromGitHub;
  stdenv = pkgs.stdenv;
  makeWrapper = pkgs.makeWrapper;
  jdk = pkgs.jdk17;
  fetchurl = pkgs.fetchurl;
  unzip = pkgs.unzip;
  systemToBinary = {
    "x86_64-darwin" = {
      url = "https://github.com/radixdlt/babylon-node/releases/download/v1.3.0/babylon-node-rust-arch-darwin-x86_64-release-v1.3.0.zip";
      sha256 = "0k0fbjgxigazsc5xi2zi7kxc3yfgifa2chp8imwcma5h1mm39azf";
      libraryExtension = "dylib";
    };
    "aarch64-darwin" = {
      url = "https://github.com/radixdlt/babylon-node/releases/download/v1.3.0/babylon-node-rust-arch-darwin-aarch64-release-v1.3.0.zip";
      sha256 = "0922hvxpqzxxfkqi1isa870vgg4mvbwy5gvsk61x8n764j3bpb0v";
      libraryExtension = "dylib";
    };
    "x86_64-linux" = {
      url = "https://github.com/radixdlt/babylon-node/releases/download/v1.3.0/babylon-node-rust-arch-linux-x86_64-release-v1.3.0.zip";
      sha256 = "1f5rddgq28xwfhivqj4srmkxasv83iwww2yvnz7mlw2j65db5gy0";
      libraryExtension = "so";
    };
    "aarch64-linux" = {
      url = "https://github.com/radixdlt/babylon-node/releases/download/v1.3.0/babylon-node-rust-arch-linux-aarch64-release-v1.3.0.zip";
      sha256 = "0slb4b0za4fmfnjng75326sdyrbh0vjd1iq1qahzdvjz77xjwz5r";
      libraryExtension = "so";
    };
  };
  binary = systemToBinary.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation rec {
  pname = "babylon-node";
  version = "1.2.3";

  srcs = [
    (fetchurl {
      url = "https://github.com/radixdlt/babylon-node/releases/download/v1.3.0/babylon-node-v1.3.0.zip";
      sha256 = "0h0mj6y23ldmb783m0rq9zzczb3pgslar577jfy7xflpz7cmbxf3";
      name = "babylon_node";
    })
    (fetchurl {
      url = binary.url;
      sha256 = binary.sha256;
      name = "library";
    })
  ];

  buildInputs = [
    jdk
    makeWrapper
    unzip
  ];


  unpackPhase = ''
    array=($srcs)
    babylon_node=''${array[0]}
    library=''${array[1]}
    unzip $babylon_node -d babylon_node
    mv babylon_node/core-*/** babylon_node
    rm -rf babylon_node/core-*
    unzip $library -d library
    ls -al library
  '';

  sourceRoot = "babylon_node";


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
