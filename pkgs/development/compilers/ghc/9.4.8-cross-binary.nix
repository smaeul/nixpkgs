{
  lib,
  stdenv,
  bash,
  fetchurl,
  pkgsMusl,
}:

# Prebuilt only does native
assert stdenv.targetPlatform == stdenv.hostPlatform;

let
  version = "9.4.8";

  # GHC upstream doesn't release bindist tarballs for some platforms.
  # We're using Debian's binary package, and patching it into a usable-in-Nixpkgs state.
  ghcCrossBinaries = {
    powerpc64le-linux = {
      variantSuffix = "";
      src = {
        url = "https://distfiles.smaeul.xyz/nix/ghc-static-powerpc64le-unknown-linux-musl-${version}.tar.xz";
        sha256 = "688befebc416821e76683194bfb191236d8b98a54137fead20214de9d8dab425";
      };
    };
  };

  crossBinaryUsed =
    ghcCrossBinaries.${stdenv.hostPlatform.system}
      or (throw "cannot bootstrap GHC on this platform ('${stdenv.hostPlatform.system}') from cross binaries");

in

stdenv.mkDerivation (finalAttrs: {
  inherit version;
  pname = "ghc-cross-binary${crossBinaryUsed.variantSuffix}";

  src = fetchurl crossBinaryUsed.src;

  sourceRoot = ".";

  # Not a bindist, nothing to configure
  dontConfigure = true;

  # Not a bindist, it's already built
  dontBuild = true;

  # Install prebuilt GHC files
  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -a * $out

    runHook postInstall
  '';

  # Patch paths
  postInstall = ''
    lib=$out/lib/ghc-${version}
    substituteInPlace \
      $out/bin/{{ghc,ghc-pkg,ghci,runghc}-${version},hp2ps,hpc,hsc2hs} \
      --replace-fail /nix/store/m2fa48bl3s86kwb1zzmarhcckp8ipbmq-bash-interactive-powerpc64le-unknown-linux-musl-5.3p3 ${bash}
    substituteInPlace \
      $out/bin/{{ghc,ghc-pkg,ghci,runghc}-${version},hp2ps,hpc,hsc2hs} \
      $(ls -1 $lib/package.conf.d/*.conf | grep -Fv system-cxx-std-lib-1.0.conf) \
      --replace-fail /nix/store/ygm7zym4fklmd99ky8lf9acmhrq751gi-ghc-musl-native-bignum-powerpc64le-unknown-linux-musl-9.4.8 $out
    substituteInPlace \
      $lib/package.conf.d/base-*.conf \
      $out/nix-support/propagated-target-target-deps \
      --replace-fail /nix/store/cjmaxclisb5k4aavbk5k57xgnbxwwwnx-musl-iconv-1.2.5 ${pkgsMusl.libiconv}
    substituteInPlace \
      $lib/package.conf.d/system-cxx-std-lib-1.0.conf \
      --replace-fail /nix/store/ahr205j8czwp02rbsnr2q8yfymszdl05-powerpc64le-unknown-linux-musl-gcc-14.3.0-lib ${pkgsMusl.stdenv.cc}
    substituteInPlace \
      $lib/settings \
      --replace-fail /nix/store/bk4hfz240r2dmhbxbmh5h9axqkac5w2p-gcc-wrapper-14.3.0 ${pkgsMusl.stdenv.cc} \
      --replace-fail /nix/store/a28zp4wgc75w71hfd5h86pcj3l3pwk3f-binutils-wrapper-2.44 ${pkgsMusl.stdenv.cc.bintools}
  '';

  postFixup =
    # Recache package db which needs to happen because
    # we modify the package db
    ''
      "$out/bin/ghc-pkg" --package-db=$out/lib/ghc-${version}/package.conf.d recache
    '';

  doInstallCheck = true;
  installCheckPhase = ''
    # Sanity check, can ghc create executables?
    cd $TMP
    mkdir test-ghc; cd test-ghc
    cat > main.hs << EOF
      module Main where
      main = putStrLn "yes"
    EOF
    env -i $out/bin/ghc --make main.hs || exit 1
    echo compilation ok
    [ $(./main) == "yes" ]
  '';

  passthru = {
    targetPrefix = "";
    enableShared = false;
    hasHaddock = false;

    llvmPackages = null;

    # Our Cabal compiler name
    haskellCompilerName = "ghc-${version}";

    # Normal GHC derivations expose the hadrian derivation used to build them
    # here. In the case of debs we just make sure that the attribute exists,
    # as it is used for checking if a GHC derivation has been built with hadrian.
    hadrian = null;
  };

  meta = {
    homepage = "http://haskell.org/ghc";
    description = "Glasgow Haskell Compiler";
    license = lib.licenses.bsd3;
    platforms = builtins.attrNames ghcCrossBinaries;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    teams = [ lib.teams.haskell ];
  };
})
