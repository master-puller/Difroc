#!/bin/bash
# DIFROCQ "diff-rock"
# Daniel Starr 2024
usage() {
  echo "Usage: $0 [OPTION] cmd [CMDOPTS]"
  echo "Diffs command outputs against files in dir"
  echo "DIFROCQ is NOT SANITIZED. DO NOT USE WITH UNTRUSTED INPUT"
  echo "Options:"
  echo "     -d --dir [DIR]              directory of test files"
  echo "         defaults to \"./tests/\""
  echo "     -i --inext [INEXT]          input file extension"
  echo "         defaults to \".in\""
  echo "     -f --force                  force run even if overwrites will occur"
  echo "     -r --runext [RUNEXT]        run file extension"
  echo "         defaults to \".run\""
  echo "     -o --outext [OUTEXT]        output (test expected) file extension"
  echo "         defaults to \".out\""
  echo "     -c --cleanup                removes run files afterward"
  echo "     -q --quiet                 only outputs which files mismatch"
}

# Default args
dir_test="./tests/"
in_ext=".in"
force=false
run_ext=".run"
out_ext=".out"
clean_up=false
quiet=false

options_passed=false

while getopts "d:i:fr:o:cq" opt; do
  options_passed=true
  case $opt in
    d|--dir)
      dir_test="$OPTARG"
      ;;
    i|--inext)
      in_ext="$OPTARG"
      ;;
    f|--force)
      force=true
      ;;
    r|--runext)
      run_ext="$OPTARG"
      ;;
    o|--outext)
      out_ext="$OPTARG"
      ;;
    c|--cleanup)
      clean_up=true
      ;;
    q|--quiet)
      quiet=true
      ;;
    \?)
      echo "Option is not DIFROCQ (Invalid option): -$OPTARG"
      usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument"
      usage
      exit 1
      ;;
  esac
done

command=
shift $((OPTIND-1))

#TODO: check if .run will overwrite a file, and warn, unless $force

if [ options_passed ]; then
  if [ $# -eq 0 ]; then
    echo "Error: command argument is required."
    usage
    exit 1
  else
    if ! command -v $1 &> /dev/null; then
      echo "Error: command \"$1\" not found"
      exit 1
    fi
    command=$1
    shift
  fi
else
  usage
  exit 0
fi

cmdopts=()
while [[ "$#" -gt 0 ]]; do
  cmdopts+=("$1")
  shift
done

for file in "$dir_test"*"$in_ext"; do
  if [ ! -f "$file" ]; then
    break 2
  fi
  base_name="${file/$in_ext/}"
  run_name="${base_name}${run_ext}"
  expected_name="${base_name}${out_ext}"
  if [ -e $run_name ] && [ $force = false ]; then
    echo file "$run_name" exists! preventing overwrite.
    echo use --force if you really want to overwrite!
    exit 1
  fi
  # run the command
  "$command" "${cmdopts[@]}" < "$file" > "$run_name"
  diff_res="$(diff $run_name $expected_name)"
  if [ $clean_up = true ]; then
    rm -f -- "$run_name"
  fi
  if [ -n "$diff_res" ]; then
    if ! $quiet; then
      echo =======================
      echo "Mismatch with $file: "
      echo "$diff_res"
    else
      echo "$file"
    fi
  fi
done
# for file in "$test_dir"/*.in; do
