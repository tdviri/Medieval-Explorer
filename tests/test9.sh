#!/usr/bin/env bash
# tests for malloc to heap


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

newCode='
int * test = malloc(sizeof(int));
printf("testloc:%p\\n", test);
printf("rooms:%p\\n", rooms);
printf("objects:%p\\n", objects);
free(test);
'

cp main.c main_test.c

sed -i "s|// INSERT TEST HERE|${newCode//$'\n'/\\$'\n'}|g" main_test.c

compile "main_test.c"
cat main_test.c
rm -f main_test.c

# input
printf "i
quit
" > INPUT

echo "Testing the standard input $(awk '{printf "%s  ", $0}' INPUT) " >> DEBUG
${binary_fn} 0 > raw_output.txt < INPUT 2> STDERR

grep_opts="-i "
EXPECTED=""
baseval=$(grep "testloc:0x[0-9a-z]+" ./raw_output.txt | cut -d":" -f2 )
roomsval=$(grep "rooms:0x[0-9a-z]+" ./raw_output.txt | cut -d":" -f2 )
objectsval=$(grep "objects:0x[0-9a-z]+" ./raw_output.txt | cut -d":" -f2 )
baseval=$(( baseval - 0x10000 ))

if grep -i -E "testloc:0x[0-9a-f]+" ./raw_output.txt && grep -i  -E "rooms:0x[0-9a-f]+" ./raw_output.txt  && grep -i  -E "objects:0x[0-9a-f]+" ./raw_output.txt ; then
  echo "found the address values"
else
  failed_test_with_exit "\033[38;5;1mFAILED to find the address values in the output, did you put the // INSERT TEST HERE in the correct place? \033[0m\n"
  exit 1
fi

if [[ $baseval -gt $roomsval ]]; then
      failed_test_with_exit "\033[38;5;1mFAILED to detect rooms being on the heap base addr=$baseval, rooms addr=$roomsval \033[0m\n"
      exit 1
fi
if [[ $baseval -gt $objectsval ]]; then
      failed_test_with_exit "\033[38;5;1mFAILED to detect rooms being on the heap base addr=$baseval, objects addr=$roomsval \033[0m\n"
      exit 1
fi
printf "%x %x %x\n"  $baseval $roomsval $objectsval
cat raw_output.txt

echo 'p' > RESULT
log_pos "PASSED, found all expected output"
