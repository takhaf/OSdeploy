set +x 

pass=$1
IP=$2
if [ $# -eq 3 ]
     then type=$3
else type=" "
fi 
if [ "$type" == "controller" ]
	then source controller_actions.sh $pass
elif [ "$type" == "compute" ]
	then source compute_actions.sh $pass

else echo "Unknown node type"
fi

