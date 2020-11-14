# CI-CD
Scripts to handle automated creation of test instances and the production environment


## Setup: 

### Periodic Shutdown of Instances

Configure CRON with the following line (or similar)

`0 0 * * * /bin/bash /home/pollbuddy/CI-CD/periodicShutdown.sh >> /var/log/cron/pollbuddy-periodicDelete.log 2>&1`

You can do this with `crontab -e`

## Notes:

If you are running this yourself, add this line to your docker.service file to ensure there is enough Docker Network space for all the instances: 
`--default-address-pool base=10.127.0.0/16,size=28`