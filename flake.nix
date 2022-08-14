{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    CMSIS = {
      url = "github:ARM-software/CMSIS_5/5.9.0";
      flake = false;
    };
    nrfx = {
      url = "github:NordicSemiconductor/nrfx/v2.9.0";
      flake = false;
    };
    bossa = {
      url = "github:arduino/BOSSA/1.9.1-arduino2";
      flake = false;
    };
  };

  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem (system:
    with builtins;
    let
      pkgs = import inputs.nixpkgs { inherit system; };
      pkgsCross = pkgs.pkgsCross.armv7l-hf-multiplatform;
      unwords = concatStringsSep " ";
      unwordsPrefix = prefix: xs: unwords (map (x: prefix + x) xs);
      linkerScript = ./src/linker_script.ld;
      startupFile = "${inputs.nrfx}/mdk/gcc_startup_nrf52840.S";
      cc = "arm-none-eabi-gcc";
      cxx = "arm-none-eabi-g++";
      ar = "arm-none-eabi-ar";
      objcopy = "arm-none-eabi-objcopy";
      definitions = unwordsPrefix "-D" [
        "NRF52840_XXAA"
        "NRFX_ATOMIC_USE_BUILT_IN"
        "NRFX_GPIOTE_ENABLED"
        "NRFX_SYSTICK_ENABLED"
        "NRFX_UART_ENABLED"
        "NRFX_UART0_ENABLED"
      ];
      mcuFlags = unwords [
        "-mcpu=cortex-m4"
        "-mthumb"
        "-mfpu=fpv4-sp-d16"
        "-mfloat-abi=hard"
      ];
      includeDirs = cmsis: nrfx: unwordsPrefix "-isystem" [
        "${cmsis}/include/CMSIS/Core/Include"
        "${nrfx}/include/nrfx"
        "${nrfx}/include/nrfx/drivers"
        "${nrfx}/include/nrfx/mdk"
        "${nrfx}/include/nrfx/soc"
        "${nrfx}/include/nrfx/templates"
      ];
      commonFlags = unwords [
        "-Os"
        "-fdata-sections"
        "-ffunction-sections"
        "--specs=nano.specs"
        "--specs=nosys.specs"
        "-Wl,--gc-sections ${mcuFlags}"
        definitions
      ];
      cFlagsNoIncludes = "-std=c17 ${commonFlags}";
      cFlags = "${cFlagsNoIncludes} ${includeDirs cmsis nrfx}";
      cxxFlagsNoIncludes = "-std=c++20 ${commonFlags}";
      cxxFlags = "${cxxFlagsNoIncludes} ${includeDirs cmsis nrfx}";

      ldFlags = unwords [
        "-L${inputs.nrfx}/mdk"
        "-T${linkerScript}"
        "-Wl,--print-memory-usage"
      ];
      nrfx = pkgs.stdenvNoCC.mkDerivation {
        name = "nrfx";
        version = "2.9.0";
        src = inputs.nrfx;
        patchPhase = ''
          sed -i 's/#define nrfx_atomic_t/#include <nrfx_atomic.h>\n#define nrfx_atomic_t nrfx_atomic_u32_t/' templates/nrfx_glue.h
          sed -i 's/#define NRFX_CTZ/#define __rbit()/' templates/nrfx_glue.h
          sed -i 's/#define NRFX_CLZ/#define __clz()/' templates/nrfx_glue.h
          sed -i 's/#define NRFX_ATOMIC_CAS(p_data, old_value, new_value)//' templates/nrfx_glue.h
          function cpdir() {
            mkdir -p include/nrfx/"$1"
            cp "$1"/*.h include/nrfx/"$1"
          }
          cpdir .
          cpdir drivers
          cpdir hal
          cpdir helpers
          cpdir mdk
          cpdir soc
          cpdir templates
          cp -r drivers/include/*.h include/nrfx/drivers
        '';
        buildPhase = ''
          for c in drivers/src/*.c helpers/*.c mdk/system_nrf52840.c; do
            echo compiling $c
            ${cc} ${cFlagsNoIncludes} ${includeDirs cmsis "/build/source"} -c -o /build/$(basename $c).o $c
          done
          ${ar} rcs /build/libnrfx.a /build/*.o
        '';
        installPhase = ''
          mkdir -p $out/include $out/lib
          cp -r /build/source/include/* $out/include
          cp /build/*.a $out/lib
        '';
        buildInputs = [ pkgs.gcc-arm-embedded ];
      };
      cmsis = pkgs.stdenvNoCC.mkDerivation {
        name = "cmsis";
        version = "5.9.0";
        src = inputs.CMSIS;
        buildPhase = ''
        '';
        installPhase = ''
          mkdir -p $out/include
          cp -r $src/CMSIS $out/include
          cp -r $src/Device $out/include
        '';
      };
      hello-arduino = pkgs.stdenvNoCC.mkDerivation rec { 
        name = "hello-arduino";
        version = "0.0.1";
        src = ./.;
        buildPhase = ''
          ${cxx} ${cxxFlags} -isystem$src/src -o ${name}.elf src/main.cpp ${nrfx}/lib/libnrfx.a ${startupFile} ${ldFlags} -Wl,-Map=${name}.map 
          ${objcopy} -O binary ${name}.elf ${name}.bin 
        '';
        installPhase = ''
          mkdir -p $out/bin
          cp ${name}.* $out/bin
        '';
        buildInputs = [ pkgs.gcc-arm-embedded ];
      };
      bossa = pkgs.bossa.overrideAttrs (attrs: {
        name = "bossa";
        version = "1.9.1-arduino2";
        src = inputs.bossa;
        patches = [];
      });
      arduino-reset = pkgs.writeShellApplication {
        name = "arduino-reset";
        text = ''python ${./reset.py} "$@"'';
        runtimeInputs = [ (pkgs.python3.withPackages (ps: [ ps.pyserial ])) ];
      };
      arduino-flash = pkgs.writeShellApplication {
        name = "arduino-reset";
        text = ''
          BIN_FILE=''${BIN_FILE:-$1}
          if [ -e "$SERIAL_NORMAL" ]; then
            echo Resetting port "$SERIAL_NORMAL"
            SERIAL="$SERIAL_NORMAL" arduino-reset
          fi
          if [ -e "$SERIAL_FLASH" ]; then
            echo "Flashing file $BIN_FILE to port $SERIAL_FLASH"
            bossac -d --port="$SERIAL_FLASH" -U -i -e -w "$BIN_FILE" -R
          else
            echo "Cannot find flashing port!" >&2
          fi
        '';
        runtimeInputs = [ arduino-reset ];
      };
    in
    {
      packages = {
        inherit hello-arduino cmsis nrfx;
        default = hello-arduino;
      };
      apps = {
        arduino-reset = inputs.flake-utils.lib.mkApp { drv = arduino-reset; };
        arduino-flash = inputs.flake-utils.lib.mkApp { drv = arduino-flash; };
      };

      devShells.default = (pkgs.mkShell.override { stdenv = pkgs.stdenvNoCC; }) {
        SERIAL_FLASH = "/dev/serial/by-id/usb-Arduino_Arduino_Nano_33_BLE_00000000000000001F5576BD69189856-if00";
        SERIAL_NORMAL = "/dev/serial/by-id/usb-Arduino_Nano_33_BLE_1F5576BD69189856-if00";
        BIN_FILE = "./result/bin/hello-arduino.bin";
        nativeBuildInputs = [ pkgs.arduino-cli bossa ];
      };
    });
}