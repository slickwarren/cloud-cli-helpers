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
    export id=$(echo "$line"  | cut -c9-16)

    if [[ $id =~ ^[0-9] ]] echo "$id" && linode-cli linodes delete $id
  done < "${1:-.linodelist}"
}


### AWS (EC2)
export region=$(aws configure get region)
alias aws_region="echo $region"
aws-list()
{
  echo ${1:=$region}
  echo -e "$(aws ec2 describe-instances --region ${1:=$region} --filters "Name=tag:Owner,Values=$aws_name" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].[PublicIpAddress, PrivateIpAddress, Tags[?Key=='Name'].Value|[0], InstanceId]" --output table)" & echo -e "$(aws ec2 describe-instances --region ${1:=$region} --filters  "Name=instance-state-name,Values=running" "Name=tag:Name,Values=$aws_initials"  --query "Reservations[*].Instances[*].[PublicIpAddress, PrivateIpAddress, Tags[?Key=='Name'].Value|[0], InstanceId]" --output table)"
}
aws-list-ids-owner()
{
  echo -e "$(aws ec2 describe-instances --region ${1:=$region} --filters "Name=tag:Owner,Values=$aws_name" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].[InstanceId]" --output text)"
}
aws-list-ids-name()
{
  echo -e "$(aws ec2 describe-instances --region ${1:=$region} --filters "Name=tag:Name,Values=$aws_initials" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].[InstanceId]" --output text)"
}


aws-list-all()
{
  echo "listing each US region's instances..."
  # explicitly listing regions in US that we commonly use, as this takes N time to display where N is length(list of regions)
  for regions in us-west-1 us-west-2 us-east-1 us-east-2
  do
       echo $regions
       echo -e "$(aws ec2 describe-instances --region $regions --filters "Name=tag:Owner,Values=$aws_name" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].[PublicIpAddress, PrivateIpAddress, Tags[?Key=='Name'].Value|[0], InstanceId]" --output table)" & echo -e "$(aws ec2 describe-instances --region $regions --filters  "Name=instance-state-name,Values=running" "Name=tag:Name,Values=$aws_initials"  --query "Reservations[*].Instances[*].[PublicIpAddress, PrivateIpAddress, Tags[?Key=='Name'].Value|[0], InstanceId]" --output table)"
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
       echo -e "$(aws ec2 describe-instances --region $us_region --filters "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].[PublicIpAddress, PrivateIpAddress, Tags[?Key=='Name'].Value|[0], InstanceId]" --output table)"
  done
}


aws-create()
{
  echo "creating in region: " ${2:=$region}
  if [ ${2:=$region} = 'us-west-1' ]
  then
    aws ec2 --region us-west-1 run-instances --image-id ${aws_uswest1[1]} --count 1 --instance-type $aws_instance_type --key-name $aws_ssh_key --security-group-ids ${aws_uswest1[2]} --subnet-id ${aws_uswest1[3]} --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$1},{Key=Owner,Value=$aws_name},{Key=DoNotDelete,Value=True}]" > /dev/null
    echo "waiting for instance to appear in backend . . ."
    sleep 5
    aws-list $region
  elif [ ${2:=$region} = 'us-east-2' ]
  then
    aws ec2 --region us-east-2 run-instances --image-id ${aws_useast2[1]} --count 1 --instance-type $aws_instance_type --key-name $aws_ssh_key --security-group-ids ${aws_useast2[2]} --subnet-id ${aws_useast2[3]} --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$1},{Key=Owner,Value=$aws_name},{Key=DoNotDelete,Value=True}]" > /dev/null
  else
    echo "no default values for" $2 "please add a new region to this function"
  fi
  echo "waiting for instance to appear in backend . . ."
  sleep 5
  aws-list
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
  export aws_ids=$(aws-list-ids-owner ${1:=$region})
  echo $aws_ids
  if [[ $aws_ids ]]
  then
    sleep 2
    aws ec2 terminate-instances --region ${1:=$region} --instance-ids $(aws-list-ids-owner ${1:=$region}) >> /dev/null
  else
    echo "no instances to remove"
  fi
  echo "also removing the following unowned instances"
  export aws_ids=$(aws-list-ids-name ${1:=$region})
  echo $aws_ids
  if [[ $aws_ids ]]
  then
    sleep 2
    aws ec2 terminate-instances --region ${1:=$region} --instance-ids $(aws-list-ids-name ${1:=$region}) >> /dev/null
  else
    echo "no more instances to remove"
  fi
  echo "all instances in ${1:=$region} region are removed"
}
