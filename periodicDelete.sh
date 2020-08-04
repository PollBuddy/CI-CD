#!/bin/bash

########################################################################################
# This script is designed to be called with no arguments as a periodic cron job. It    #
# will check for instances that have been spun down, and delete them after a set time  #
# period elapses. They would have to be manually recreated to be spun up again.        #
########################################################################################
