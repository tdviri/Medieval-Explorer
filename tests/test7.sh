#!/usr/bin/env bash
# tests movement to south and attempts past end


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
printf "s
s
s
s
s
s
s
s
s
s
s
s
s
n
quit
" > INPUT

echo "Testing the standard input $(awk '{printf "%s  ", $0}' INPUT) " >> DEBUG

${binary_fn} 0 > raw_output.txt < INPUT 2> STDERR
cat raw_output.txt | tr -d " " > output.txt

## going south quite a bit, but should have 6 total of these
line="108.*Small path in the park"
sciCnt=$(grep -i -E "${line// /}" output.txt | wc -l)

if [[  $sciCnt -eq 6 ]]; then
  echo "passed 'Small path in the park' count " >> DEBUG
else
  echo "sciCnt=$sciCount" >> DEBUG
  failed_test_with_exit "\033[38;5;1mFailed, found the wrong number of '108.*Small path in the park' in output expected 6 but found ${sciCnt} \033[0m\n"
  exit 1
fi

## should have 2 of these
line="105.*Park Entrance"
sciCnt=$(grep -i -E "${line// /}" output.txt | wc -l)

if [[  $sciCnt -eq 2 ]]; then
  echo "passed 'Park Entrance' count " >> DEBUG
else
  echo "sciCnt=$sciCount" >> DEBUG
  failed_test_with_exit "\033[38;5;1mFailed, found the wrong number of '105.*Park Entrance' in output expected 2 but found ${sciCnt} \033[0m\n"
  exit 1
fi

grep_opts="-i -E"
EXPECTED="
105.*Park Entrance
102.*Promenade
108.*Small path in the park
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







