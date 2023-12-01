#!/usr/bin/env bash
# tests gets and drops

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

printf "get
s
get
s
get
n
n
drop
5
get
s
s
w
drop
5
quit
" > INPUT

echo "Testing the standard input $(awk '{printf "%s  ", $0}' INPUT) " >> DEBUG

${binary_fn} 0 > raw_output.txt < INPUT 2> STDERR
cat raw_output.txt | tr -d " " > output.txt

line="You see a scimitar blade"
sciCnt=$(grep -i "${line// /}" output.txt | wc -l)

if [[  $sciCnt -eq 3 ]]; then
  echo "passed scimitar count " >> DEBUG
else
  echo "sciCnt=$sciCount"
  "\033[38;5;1mFailed, found the wrong number of 'You see a scimitar blade' in output \033[0m\n"
  failed_test_with_exit "\033[38;5;1mFailed, found the wrong number of 'You see a scimitar blade' in output expected 3 but found ${sciCnt} \033[0m\n"
  exit 1
fi

echo 'p' > RESULT
log_pos "PASSED, found all expected output"







