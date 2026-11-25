set shell := ["bash", "-euo", "pipefail", "-c"]

# Usage:
#   just top=blink srcs="src/*.vhd" load
#   just top=ws2812_top srcs="src/ws2812.v src/top.v" load
top  := "top"
srcs := "src/*"
cst  := "tangnano20k.cst"

BUILD  := "build"
DEVICE := "GW2AR-LV18QN88C8/I7"
FAMILY := "GW2A-18C"
FREQ   := "27"
BOARD  := "tangnano20k"

# fullname
synth_json      := join(BUILD, top + "_synth.json")
netlistsvg_json := join(BUILD, top + "_netlistsvg_synth.json")
netlistsvg_svg := join(BUILD, top + "_netlistsvg.svg")

pnr_json        := join(BUILD, top + "_pnr.json")
report_json     := join(BUILD, top + "_report.json")
placed_svg      := join(BUILD, top + "_placed.svg")
routed_svg      := join(BUILD, top + "_routed.svg")

bit             := join(BUILD, top + "_bitstream.fs")

# basename
gates_file_prefix   := join(BUILD, top + "_gates")

alias s     := synthesis
alias synth := synthesis

alias p    := place-and-route
alias pnr  := place-and-route

alias pnr-svg := place-and-route-svg

alias gui     := place-and-route-gui
alias pnr-gui     := place-and-route-gui
alias graphic := place-and-route-gui

alias b         := bitstream-generate
alias bit       := bitstream-generate
alias bitstream := bitstream-generate
alias fs        := bitstream-generate

alias l    := load-sram
alias load := load-sram
alias sram := load-sram

alias fl    := load-sram
alias flash := load-sram

alias d    := detect

# Miscs
default:
    @just --list

_builddir:
    mkdir -p {{BUILD}}

clean:
    rm -rf {{BUILD}}

[arg("flatten", long="flatten", value="true")]
svg flatten="false":
    just place-and-route-svg
    just netlistsvg {{if flatten == "true" { "--flatten" } else { "" }}}
    just yosys-svg {{if flatten == "true" { "--flatten" } else { "" }}}

# Synthesis
_yosys EXTRA="": _builddir
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    vhdl=(); vlog=()
    for f in {{srcs}}; do
      case "$f" in
        *.vhd|*.vhdl) vhdl+=("$f") ;;
        *.v|*.sv)     vlog+=("$f") ;;
      esac
    done
    if (( ${#vhdl[@]} + ${#vlog[@]} == 0 )); then
      echo "no sources matched: {{srcs}}" >&2; exit 1
    fi

    cmds=(); plugin=()
    if (( ${#vlog[@]} )); then
      cmds+=("read_verilog -sv ${vlog[*]}")
    fi
    if (( ${#vhdl[@]} )); then
      plugin=(-m ghdl)
      cmds+=("ghdl --std=08 --workdir={{BUILD}} ${vhdl[*]} -e {{top}}")
    fi
    if [[ -n '{{EXTRA}}' ]]; then
      cmds+=('{{EXTRA}}')
    fi

    script=$(printf '%s; ' "${cmds[@]}")
    echo "yosys ${plugin[*]} -p \"$script\""
    yosys "${plugin[@]}" -p "$script"

synthesis:
    just _yosys "synth_gowin -top {{top}} -json {{synth_json}}"

[arg("flatten", long="flatten", value="flatten")]
yosys-svg flatten="":
    just _yosys "hierarchy -top {{top}}; proc; opt; {{flatten}}; techmap; abc -g AND,OR,XOR,NAND,NOR,XNOR; opt; show -format svg -prefix {{gates_file_prefix}} {{top}}"

[arg("flatten", long="flatten", value="-flatten")]
netlistsvg flatten="":
    just _yosys "prep -top {{top}} {{flatten}}; write_json {{netlistsvg_json}}"
    netlistsvg {{netlistsvg_json}} -o {{netlistsvg_svg}}

# Place and route
_place-and-route ARGS="":
    nextpnr-himbaechel \
        --device "{{DEVICE}}" \
        --vopt family={{FAMILY}} \
        --vopt cst={{cst}} \
        --freq {{FREQ}} \
        --json {{synth_json}} \
        --write {{pnr_json}} \
        --report {{report_json}} \
        --detailed-timing-report \
        {{ARGS}}

place-and-route: synthesis
    just _place-and-route

place-and-route-svg: synthesis
    just _place-and-route "--placed-svg {{placed_svg}} --routed-svg {{routed_svg}}"

place-and-route-gui: synthesis
    just _place-and-route "--placed-svg {{placed_svg}} --routed-svg {{routed_svg}} --gui"

# Bitsteam
bitstream-generate: place-and-route
    gowin_pack -d {{FAMILY}} -o {{bit}} {{pnr_json}}

# Flashing
load-sram: bitstream-generate
    openFPGALoader -b {{BOARD}} {{bit}}

load-permanent: bitstream-generate
    openFPGALoader -b {{BOARD}} {{bit}} -f

detect:
    openFPGALoader -b {{BOARD}} --detect
