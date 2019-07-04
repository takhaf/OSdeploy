pass=$1
IP=$2
type=$3
if ["type" -eq "controller" ]
	then source controller_actions.sh
elif ["type" -eq "compute" ]
	then source compute_actions.sh

else echo "Unknown node type"
fi

