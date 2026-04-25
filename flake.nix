{
  description = "Gradia - Make your screenshots ready for the world";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      # Python with required packages
      pythonEnv = pkgs.python3.withPackages (ps:
        with ps; [
          pygobject3
          pillow
          pytesseract
          # Add other Python deps as needed
        ]);

      gradia = pkgs.stdenv.mkDerivation rec {
        pname = "gradia";
        version = "1.13.0";

        src = ./.;

        nativeBuildInputs = with pkgs; [
          meson
          ninja
          pkg-config
          gobject-introspection
          wrapGAppsHook4
          blueprint-compiler
          gettext
          desktop-file-utils
        ];

        buildInputs = with pkgs; [
          pythonEnv
          python3Packages.pygobject3
          gtk4
          libadwaita
          gtksourceview5
          libportal
          libportal-gtk4
          gsettings-desktop-schemas
          glib
          gdk-pixbuf
          libsoup_3
        ];

        propagatedBuildInputs = with pkgs; [
          pythonEnv
        ];

        postPatch = ''
          substituteInPlace gradia/constants.in \
            --subst-var-by PKGDATA_DIR $out/share/gradia \
            --subst-var-by ROOT_PATH /be/alexandervanhee/gradia \
            --subst-var-by VERSION ${version} \
            --subst-var-by BUILD_TYPE debug \
            --subst-var-by APP_ID be.alexandervanhee.gradia
        '';

        preFixup = ''
          makeWrapperArgs+=(
            --prefix PYTHONPATH : "$out/lib/python${pythonEnv.pythonVersion}/site-packages"
            --prefix GI_TYPELIB_PATH : "$GI_TYPELIB_PATH"
            --prefix XDG_DATA_DIRS : "$out/share/gsettings-schemas/gradia-${version}"
          )
        '';

        meta = with pkgs.lib; {
          description = "Make your screenshots ready for the world";
          homepage = "https://gradia.alexandervanhee.be/";
          license = licenses.gpl3Plus;
          maintainers = [];
        };
      };
    in {
      packages = {
        default = gradia;
        gradia = gradia;
      };

      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          # Build tools
          meson
          ninja
          pkg-config
          gobject-introspection
          wrapGAppsHook4
          blueprint-compiler
          gettext
          desktop-file-utils

          # Runtime dependencies
          pythonEnv
          python3Packages.pygobject3
          gtk4
          libadwaita
          gtksourceview5
          libportal
          libportal-gtk4
          gsettings-desktop-schemas
          glib
          gdk-pixbuf
          libsoup_3

          # Additional dev tools
          git
        ];

        shellHook = ''
          echo "Gradia development shell"
          echo ""
          echo "To build and run locally:"
          echo "  meson setup build --prefix=\$PWD/install"
          echo "  meson compile -C build"
          echo "  meson install -C build"
          echo "  ./install/bin/gradia"
          echo ""
          echo "Or use nix build:"
          echo "  nix build .#gradia"
          echo "  result/bin/gradia"
        '';
      };
    });
}
