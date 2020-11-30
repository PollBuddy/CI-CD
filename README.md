# CI-CD
Scripts to handle automated creation of test instances and the production environment


## Setup: 

### Periodic Shutdown of Instances

Configure CRON with the following line (or similar)

```
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
0 0 * * * /bin/bash /home/pollbuddy/CI-CD/periodicShutdown.sh >> /var/log/cron/pollbuddy-periodicShutdown.log 2>&1
```

Path is just what I had. It can likely be much more limited. You may want to use the output of the `echo $PATH` command so that it's specific to your system.

You can do this with `crontab -e`

This will run the script `every day` at `midnight` and log output to `/var/log/cron/pollbuddy-periodicShutdown.log`.

## Notes:

If you are running this yourself, add this line to your docker.service file to ensure there is enough Docker Network space for all the instances: 
`--default-address-pool base=10.127.0.0/16,size=28`

Alternatively, configure it in `/etc/docker/daemon.js`: (`...` indicates possible existing values. Do not include these `...`'s)

```
{
    ...
    "default-address-pools":
        [
            {
                "base": "10.127.0.0/16",
                "size": 28
            }
        ]
    ...
}
```