# Variables declared at start of 
name="sourav"
s3_bucket="upgrad-sourav"

# update ubuntu repo
apt update -y

# Check if apache2 is installed
if [[ apache2 != $(dpkg --get-selections apache2 | awk '{print $1}') ]] 
then
	# Install apache2
	apt install apache2 -y
fi

# Ensure that apache2 is running
running=$(systemctl status apache2 | grep active | awk '{print $3}' | tr -d '()')
if [[ running != ${running} ]] 
then
	# Start apache2
	systemctl start apache2
fi

# Ensure apache2 service is enabled
enabled=$(systemctl is-enabled apache2 | grep "enabled")
if [[ enabled != ${enabled} ]]
then
	# Enable apache2 service
	systemctl enable apache2
fi

# Creating file name
timestamp=$(date '+%d%m%Y-%H%M%S')


echo $timestamp

# Creating tar archive of apache2 access and error logs 
cd /var/log/apache2
tar -cf /tmp/${name}-httpd-logs-${timestamp}.tar *.log

# Copy logs to s3 bucket
if [[ -f /tmp/${name}-httpd-logs-${timestamp}.tar ]] 
then
	aws s3 cp /tmp/${name}-httpd-logs-${timestamp}.tar s3://${s3_bucket}/${name}-httpd-logs-${timestamp}.tar
fi

# git check

# Check if inventory.html exists or not
dir="/var/www/html"
if [[ ! -f ${dir}/inventory.html ]]
then
	echo -e 'Log Type\t-\tTime Created\t-\tType\t-\tSize' >> ${dir}/inventory.html
fi

# Inserting a log into the inventory.html
if [[ -f ${dir}/inventory.html ]]
then
	# echo \n
	# cat /tmp/${name}-httpd-logs-${timestamp}.tar
	# echo \n
	size=$(du -h /tmp/${name}-httpd-logs-${timestamp}.tar | awk '{print $1}')
	echo -e "httpd-logs\t-\t${timestamp}\t-\ttar\t-\t${size}" >> ${dir}/inventory.html
fi

# Create a cron job that runs for automation 
if [[ ! -f /etc/cron.d/automation ]]
then
	echo "* * * * * root /home/ubuntu/upgrad-assignment-1/automation-project/automation.sh" >> /etc/cron.d/automation
fi
