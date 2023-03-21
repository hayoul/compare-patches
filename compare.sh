#!/bin/bash
vm1=$1
vm2=$2
comparefolder=/tmp/comparefolder-$$
silentconnect="-q -o StrictHostKeyChecking=no"
diffile=$comparefolder/diff.txt
echo
mkdir -p $comparefolder/$vm1 & mkdir -p $comparefolder/$vm2

pathvm1=`ssh $silentconnect root@$vm1 'find / -type d -wholename "*sat0/modules/updates"'`
pathvm2=`ssh $silentconnect root@$vm2 'find / -type d -wholename "*sat0/modules/updates"'`

getpatch(){
 vm=$1
 path=$2
 scp $silentconnect  planisware@$vm:$path/*.obin $comparefolder/$vm
}
cd $comparefolder

echo "Calculating difference... (might take ~ 2 minutes)"
ls
#diff -q <(ssh $silentconnect root@$vm1:$pathvm1/*) <(ssh $silentconnect root@$vm2:$pathvm2/*)

getpatch $vm1 $pathvm1 & getpatch $vm2 $pathvm2
echo
diff -urq $vm1/ $vm2/ > $diffile
echo
echo "*******"
echo "* Only in $vm1:"
cat $diffile | grep Only | grep $vm1
echo
echo "*******"
echo "* Only in $vm2:"
cat $diffile | grep Only | grep $vm2
echo
echo "*******"
echo "* On both environments, differences:"
cat $diffile | grep differ | while read -r line;do
  f1=`echo $line | sed 's/Files \(.*\) and .*/\1/g'`
  f2=`echo $line | sed 's/.* and \(.*\) differ/\1/g'`
  echo "$(head -n1 $f1) in $vm1"
  echo "$(head -n1 $f2) in $vm2"
  echo "---"
done

rm -rf $comparefolder
