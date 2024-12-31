let
  nixpkgs-src = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/634fd46801442d760e09493a794c4f15db2d0cbb.tar.gz";
    sha256 = "sha256-NYVcA06+blsLG6wpAbSPTCyLvxD/92Hy4vlY9WxFI1M=";
  };
in

with import nixpkgs-src { };

let
  listToQtVar = suffix: lib.makeSearchPathOutput "bin" suffix;
in
mkShell {
  name = "masquerade-shell";

  packages = with pkgs; [
    editorconfig-checker

    qt6.qtbase
    qt6.qtdeclarative
  ];

  env = {
    QT_PLUGIN_PATH = listToQtVar qt6.qtbase.qtPluginPrefix (
      with qt6;
      [
        qtbase
        qtwayland
      ]
    );
    QML2_IMPORT_PATH = listToQtVar qt6.qtbase.qtQmlPrefix (
      with qt6;
      [
        qtdeclarative
      ]
    );
  };
}
