#!/bin/csh -f
# QueryVals.csh is "source"-d from within xmlGen.csh script. It acts like a function
#  which prints to standard output the contents of a preset string variable "dinfo"
#  and numerates a list of values pre-set in variable "varvals", then awaits input
#  of a number associated with each element (input can be interactive or from input file.)
# 
# PRE-SET variables in shell from which QueryVals.csh is "source"-d:
#
#   "varvals" == list of variables the user can select by entering number associated with the variable.
#                1st variable in the list get number "1", 2nd gets number "2", etc.
#   "dinfo"   == string that describes what the selection from the variable list is about.
#
# OUTPUT 
# 
#   "kvar"    == the numeric value of the option selected, and is then used in the shell
#                as well as written to local file "InputValues.txt". (so user can re-run without having 
#                to re-type all option selections.)
#

if (! $?dinfo) then
echo "Please set 'dinfo' = to a string describing what you are querying ."
exit 1
endif

if ($?varvals) then
unset ok
unset kvar
while (! $?ok) 
  echo "============================================="
  echo " "
  echo "   For  ${dinfo}"
  echo " "
  echo "============================================="
  echo " "
  echo "   Options = "
  set n=1
  while ($n <= $#varvals)
    echo "     $n  $varvals[$n]"
    @ n = $n + 1
  end
  echo " "
  echo -n ">>> Enter the integer associated with the option desired: "
  set kvar=$<
  
  echo ""

  if ( `echo $kvar | grep -P '^\d+$'` != "" ) then
     if ($kvar > 0 && $kvar <= $#varvals) then 
       set ok
       echo "   You chose $varvals[$kvar] ."
       echo ""
     else
       echo "   You entered $kvar . Please enter the integer associated with the option desired."
     endif
  else
     echo "   You entered $kvar . Please enter the integer associated with the option desired."
  endif
end

echo $kvar >> ./InputValues.txt
sleep 1
else
echo  "You must define options in "varvals"."
exit 1
endif
