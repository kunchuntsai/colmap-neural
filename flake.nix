{
  description = "Enhanced COLMAP with neural network capabilities for Apple M4 Pro";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-23.11-darwin";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            # Permit insecure packages that COLMAP needs
            permittedInsecurePackages = [
              "freeimage-unstable-2021-11-01"
            ];
            allowUnfree = true;  # Needed for CUDA
          };
        };
        
        # Core dependencies for all platforms
        baseDeps = with pkgs; [
          # Build tools
          cmake
          ninja
          pkg-config
          gcc
          git

          onnxruntime
          
          # Core libraries
          boost
          eigen
          glog
          gflags
          ceres-solver
          
          # Image processing
          opencv
          freeimage  # Note: This might be marked as insecure
          
          # FLANN for feature matching
          flann
          
          # Graphics dependencies
          glew
          freeglut
          mesa

          # COLMAP additional dependencies
          sqlite
          qt5.qtbase
          
          # CGAL and related dependencies
          cgal
          gmp
          mpfr
          lz4
          
          # Python packages
          (python3.withPackages (ps: with ps; [
            pip
            setuptools
            wheel
            numpy
            pytorch
            torchvision
            matplotlib
            scipy
            pandas
          ]))
        ];
        
        # CUDA-specific dependencies (for NVIDIA GPUs)
        cudaDeps = with pkgs; lib.optionals (system != "aarch64-darwin" && system != "x86_64-darwin") [
          cudaPackages.cudatoolkit
          cudaPackages.cudnn
        ];
        
        # Metal-specific dependencies (for macOS/Apple Silicon)
        metalDeps = with pkgs; lib.optionals (system == "aarch64-darwin" || system == "x86_64-darwin") [
          darwin.apple_sdk.frameworks.Metal
          darwin.apple_sdk.frameworks.MetalKit
          darwin.apple_sdk.frameworks.CoreML
          darwin.apple_sdk.frameworks.Accelerate
          darwin.apple_sdk.frameworks.CoreGraphics
          darwin.apple_sdk.frameworks.CoreFoundation
          darwin.apple_sdk.frameworks.Foundation
        ];

        # Function to create a development shell with configurable options
        mkDevShell = { withDebug ? false, withCuda ? pkgs.stdenv.isLinux, withMetal ? pkgs.stdenv.isDarwin }:
          pkgs.mkShell {
            buildInputs = baseDeps 
              ++ (if withCuda then cudaDeps else [])
              ++ (if withMetal then metalDeps else [])
              ++ (if withDebug then [ pkgs.gdb pkgs.valgrind ] else []);
            
            shellHook = ''
              export COLMAP_NEURAL_ROOT=$(pwd)
              export PATH=$COLMAP_NEURAL_ROOT/scripts:$PATH
              
              # Configure paths for libraries that might be hard to find
              export BOOST_ROOT=${pkgs.boost}
              export EIGEN3_ROOT=${pkgs.eigen}
              export FLANN_ROOT=${pkgs.flann}
              export CERES_ROOT=${pkgs.ceres-solver}
              export GLOG_ROOT=${pkgs.glog}
              export GFLAGS_ROOT=${pkgs.gflags}
              export GMP_ROOT=${pkgs.gmp}
              export MPFR_ROOT=${pkgs.mpfr}
              export CGAL_ROOT=${pkgs.cgal}
              export FREEIMAGE_ROOT=${pkgs.freeimage}
              
              # Add symlinks to ensure paths match what CGAL expects
              mkdir -p $HOME/.nix-shell-links
              ln -sf ${pkgs.mpfr}/include $HOME/.nix-shell-links/mpfr-include
              ln -sf ${pkgs.gmp}/include $HOME/.nix-shell-links/gmp-include
              
              # Configure build type
              if [ "${toString withDebug}" = "true" ]; then
                export CMAKE_BUILD_TYPE=Debug
              else
                export CMAKE_BUILD_TYPE=Release
              fi
              
              # Configure GPU acceleration
              if [ "${toString withCuda}" = "true" ]; then
                export WITH_CUDA=ON
              else
                export WITH_CUDA=OFF
              fi
              
              if [ "${toString withMetal}" = "true" ]; then
                export WITH_METAL=ON
              else
                export WITH_METAL=OFF
              fi
              
              echo "COLMAP Neural Enhancement Development Environment"
              echo "================================================="
              echo "Build type: $CMAKE_BUILD_TYPE"
              echo "CUDA support: $WITH_CUDA"
              echo "Metal support: $WITH_METAL"
              echo
              echo "Run './scripts/build.sh' to build the project"
              echo "Run './scripts/run.sh --help' for usage information"
            '';
          };
      in
      {
        packages = {
          colmap = pkgs.stdenv.mkDerivation {
            pname = "colmap";
            version = "3.8";
            
            src = pkgs.fetchFromGitHub {
              owner = "colmap";
              repo = "colmap";
              rev = "3.8";
              sha256 = "sha256-FWVyUxrJ2lBP5tgYLBLXOPRV0QxNxv28A96rMsJZduw=";
            };
            
            nativeBuildInputs = with pkgs; [ cmake ninja pkg-config ];
            buildInputs = baseDeps
              ++ (if system != "aarch64-darwin" && system != "x86_64-darwin" then cudaDeps else metalDeps);
            
            cmakeFlags = [
              "-DCMAKE_BUILD_TYPE=Release"
              "-DTESTS_ENABLED=OFF"
              "-DCGAL_DO_NOT_WARN_ABOUT_CMAKE_BUILD_TYPE=ON"
              "-DCMAKE_POLICY_DEFAULT_CMP0074=NEW"
              "-DCMAKE_PREFIX_PATH=$HOME/.nix-shell-links"
            ] ++ (if pkgs.stdenv.isDarwin then [
              "-DCUDA_ENABLED=OFF" 
              "-DMETALPETAL_ENABLED=ON"
            ] else [
              "-DCUDA_ENABLED=ON"
              "-DMETALPETAL_ENABLED=OFF"
            ]);

            preConfigure = ''
              # Create symlinks to ensure paths match what CGAL expects
              mkdir -p $HOME/.nix-shell-links
              ln -sf ${pkgs.mpfr}/include $HOME/.nix-shell-links/mpfr-include
              ln -sf ${pkgs.gmp}/include $HOME/.nix-shell-links/gmp-include
            '';
            
            meta = with pkgs.lib; {
              description = "Structure-from-Motion and Multi-View Stereo";
              homepage = "https://colmap.github.io/";
              license = licenses.bsd3;
              platforms = platforms.unix;
            };
          };
          
          default = pkgs.stdenv.mkDerivation {
            pname = "colmap-neural";
            version = "0.1.0";
            
            src = self;
            
            nativeBuildInputs = with pkgs; [ cmake ninja pkg-config ];
            buildInputs = baseDeps 
              ++ (if pkgs.stdenv.isDarwin then metalDeps else cudaDeps)
              ++ [ self.packages.${system}.colmap ];
            
            cmakeFlags = [
              "-DCMAKE_BUILD_TYPE=Release"
              "-DCGAL_DO_NOT_WARN_ABOUT_CMAKE_BUILD_TYPE=ON"
              "-DCMAKE_POLICY_DEFAULT_CMP0074=NEW"
              "-DCMAKE_PREFIX_PATH=$HOME/.nix-shell-links"
            ] ++ (if pkgs.stdenv.isDarwin then [
              "-DWITH_METAL=ON"
              "-DWITH_CUDA=OFF"
            ] else [
              "-DWITH_CUDA=ON"
              "-DWITH_METAL=OFF"
            ]);

            preConfigure = ''
              # Create symlinks to ensure paths match what CGAL expects
              mkdir -p $HOME/.nix-shell-links
              ln -sf ${pkgs.mpfr}/include $HOME/.nix-shell-links/mpfr-include
              ln -sf ${pkgs.gmp}/include $HOME/.nix-shell-links/gmp-include
            '';
            
            meta = with pkgs.lib; {
              description = "Enhanced COLMAP with neural network capabilities";
              homepage = "https://github.com/your-username/colmap-neural";
              license = licenses.bsd3;
              platforms = platforms.unix;
            };
          };
        };
        
        devShells = {
          default = mkDevShell {
            withDebug = false;
            withCuda = !pkgs.stdenv.isDarwin;
            withMetal = pkgs.stdenv.isDarwin;
          };
          
          debug = mkDevShell {
            withDebug = true;
            withCuda = !pkgs.stdenv.isDarwin;
            withMetal = pkgs.stdenv.isDarwin;
          };
          
          cuda = mkDevShell {
            withDebug = false;
            withCuda = true;
            withMetal = false;
          };
          
          metal = mkDevShell {
            withDebug = false;
            withCuda = false;
            withMetal = true;
          };
        };
      }
    );
}