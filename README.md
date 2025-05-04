# Platform Engineering

This is my playground for platform engineering ideas and 
tests for new services

## Virtual Network Manager and IPAM
Creating a Virtual Network Manager with IPAM pools and a new way of deploying vnets that allocate ip ranges from the pool, rather than explitly assigning a range.

After deployment you should see the allocated ip space for the root pool

![alt text](/resources/rootpool.png)

and for the child pool

![alt text](/resources/childpool.png)