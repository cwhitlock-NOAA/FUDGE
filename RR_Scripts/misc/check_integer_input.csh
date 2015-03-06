#!/bin/csh -f
echo " "

set input=$1
echo $input

if ( `echo $input | grep -P '^\d+$'` != "" ) then
echo "   You entered $input . An integer was expected."
exit 1
else
echo "   You entered $input . "
endif
