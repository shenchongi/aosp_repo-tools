#!/bin/bash
 
myToken="glpat-m2PKd1yH66PR_vzf5kKZ" #填入群组中的accesskey令牌
#根据名字获取groupId
function getGroupId()
{
	groupName=$1
	i=0
	rm -rf b.txt
	for ((i=1;i<=10;i++))
	do
		#echo "i为"$i
		groupsJsonTemp=$(curl -s --request GET --header "PRIVATE-TOKEN: $myToken" "http://192.168.100.222:4567/api/v4/groups?page=$i&per_page=100") #192.168.100.222:4567替换成自己的IP和端口
		if [[ $groupsJsonTemp != "[]" ]]
		then
			echo $groupsJsonTemp >> b.txt
		else
			break
		fi
	done
	
	var=$(cat b.txt | jq ".[] | select(.name == \"$groupName\").id")
	echo $var
}
 
 
 
 
function createGroup()
{
	groupName=$1
	preGroupId=$2
	
	tempVar=$(curl -s --request POST --header "PRIVATE-TOKEN: $myToken" \
     --header "Content-Type: application/json" \
     --data "{\"path\": \"$groupName\", \"name\": \"$groupName\", \"parent_id\": $preGroupId, \"visibility\":\"internal\" }" \
     "http://192.168.100.222:4567/api/v4/groups/") #192.168.100.222:4567替换成自己的IP和端口
	#echo "createGroup: "$tempVar
}
 
 
function createProject()
{
	projectName=$1
	groupId=$2
	tempVar=$(curl -s --request POST --header "PRIVATE-TOKEN: $myToken" --data "name=$projectName&namespace_id=$groupId&visibility=internal&default_branch=master&initialize_with_readme=true" http://192.168.100.222:4567/api/v4/projects) #192.168.100.222:4567  替换成自己的IP和端口
	#echo "创建项目: "$projectName
	#echo " "
}
 
#获取字符串数组长度
function getStringArrLength()
{
	line=$1
	i=0
	#数组长度
	arr=($line)
	length=${#arr[@]}
	echo $length
}
 
 
 
#从default.xml中读取所有的仓库
rm -rf repositories.txt
cat chenag-default.xml | while read line
do
 if [[ $line =~ "<project" ]]
 then
 	if [[ $line == *name=\"* ]]
 	then
    	 line=$(echo ${line#*name=\"})
    	 line=$(echo ${line%%\"*})
    	 echo $line >> repositories.txt
 	fi
 fi
done
 
#所有的/使用空格替换
rm -rf makeGroups.txt
cat repositories.txt | while read line
do
	#string=$(echo ${line%\/*})
	echo ${line//\// } >> makeGroups.txt
done
awk '!a[$0]++' makeGroups.txt > makeGroupsReduce.txt
 
 
 
 
makeGroupsReduceLength=0
makeGroupsReduceIndex=0
#创建group
while read line
do
	makeGroupsReduceLength=$((makeGroupsReduceLength+1))
done < makeGroupsReduce.txt
 
#创建group
cat makeGroupsReduce.txt | while read line
do
	((makeGroupsReduceIndex+=1))
	echo " =======================读取的文本数据："$line" ======================="
	echo "进度: "$((makeGroupsReduceIndex*100/makeGroupsReduceLength))"%"
	#数组长度
	length=$(getStringArrLength "$line")
	#项目的名称
	projectName=$(echo ${line##*\ })
	echo "数据长度:" $length " 项目名称:" $projectName
	preGroupName=""
	preGroupId=""
	index=0
	for groupName in $line
	do
	        echo "=============循环组名称 :" $groupName " 父节点组名称:"$preGroupName" =============================="
		((index+=1))
		#如果不是最后一个，则是子group
		if [[ $index -ne $length ]]
		then
			if [[ $preGroupName == "" ]]
			then
				preGroupName="new-aosp-13-r78" #aosp11_r48  替换成自己在gitlab上创建的顶层组名称，所有的组合项目都会在此组下面
				#循环获取根groupId
				while [[ $preGroupId == "" ]]
				do
					preGroupId=$(getGroupId $preGroupName)
					echo "根节点组ID:" $preGroupId
				done
			fi
			#echo "创建组开始 :"$groupName" 父组ID : "$preGroupId
			createGroup $groupName $preGroupId
			curGroupId=$(curl -s --request GET --header "PRIVATE-TOKEN: $myToken" http://192.168.100.222:4567/api/v4/groups/$preGroupId/subgroups | 				jq ".[] | select(.name == \"$groupName\").id")
			curGroupId=$(echo ${curGroupId//null/ })
			echo "创建组结束 :"$groupName" 组ID : "$curGroupId
			preGroupName=$groupName
			preGroupId=$curGroupId
		#如果是项目
		else
			#echo "创建项目开始 projectName : "$projectName " 组ID: "$preGroupId" 组名称:"$preGroupName
			createProject $projectName $preGroupId
			echo "创建项目结束 projectName : "$projectName " 组ID: "$preGroupId" 组名称:"$preGroupName
		fi
	done
	
	#echo 'preGroupId'$preGroupId
	
done
