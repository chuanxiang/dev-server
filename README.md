# Development Server on AWS

This is project to create your own server for deveopment purpose.

In some scenario, we are not allowed to use our own pc/laptop, or we have to use Pad for code development, then this development server will help.

After using the terraform to create this server, we can start/stop it anytime to save money. As long as you have the internet, everything can be done here.

Also, we use the another EBS disk as home, so our data will not deleted if the server is terminated.

Check features list for more information about this server.


## Feature
1. Customize your EC2 in different Region and AZ
2. Use Ubuntu 22.0.4
3. Use your own EBS as home
4. Create a 2G swap for system
5. Use Duck DDNS for your server
6. Use telegram bot to inform the server is live
7. Use Google Chrome Remote Desktop to connect


## How to setup
1. Install terraform and setup AWS key if it is not done yet
2. Create a EBS volume in your AZ, launch an instace to use this EBS and label it by e2label
3. Clone this code
4. Change values in terrafrom.tfvars, and vars in setup_ubuntu.sh
5. Execute terraform init, plan, apply