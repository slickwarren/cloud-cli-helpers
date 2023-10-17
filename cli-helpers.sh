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
  linode-list > .linodelist
  while read line;
  do
    export id=$(echo "$line"  | cut -c5-12);

    if [[ $id =~ ^[0-9] ]]; then
      echo $(($id)) && linode-cli linodes delete $(($id));
    fi
  done < ".linodelist";
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
  if [[ $1 ]]; then
    test_region=$1
  else
    test_region=$region
  fi
  echo $test_region
  echo -e "$(aws ec2 describe-instances --region $test_region --filters "$aws_filter_owner" "$aws_filter_instances" --query "$aws_query" --output table)" 
  echo -e "$(aws ec2 describe-instances --region $test_region --filters  "$aws_filter_instances" "$aws_filter_initials"  --query "$aws_query" --output table)"
}
aws-generic-list()
{
  if [[ $1 ]]; then
    test_region=$1
  else
    test_region=$region
  fi
  if [[ $2 ]]; then
    test_owner=$2
  else
    test_filter=$aws_filter_initials
  fi

  if [[ $3 ]]; then
    test_query=$3
  else
    test_query=$aws_query
  fi
  echo -e "$(aws ec2 describe-instances --region $test_region --filters "$test_filter" "$aws_filter_instances" --query "$test_query" --output text)"
}
aws-list-ids-by-initials()
{
  if [[ $1 ]]; then
    test_region=$1
  else
    test_region=$region
  fi

  if [[ $2 ]]; then
    test_owner=$2
  else
    test_filter=$aws_filter_initials
  fi

  if [[ $3 ]]; then
    test_query=$3
  else
    test_query=$aws_query_id
  fi
  aws-generic-list $test_region $test_filter $test_query
}
aws-list-ids-by-owner()
{
  if [[ $1 ]]; then
    test_region=$1
  else
    test_region=$region
  fi

  if [[ $2 ]]; then
    test_owner=$2
  else
    test_filter=$aws_filter_owner
  fi

  if [[ $3 ]]; then
    test_query=$3
  else
    test_query=$aws_query_id
  fi
  aws-generic-list $test_region $test_filter $test_query
}
aws-list-ids-by-cicd()
{
  if [[ $1 ]]; then
    test_region=$1
  else
    test_region=$region
  fi

  if [[ $2 ]]; then
    test_owner=$2
  else
    test_filter=$aws_filter_cicd
  fi

  if [[ $3 ]]; then
    test_query=$3
  else
    test_query=$aws_query_id
  fi
  aws-generic-list $test_region $test_filter $test_query
}
aws-list-names-by-initials()
{
  if [[ $1 ]]; then
    test_region=$1
  else
    test_region=$region
  fi

  if [[ $2 ]]; then
    test_owner=$2
  else
    test_filter=$aws_filter_initials
  fi

  if [[ $3 ]]; then
    test_query=$3
  else
    test_query=$aws_query_name
  fi
  aws-generic-list $test_region $test_filter $test_query
}
aws-list-names-by-owner()
{
  if [[ $1 ]]; then
    test_region=$1
  else
    test_region=$region
  fi

  if [[ $2 ]]; then
    test_owner=$2
  else
    test_filter=$aws_filter_owner
  fi

  if [[ $3 ]]; then
    test_query=$3
  else
    test_query=$aws_query_name
  fi
  aws-generic-list $test_region $test_filter $test_query
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
  if [[ $2 ]]; then
    test_region=$2
  else
    test_region=$region
  fi
  echo $test_region
  echo "creating in region: " $test_region
  if [ $test_region = 'us-west-1' ]
  then
    aws ec2 --region us-west-1 run-instances --image-id ${aws_us_west_1[0]} --count 1 --instance-type $aws_instance_type --key-name $aws_ssh_key --security-group-ids ${aws_us_west_1[1]} --subnet-id ${aws_us_west_1[2]} --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$1},{Key=Owner,Value=$aws_name},{Key=DoNotDelete,Value=True}]" > /dev/null
    echo "waiting for instance to appear in backend . . ."
    sleep 5
    aws-list $region
  elif [ $test_region = 'us-east-2' ]
  then
    aws ec2 --region us-east-2 run-instances --image-id ${aws_us_east_2[0]} --count 1 --instance-type $aws_instance_type --key-name $aws_ssh_key --security-group-ids ${aws_us_east_2[1]} --subnet-id ${aws_us_east_2[2]} --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$1},{Key=Owner,Value=$aws_name},{Key=DoNotDelete,Value=True}]" > /dev/null
    echo "waiting for instance to appear in backend . . ."
    sleep 5
    aws-list us-east-2
  else
    echo "no default values for" $2 "please add a new region to this function"
  fi
}

aws-create-ubuntu()
{
  if [[ $2 ]]; then
    test_region=$2
  else
    test_region=$region
  fi
  echo $test_region
  echo "creating in region: " $test_region
  if [ $test_region = 'us-west-1' ]
  then
    aws ec2 --region us-west-1 run-instances --image-id ${aws_us_west_1_ubuntu[0]} --count 1 --instance-type $aws_instance_type --key-name $aws_ssh_key --security-group-ids ${aws_us_west_1_ubuntu[1]} --subnet-id ${aws_us_west_1_ubuntu[2]} --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$1},{Key=Owner,Value=$aws_name},{Key=DoNotDelete,Value=True}]" > /dev/null
    echo "waiting for instance to appear in backend . . ."
    sleep 5
    aws-list $region
  elif [ $test_region = 'us-east-2' ]
  then
    aws ec2 --region us-east-2 run-instances --image-id ${aws_us_east_2_ubuntu[0]} --count 1 --instance-type $aws_instance_type --key-name $aws_ssh_key --security-group-ids ${aws_us_east_2_ubuntu[1]} --subnet-id ${aws_us_east_2_ubuntu[2]} --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$1},{Key=Owner,Value=$aws_name},{Key=DoNotDelete,Value=True}]" > /dev/null
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
  if [[ $2 ]]; then
    test_region=$2
  else
    test_region=$region
  fi
  echo $test_region
  aws ec2 --region $test_region describe-instances --filters "Name=tag:Name,Values=$1" --query "Reservations[*].Instances[*].InstanceId" --output text
}
aws-delete()
{
  if [[ $2 ]]; then
    test_region=$2
  else
    test_region=$region
  fi
  echo $test_region
  aws ec2 --region $test_region terminate-instances --instance-ids $(aws-id $1 $test_region) >> /dev/null
}
aws-remove-all()
{
  if [[ $2 ]]; then
    test_region=$2
  else
    test_region=$region
  fi
  echo "about to remove all instances listed below"
  export aws_ids=$(aws-list-ids-by-owner $test_region)
  echo $aws_ids
  if [[ ${#aws_ids} -gt 4 ]]
  then
    sleep 2
    aws ec2 terminate-instances --region $test_region --instance-ids $(aws-list-ids-by-owner $test_region) > /dev/null
  else
    echo "no instances to remove"
  fi
  echo "also removing the following unowned instances"
  export aws_ids=$(aws-list-names-by-initials $test_region)
  echo $aws_ids
  if [[ ${#aws_ids} -gt 4 ]]
  then
    sleep 2
    aws ec2 terminate-instances --region $test_region --instance-ids $(aws-list-ids-by-initials $test_region) > /dev/null
  else
    echo "no more instances to remove"
  fi
  echo "about to remove all CICD instances listed below"
  export aws_ids=$(aws-list-ids-by-cicd $test_region)
  echo $aws_ids
  if [[ ${#aws_ids} -gt 4 ]]
  then
    sleep 2
    aws ec2 terminate-instances --region $test_region --instance-ids $(aws-list-ids-by-cicd $test_region) > /dev/null
  else
    echo "no instances to remove"
  fi
  echo "all instances in $test_region region are removed"

}

### AWS nlb
aws-list-nlbs()
{
  if [[ $1 ]]; then
    test_region=$1
  else
    test_region=$region
  fi
  aws elbv2 describe-load-balancers --region $test_region --output table --query "LoadBalancers[*].LoadBalancerName" | grep $aws_initials | tr -d '|'
}
aws-list-everyone-nlbs()
{
  if [[ $1 ]]; then
    test_region=$1
  else
    test_region=$region
  fi
  aws elbv2 describe-load-balancers --region $test_region --output table --query "LoadBalancers[*].LoadBalancerName"
}
aws-list-arns()
{
  if [[ $1 ]]; then
    test_region=$1
  else
    test_region=$region
  fi
  aws elbv2 describe-load-balancers --region $test_region --output table --query "LoadBalancers[*].LoadBalancerArn" | grep $aws_initials | tr -d '|'
}
aws-create-nlb()
{
  if [[ $2 ]]; then
    test_region=$2
  else
    test_region=$region
  fi
  echo $test_region
  echo "creating in region: " $test_region
  if [ $test_region = 'us-west-1' ]
  then
    aws elbv2 create-load-balancer --region us-west-1 --name $1 --type network --subnets ${aws_us_west_1[3]} > dev/null
  elif [ $test_region = 'us-east-2' ]
  then
    aws elbv2 create-load-balancer --region us-east-2 --name $1 --type network --subnets ${aws_us_east_2[3]} > dev/null
  else
    echo "no default values for" $2 "please add a new region to this function"
  fi
  aws-list-nlbs $test_region
}
aws-delete-arn()
{
  if [[ $2 ]]; then
    test_region=$2
  else
    test_region=$region
  fi
  aws elbv2 delete-load-balancer --region $test_region --load-balancer-arn $1 > /dev/null
}
aws-remove-all-nlb()
{
  if [[ $1 ]]; then
    test_region=$1
  else
    test_region=$region
  fi
  echo $test_region
  echo "warning! About to remove all NLBs in" $test_region
  aws-list-nlbs $test_region
  sleep 2
  for arn in $(aws-list-arns $test_region)
  do
    aws-delete-arn $arn $test_region
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
