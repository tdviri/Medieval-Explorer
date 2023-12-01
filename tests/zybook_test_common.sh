#! /usr/bin/env bash
testcnt=1
binary_fn="./a.out"
output_fn="./output.txt"

function failed_test_with_exit(){
    printf "$1" >> DEBUG
    showOutput
    echo "np" > RESULT
    exit 66
}

# Function to be called upon exit
function on_exit() {
    echo "Exiting tester." >> DEBUG
}

# Trap the exit signal to call on_exit function
trap on_exit EXIT

function compile(){
  binary_fn=$(find ./ -type f -executable -exec sh -c 'head -c 4 "{}" | grep -a -q "^.ELF"' \; -print)
  filesize=0;
  if [[ -f ./Makefile ]]; then
    filesize=$(wc -c < "./Makefile")
  fi
  if [[ -z "$binary_fn" ]]; then
    binary_fn="./a.out"
  fi
  if [[ $filesize -gt 20 ]]; then
    rm -f ${binary_fn}
    make >> COMPILE_OUTPUT 2>&1
    compile_ret=$?
  else

    rm -f ${binary_fn}

    gcc $@ -Wall -Werror -g -o ${binary_fn} >> COMPILE_OUTPUT 2>&1
    compile_ret=$?
    cat COMPILE_OUTPUT >> DEBUG

  fi

  if [[ $compile_ret -ne 0 ]]; then
      printf "\t\033[38;5;3mFAILED to compile " >> DEBUG
      cat COMPILE_OUTPUT >> DEBUG
      echo "np" > RESULT
      exit 44
  fi
}

# source code tests
function sourceCodeTest(){
  local grep_opts="-i -E"
  local breakPoint=$1
  local extraCmdsFile=$2
  local expectedResults=$3
  local failMsg=$4
  printf "
  set disable-randomization off
  b ${breakPoint}
  run
  list
  " > /tmp/tmp_extra

  cat $extraCmdsFile >> /tmp/tmp_extra
  gdb ./a.out --batch -x /tmp/tmp_extra |tr -d " " > /tmp/debuggercode

  EXPECTED="printf\(.a=\%.,pA=\%.,\&a=.p,pA=\%.{2,4},a,\*pA,\&a,pA"
  while read -r line; do
      if grep ${grep_opts} "$line" /tmp/debuggercode > /dev/null ; then
          continue;
      else
          log_neg "\033[38;5;1mFAILED code check \033[0m\n"
          log_neg "\t\033[38;5;3m $failMsg \033[0m \n"
          echo "*********** GDB OUTPUT ***********" >> DEBUG
          cat /tmp/debuggercode >> DEBUG
          echo "*********** END OUTPUT ***********" >> DEBUG
          echo "np" > RESULT
          exit 33
      fi
  done <<< $expectedResults
}

function showOutput() {

	if [[ ! -z "$@" ]]; then
		echo "Arguments to main.sh : '$@' "  >> DEBUG
	fi
	if [[ -f INPUT ]]; then
	  echo "---- std input to main.sh ---- " >> DEBUG
	  cat INPUT >> DEBUG
	fi
	if [[ -f raw_output.txt ]]; then
    echo -e "\n---- std out from main.sh ---- " >> DEBUG
    cat raw_output.txt >> DEBUG
  fi
  if [[ -f STDERR ]]; then
    echo -e "\n---- std err from main.sh ---- " >> DEBUG
    cat STDERR >> DEBUG
  fi
  if [[ -f RESULT ]]; then
    echo -e "\n------------------------------ " >> DEBUG
    echo "np" > RESULT
  fi
}

# Function to generate a random directory name
generate_random_name() {
    head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8
}

log_pos() {
    msg="$1"
    printf "\t${testcnt}. \033[38;5;10m✔ ️$msg\033[0m\n" >> DEBUG
    testcnt=$(( testcnt + 1 ))
}
log_neg() {
    msg="$1"
    printf "\n\033[38;5;9m$msg\033[0m\n" >> DEBUG
    echo "np" > RESULT
}

log_and_exec(){
    ## print the command to the logfile
    printf "\033[38;5;8m%s\033[0m\n" "$@" >> DEBUG
    ## run the command and redirect it's error output
    ## to the logfile
    eval "$@" >> DEBUG 2>&1
}



generate_random_face() {
    # Define an array of emoji faces
    faces=("😀" "😁" "😂" "🤣" "😃" "😄" "😅" "😆" "😉" "😊" "😋" "😎" "😍" "😘" "🥰" "😚" "😗" "😙" "😜" "😝" "🤤" "😪" "😫" "😴" "😌" "😛" "😏" "😒" "😞" "😔" "😟" "😖" "😣" "😓" "😭" "😢" "😮" "😲" "😳" "🥺" "😦" "😧" "😨" "😰" "😥" "😓" "🤗" "🤔" "🤭" "🤫" "🤥" "😶" "😐" "😑" "😬" "🙄" "😯" "😴" "😌" "😛" "😜" "😝" "🤤" "😒" "😔" "😪" "🤐" "🤨" "🤓" "😈" "👿" "🤑" "🤠" "😷" "🤧" "🥵" "🥶" "🥴" "😵" "🤯" "🤠" "🥳" "😎" "🤓" "🧐" "😕" "😟" "🙁" "☹" "😮" "😯" "😲" "😳" "🥵" "🥶" "😱" "😨" "😰" "😥" "😓" "🥱" "😴" "😩" "😫" "😤" "😡" "😠" "🤬" "😈" "👿")

    # Get the size of the array
    size=${#faces[@]}

    # Generate a random index
    index=$((RANDOM % size))

    # Print the emoji face at the randomly chosen index
    echo ${faces[$index]}
}

clean_string() {
    echo "$1" | sed 's/ //g'
}

# Main evaluation function
evaluate_strings() {
    # $1 is Expected, $2 is actual output
    local str1=$(clean_string "$1")
    local str2=$(clean_string "$2")

    # Split the cleaned strings based on commas.
    IFS=',' read -ra str1_arr <<< "$str1"
    IFS=',' read -ra str2_arr <<< "$str2"

    local length=${#str1_arr[@]}
    for ((i=0; i<$length; i++)); do
        if [[ "${str1_arr[$i]}" != "${str2_arr[$i]}" ]]; then
            echo "Arr[$i] : Difference b/t Expected: '${str1_arr[$i]}' but found: '${str2_arr[$i]}'" >> DEBUG
        else
            echo "Arr[$i] : '${str1_arr[$i]}' OK " >> DEBUG
        fi
    done
}




