source ~/Github/cloud-cli-helpers/user_variables.private

### droplet (Digital Ocean)
alias drop-list="doctl compute -t $droptoken  droplet list --format ID,Name,PublicIPv4 | grep \$dropshortnames"
drop-create()
{
  doctl compute -t $droptoken droplet create $1 --image $dropimage --size $dropsize --region $dropregion --ssh-keys $dropssh > /dev/null
  sleep 2
  drop-list
}
alias drop-delete="doctl compute -t $droptoken droplet delete -f "
drop-list-full()
{
    doctl compute -t $droptoken droplet list  --format ID,Name | grep $dropshortnames
}
drop-remove-all()
{
  cd ~/
  drop-list-full > ~/.droplist
  while read line
  do
    export id=$(echo "$line"  | cut -c1-9)
    echo "$id"
    doctl compute droplet -t $droptoken delete $id -f
  done < "${1:-.droplist}"
}


### Linode
alias linode-create='linode-cli linodes create --type $linodetype --region us-west --image $linodeimage --root_pass $linoderootpswd --authorized_keys "$linodessh" --label $1'
alias linode-list="linode-cli linodes list"
alias linode-delete="linode-cli linodes delete "
linode-remove-all()
{
  cd ~/
  linode-list > ~/.linodelist
  while read line
  do
    export id=$(echo "$line"  | cut -c3-10)

    if [[ $id =~ ^[0-9] ]] echo "$id" && linode-cli linodes delete $id
  done < "${1:-.linodelist}"
}


### AWS Instances
export region=$(aws configure get region)
alias aws_region="echo $region"

export aws_query="Reservations[*].Instances[*].[PublicIpAddress, PrivateIpAddress, Tags[?Key=='Name'].Value|[0], InstanceId, SubnetId, Placement.AvailabilityZone]"
export aws_query_id="Reservations[*].Instances[*].InstanceId"
export aws_query_name="Reservations[*].Instances[*].Tags[?Key=='Name'].Value|[0]"

export aws_filter_owner="Name=tag:Owner,Values=$aws_name"
export aws_filter_cicd="Name=tag:CICD,Values=$aws_initials*"
export aws_filter_initials="Name=tag:Name,Values=*$aws_initials*"
export aws_filter_instances="Name=instance-state-name,Values=running"

aws-list()
{
  echo ${1:=$region}
  echo -e "$(aws ec2 describe-instances --region ${1:=$region} --filters "$aws_filter_owner" "$aws_filter_instances" --query "$aws_query" --output table)" & echo -e "$(aws ec2 describe-instances --region ${1:=$region} --filters  "$aws_filter_instances" "$aws_filter_initials"  --query "$aws_query" --output table)"
}
aws-generic-list()
{
  echo -e "$(aws ec2 describe-instances --region ${1:=$region} --filters "${2:=$aws_filter_initials}" "$aws_filter_instances" --query "${3:=$aws_query}" --output text)"
}
aws-list-ids-by-initials()
{
  aws-generic-list ${1:=$region} ${2:=$aws_filter_initials} ${3:=$aws_query_id}
}
aws-list-ids-by-owner()
{
  aws-generic-list ${1:=$region} ${2:=$aws_filter_owner} ${3:=$aws_query_id}
}
aws-list-ids-by-cicd()
{
  aws-generic-list ${1:=$region} ${2:=$aws_filter_cicd} ${3:=$aws_query_id}
}
aws-list-names-by-initials()
{
  aws-generic-list ${1:=$region} ${2:=$aws_filter_initials} ${3:=$aws_query_name}
}
aws-list-names-by-owner()
{
  aws-generic-list ${1:=$region} ${2:=$aws_filter_owner} ${3:=$aws_query_name}
}

aws-list-all()
{
  echo "listing each US region's instances..."
  # explicitly listing regions in US that we commonly use, as this takes N time to display where N is length(list of regions)
  for regions in us-west-1 us-west-2 us-east-1 us-east-2
  do
       echo $regions
       echo -e "$(aws ec2 describe-instances --region $regions --filters "$aws_filter_owner" "$aws_filter_cicd" "$aws_filter_instances" --query "$aws_query" --output table)" & echo -e "$(aws ec2 describe-instances --region $regions --filters  "$aws_filter_instances" "$aws_filter_initials"  --query "$aws_query" --output table)"
  done
}
aws-list-everyone()
{
  echo "listing all instances in each US region..."
  # explicitly listing regions in US that we commonly use, as this takes N time to display where N is length(list of regions)
  # this function lists every instance in the region, similar to what you would see in aws ec2 UI
  for us_region in us-west-1 us-west-2 us-east-1 us-east-2
  do
       echo $us_region
       echo -e "$(aws ec2 describe-instances --region $us_region --filters "$aws_filter_instances" --query "$aws_query" --output table)"
  done
}


aws-create()
{
  echo "creating in region: " ${2:=$region}
  if [ ${2:=$region} = 'us-west-1' ]
  then
    aws ec2 --region us-west-1 run-instances --image-id ${aws_us_west_1[1]} --count 1 --instance-type $aws_instance_type --key-name $aws_ssh_key --security-group-ids ${aws_us_west_1[2]} --subnet-id ${aws_us_west_1[3]} --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$1},{Key=Owner,Value=$aws_name},{Key=DoNotDelete,Value=True}]" > /dev/null
    echo "waiting for instance to appear in backend . . ."
    sleep 5
    aws-list $region
  elif [ ${2:=$region} = 'us-east-2' ]
  then
    aws ec2 --region us-east-2 run-instances --image-id ${aws_us_east_2[1]} --count 1 --instance-type $aws_instance_type --key-name $aws_ssh_key --security-group-ids ${aws_us_east_2[2]} --subnet-id ${aws_us_east_2[3]} --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$1},{Key=Owner,Value=$aws_name},{Key=DoNotDelete,Value=True}]" > /dev/null
    echo "waiting for instance to appear in backend . . ."
    sleep 5
    aws-list us-east-2
  else
    echo "no default values for" $2 "please add a new region to this function"
  fi
}

aws-create-ubuntu()
{
  echo "creating in region: " ${2:=$region}
  if [ ${2:=$region} = 'us-west-1' ]
  then
    aws ec2 --region us-west-1 run-instances --image-id ${aws_us_west_1_ubuntu[1]} --count 1 --instance-type $aws_instance_type --key-name $aws_ssh_key --security-group-ids ${aws_us_west_1_ubuntu[2]} --subnet-id ${aws_us_west_1_ubuntu[3]} --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$1},{Key=Owner,Value=$aws_name},{Key=DoNotDelete,Value=True}]" > /dev/null
    echo "waiting for instance to appear in backend . . ."
    sleep 5
    aws-list $region
  elif [ ${2:=$region} = 'us-east-2' ]
  then
    aws ec2 --region us-east-2 run-instances --image-id ${aws_us_east_2_ubuntu[1]} --count 1 --instance-type $aws_instance_type --key-name $aws_ssh_key --security-group-ids ${aws_us_east_2_ubuntu[2]} --subnet-id ${aws_us_east_2_ubuntu[3]} --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$1},{Key=Owner,Value=$aws_name},{Key=DoNotDelete,Value=True}]" > /dev/null
    echo "waiting for instance to appear in backend . . ."
    sleep 5
    aws-list
  else
    echo "no default values for" $2 "please add a new region to this function"
  fi
}

# output id from name of 1 instance
aws-id()
{
  aws ec2 --region ${2:=$region} describe-instances --filters "Name=tag:Name,Values=$1" --query "Reservations[*].Instances[*].InstanceId" --output text
}
aws-delete()
{
  aws ec2 --region ${2:=$region} terminate-instances --instance-ids $(aws-id $1 ${2:=$region}) >> /dev/null
}
aws-remove-all()
{
  echo "about to remove all instances listed below"
  export aws_ids=$(aws-list-ids-by-owner ${1:=$region})
  echo $aws_ids
  if [[ $aws_ids ]]
  then
    sleep 2
    aws ec2 terminate-instances --region ${1:=$region} --instance-ids $(aws-list-ids-by-owner ${1:=$region}) > /dev/null
  else
    echo "no instances to remove"
  fi
  echo "also removing the following unowned instances"
  export aws_ids=$(aws-list-names-by-initials ${1:=$region})
  echo $aws_ids
  if [[ $aws_ids ]]
  then
    sleep 2
    aws ec2 terminate-instances --region ${1:=$region} --instance-ids $(aws-list-ids-by-initials ${1:=$region}) > /dev/null
  else
    echo "no more instances to remove"
  fi
  echo "about to remove all CICD instances listed below"
  export aws_ids=$(aws-list-ids-by-cicd ${1:=$region})
  echo $aws_ids
  if [[ $aws_ids ]]
  then
    sleep 2
    aws ec2 terminate-instances --region ${1:=$region} --instance-ids $(aws-list-ids-by-cicd ${1:=$region}) > /dev/null
  else
    echo "no instances to remove"
  fi
  echo "all instances in ${1:=$region} region are removed"

}

### AWS nlb
aws-list-nlbs()
{
  aws elbv2 describe-load-balancers --region ${1:=$region} --output table --query "LoadBalancers[*].LoadBalancerName" | grep $aws_initials | tr -d '|'
}
aws-list-everyone-nlbs()
{
  aws elbv2 describe-load-balancers --region ${1:=$region} --output table --query "LoadBalancers[*].LoadBalancerName"
}
aws-list-arns()
{
  aws elbv2 describe-load-balancers --region ${1:=$region} --output table --query "LoadBalancers[*].LoadBalancerArn" | grep $aws_initials | tr -d '|'
}
aws-create-nlb()
{
  echo "creating in region: " ${2:=$region}
  if [ ${2:=$region} = 'us-west-1' ]
  then
    aws elbv2 create-load-balancer --region us-west-1 --name $1 --type network --subnets ${aws_us_west_1[3]} > dev/null
  elif [ ${2:=$region} = 'us-east-2' ]
  then
    aws elbv2 create-load-balancer --region us-east-2 --name $1 --type network --subnets ${aws_us_east_2[3]} > dev/null
  else
    echo "no default values for" $2 "please add a new region to this function"
  fi
  aws-list-nlbs ${2:=$region}
}
aws-delete-arn()
{
  aws elbv2 delete-load-balancer --region ${2:=$region} --load-balancer-arn $1 > /dev/null
}
aws-remove-all-nlb()
{
  echo "warning! About to remove all NLBs in" ${1:=$region}
  aws-list-nlbs ${1:=$region}
  sleep 2
  for arn in $(aws-list-arns ${1:=$region})
  do
    aws-delete-arn $arn ${1:=$region}
    echo "removed" $arn
  done
}

cleanup-all-providers()
{
  echo "warning! this will remove anything with your initials..." $aws_initials "be sure this is what you want!"
  sleep 5

  for regions in us-west-1 us-west-2 us-east-1 us-east-2
  do
    echo "\nwarning! About to remove everything in" $regions
    aws-remove-all $regions
    aws-remove-all-nlb $regions
  done
  ### No longer have access to DO on QA team
  # echo "done with AWS, starting on Digital Ocean \n"
  # drop-remove-all
  echo "done with Digital Ocean, starting on Linode \n"
  linode-remove-all
}
