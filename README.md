# CI-CD
Scripts to handle automated creation of test instances and the production environment


## Notes:

If you are running this yourself, add this line to your docker.service file to ensure there is enough Docker Network space for all the instances: 
`--default-address-pool base=10.127.0.0/16,size=28`