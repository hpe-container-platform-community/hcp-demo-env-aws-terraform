##########################################################################
# You MAY need to change these types if not available in your AWS region #
# You can heck at: https://aws.amazon.com/ec2/pricing/on-demand/         #
# See docs/README-TROUBLESHOOTING.MD#error-launching-source-instance.    #
##########################################################################

gtw_instance_type = "m5a.xlarge" 
ctr_instance_type = "r5a.xlarge" 
wkr_instance_type = "m5.4xlarge" # or provide wkr_instance_types = []
nfs_instance_type = "t2.small"
ad_instance_type  = "t2.small"
rdp_instance_type = "t3.large"
mapr_instance_type = "m5.4xlarge"