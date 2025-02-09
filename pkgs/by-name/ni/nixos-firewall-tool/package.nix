{
  stdenvNoCC,
  lib,
  bash,
  installShellFiles,
  shellcheck-minimal,
}:

stdenvNoCC.mkDerivation rec {
  name = "nixos-firewall-tool";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.fileFilter (file: !file.hasExt "nix") ./.;
  };

  strictDeps = true;
  buildInputs = [ bash ];
  nativeBuildInputs = [ installShellFiles ];

  postPatch = ''
    patchShebangs --host nixos-firewall-tool
  '';

  installPhase = ''
    installBin nixos-firewall-tool
    installManPage nixos-firewall-tool.1
    installShellCompletion nixos-firewall-tool.{bash,fish}
  '';

  # Skip shellcheck if GHC is not available, see writeShellApplication.
  doCheck =
    lib.meta.availableOn stdenvNoCC.buildPlatform shellcheck-minimal.compiler
    && (builtins.tryEval shellcheck-minimal.compiler.outPath).success;
  checkPhase = ''
    ${lib.getExe shellcheck-minimal} nixos-firewall-tool
  '';

  meta = with lib; {
    description = "A tool to temporarily manipulate the NixOS firewall";
    license = licenses.mit;
    maintainers = with maintainers; [
      clerie
      rvfg
      garyguo
    ];
    platforms = platforms.linux;
    mainProgram = "nixos-firewall-tool";
  };
}
