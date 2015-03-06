#!/bin/csh -f
echo " "
echo " "
echo "   CDFt method allows user to set options for 'dev' and 'npas'."
echo " "
set maxdev = 5
set dinfo = " = the coefficient of development (of the difference between the mean of the large-scale historical data and the mean of the large-scale future data to be down-scaled). This development is used to extend range of data on which the quantiles will be calculated for the CDF to be downscaled. (Package developers suggest dev=2, but we often use 1.)"
echo -n "   Please enter the value for 'dev' $dinfo : "

unset ok
while (! $?ok) 
  set dev=$<
  echo $dev
  if ( `echo $dev | grep -P '^\d+$'` != "" ) then
     if ($dev > 0 && $dev <= $maxdev) then 
       set ok
       echo " "
       echo "   You chose $dev ."
       echo " "
     else
       echo "   You entered $dev . Please enter the integer associated with a ${dinfo}."
     endif
  else
     echo "   You entered $dev . Please enter the integer associated with a ${dinfo}."
  endif
end

echo "   Please enter the value for 'npas' (integer 1 through maximum # of days per time window)."
set dinfo = "If you want to use maximum # of days per time window, just hit return or enter 'default' or 0 "
echo -n "   ${dinfo} : "

unset ok
while (! $?ok) 
  set npas=$<
  echo $npas
  echo " "
  if ($npas == "default" || $npas == "'default'" || $npas == "" || $npas == "0") then 
     set npas = "'default'"
     echo "   Will use   npas = 0 ."
     set ok
  else if ( `echo $npas | grep -P '^\d+$'` != "" ) then
     if ($npas > 0) then 
       set ok
       echo "   Will use   npas = $npas ."
     else
       echo "   PROBLEM:   You entered $npas . ${dinfo}."
     endif
  else
     echo "   PROBLEM:   You entered $npas . ${dinfo}."
  endif
end

echo $dev >> ./InputValues.txt
echo $npas >> ./InputValues.txt

cat >> XMLfile <<EOF
        <dev>$dev</dev>
        <npas>$npas</npas>
EOF
