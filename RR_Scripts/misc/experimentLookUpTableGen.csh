#
# gs_sortable.js is from 
# http://www.allmyscripts.com/Table_Sort/gs_sortable.js  (gs_sortable.js v1.8)
#

set expSeries = B
set regionID = "RR"
set platformID = "p1"
set obsID = "L01"
set kfold = 0
  if ($kfold <= 9) set kfoldID = "K0$kfold"
  if ($kfold >= 10) set kfoldID = "K$kfold"

\rm RR_exp.html

cat >> RR_exp.html<<EOF 
<html>
<!-- uses gs_sortable.js  from http://www.allmyscripts.com/Table_Sort/gs_sortable.js (v1.8) -->
<script type="text/javascript" src="./gs_sortable.js"></script>
<script type="text/javascript">
<!--
var TSort_Data = new Array ('exp_info', 's', 's', 's', 's', 's', 's', 's');
tsRegister();
// -->
</script>
<table id="exp_info">
<thead>
<tr align="left"><th width=20%>Name</th><th width=10%>DS Method   </th><th width=10%>Series    </th><th width=10%>GCM    </th><th width=10%>Epoch    </th><th width=10%>Obs    </th><th width=10%>Kfold    </th><th width=10%></tr>
</thead>
EOF

set k=0
foreach dsMethod (CDFt BCQM EDQM)
foreach varID (tx tn pr)
foreach gcm (CCSM4 MIROC5 "MPI-ESM-LR")
   if ($gcm == "CCSM4") set gcmID = 1
   if ($gcm == "MIROC5") set gcmID = 2
   if ($gcm == "MPI-ESM-LR") set gcmID = 3
foreach epoch (historical rcp45 rcp85)
   if ($epoch == "historical") set epochID = 0
   if ($epoch == "rcp45") set epochID = 4
   if ($epoch == "rcp85") set epochID = 8

  set expName = "${regionID}${varID}${platformID}-${dsMethod}-${expSeries}${gcmID}${epochID}${obsID}${kfoldID}"

  @ k++
  echo "<tr><td width=20%>$expName</td><td width=10%>${dsMethod}</td><td width=10%>${expSeries}</td><td width=10%>$gcm</td><td width=10%>$epoch</td><td width=10%>${obsID}</td><td width=10%>${kfoldID}</td><td width=10%></tr>" >> RR_exp.html
end
end
end
end
echo "</table>" >> RR_exp.html
echo "</html>" >> RR_exp.html
