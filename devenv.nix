{ pkgs, inputs, ... }:

{
  packages = [
    pkgs.hurl

    inputs.dagger.packages.${pkgs.stdenv.hostPlatform.system}.dagger

    # To manage mise environment
    pkgs.mise
  ];
}
