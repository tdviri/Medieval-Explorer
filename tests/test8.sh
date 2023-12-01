#!/usr/bin/env bash
# tests empty inventory


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ -d /usercode ]]; then
  cd /usercode
else
  cd "$DIR/.."
fi

find . -maxdepth 1 -type f -regex '.*/[A-Z_]+$' -delete

find ./ -type f -executable -exec sh -c 'head -c 4 "{}" | grep -a -q "^.ELF"' \; -delete

if [[ -f  "$DIR/zybook_test_common.sh" ]]; then
    source "$DIR/zybook_test_common.sh"
fi

compile "main.c"

binary_fn=$(find ./ -type f -executable -exec sh -c 'head -c 4 "{}" | grep -a -q "^.ELF"' \; -print)

# input
printf "i
quit
" > INPUT

echo "Testing the standard input $(awk '{printf "%s  ", $0}' INPUT) " >> DEBUG

${binary_fn} 0 > raw_output.txt < INPUT 2> STDERR
cat raw_output.txt | tr -d " " > output.txt

grep_opts="-i -E"
EXPECTED="nothing in your backpack
"

while read -r line; do

  if grep ${grep_opts} "${line// /}" output.txt > /dev/null ; then
    continue
  else
    failed_test_with_exit "\033[38;5;1mFAILED to find '${line}' in output \033[0m\n"
    exit 1
  fi

done <<< $EXPECTED

echo 'p' > RESULT
log_pos "PASSED, found all expected output"







