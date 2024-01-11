# Requirements  
  
# Level 1  
The general goal of Level 1 is to start  
introducing our File Share service to our customers.  

## Level 1 Overview Diagram  
Business requirements for Level 1  
  
Customers should be able to send a POST HTTP-request  
to a function in the environment function app which  
creates a file share in the environment storage account  
The customer HTTP-request order should only be accepted  
if it contains at least the following values:  
filesharename - This should be the name  
of the file share that gets created.  
firstname - First name of the person who created the order.  
lastname - Last name of the person who created the order.  
The details for the order should be populated  
into a storage account table called FileshareOrders.  
If everything succeeded, the results should be  
returned as a HTTP-response containing StatusCode - 200 OK  
and the Share URL of the created file share.  
As well as any other details that might  
be good to return in the response.  
  
In order to protect our customers data in the file shares,  
it is expected that each existent file share  
has a daily backup to a Recovery Services Vault.  
It is expected that the full setup of resources  
and configurations for the Level 1 business requirements  
is done using IaC and Azure Pipelines.  
  
# Level 2
The general goal of Level 2 is to  
start introducing our SFTP service to our customers.  
  
## Level 2 Overview Diagram  
Business requirements for Level 2  
  
Customers should be able to send a POST HTTP-request  
to a function in the environment function app which  
creates an SFTP user, and a container that will  
be the SFTP user's home-directory for the SFTP service  
The customer HTTP-request order should only  
be accepted if it contains at least the following values  
containername - Name of the storage account blob container  
that will get created, and should be  
the home-directory for the SFTP user.  
username - Name of the SFTP user that will be created.  
firstname - First name of the person who created the order.  
lastname - Last name of the person who created the order.  
company - Name of the company of the client who created the order.  
The details for the order should be populated  
into a storage account table called SFTPOrders.  
If everything succeeded, the results should be  
returned as a HTTP-response containing StatusCode - 200 OK.  
The HTTP response should also contain the following values:  
  
username - Name of the SFTP user that were created.  
  
sshpassword - SSH password that the customer  
will use to connect to the SFTP service.  
  
connection-string - Connection string  
for the user for when using the SFTP service.  
The SFTP user should have full permissions from the home-directory  
  
It is important that our customers has their own dedicated  
encryption scopes so for each company that has ordered  
from our SFTP service, there should be a dedicated encryption scope  
for their blob containers.  
In order to gain better insights in the daily operations  
of our resources, it is expected that we start  
collecting diagnostic logs for all our resources in the environment.  
The logs should be collected into a Log Analytics Workspace,  
and archived into a Storage Account with lifecycle management policies.  
These resources should be placed into it's own resource-group  
so that it can easily be used by multiple environments.  
We will call the environment that contains shared resources for core.  
The resources in core should have it's own dedicated Azure Pipeline.  
It is expected that the full setup of resources and configurations  
for the Level 2 business requirements is done using IaC and Azure Pipelines.  
  
# Level 3  
The general goal of Level 3 is securing our resources  
by introducing internal networks, private endpoints  
and privatelinks as well as a dedicated management VM.  
  
## Level 3 Overview Diagram  
Business requirements for Level 3  
  
Secure Azure resources from unnecessary exposure to the internet  
This requires us to set up internal networking using VNet's,  
Private Endpoints and Privatelinks  
We also need to ensure we are creating the expected privatelink  
private DNS zones for the different resource-types  
The connectivity between the different VNet's should be done  
possible using VNet peerings  
Ensure all management can be done from a dedicated management VM  
Ensure we have default network ACLs in place (NSGs)  
and traffic only allowed for expected ports  
It is expected that NSG's are attached to all subnets in each VNet  
These resources should be placed into it's own resource-group  
so that it can easily be towards multiple environments.  
We will call the environment that contains shared resources for core.  
The resources in core should have it's own dedicated Azure Pipeline.  
It is expected that the full setup of resources and  
configurations for the Level 3 business requirements  
is done using IaC and Azure Pipelines.  


# Introduction 
TODO: Give a short introduction of your project. Let this section explain the objectives or the motivation behind this project. 

# Getting Started
TODO: Guide users through getting your code up and running on their own system. In this section you can talk about:
1.	Installation process
2.	Software dependencies
3.	Latest releases
4.	API references

# Build and Test
TODO: Describe and show how to build your code and run the tests. 

# Contribute
TODO: Explain how other users and developers can contribute to make your code better. 