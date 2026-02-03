{
  busybox = import <nix/fetchurl.nix> {
    url = "https://distfiles.smaeul.xyz/nix/n5rqavcp9wb04zdhzqyvkbhn3iams3f3-busybox";
    sha256 = "sha256-6efMwwiUTOWI3znvQvSFQ923k7zCDVEMeO4ud52Tpsc=";
    executable = true;
  };
  bootstrapTools = import <nix/fetchurl.nix> {
    url = "https://distfiles.smaeul.xyz/nix/hii6xw0ymmpdm8x580w5nz5bc3vldcrn-bootstrap-tools.tar.xz";
    sha256 = "sha256-lXJmFEP70NRr8fQ42Rck67WrteJQWW/H83r4Aqn/NuE=";
  };
}
