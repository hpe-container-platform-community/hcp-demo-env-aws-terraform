#!/bin/bash
source "./scripts/variables.sh"
source "./scripts/functions.sh"

if [[ "$AD_SERVER_ENABLED" != "True" ]]; then
   echo "Aborting. AD Server has not been enabled"
fi

show_help() {
   print_term_width '='
   echo Usage: $0 -q query
   echo
   echo Example query strings
   echo ---------------------
   echo "# Retrieve the ad_admin1 record"
   echo "$0 -q 'CN=ad_admin1'"   
   echo
   echo "# Retrieve all 'user' records in group DemoTenantUsers"
   echo "$0 -q '(&(memberOf=CN=DemoTenantUsers,CN=Users,DC=samdom,DC=example,DC=com)(objectClass=user))'"
   print_term_width '='
}

OPTIND=1 # Reset in case getopts has been used previously in the shell.

query=""

while getopts "q:" opt; do
    case "$opt" in
    q)  query=$OPTARG
        ;;
    esac
done

if [[ OPTIND == 1 || -z $query ]]
then
    show_help
    exit 1
fi

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

ldapsearch -o ldif-wrap=no \
   -x \
   -H ldap://$AD_PUB_IP:389 \
   -D 'cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com' \
   -w '5ambaPwd@' \
   -b 'CN=Users,DC=samdom,DC=example,DC=com' \
   $query

# To connect over TLS
# LDAPTLS_REQCERT=never ldapsearch -o ldif-wrap=no -x -H ldaps://localhost:636 -D 'cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com' -w '5ambaPwd@' -b 'DC=samdom,DC=example,DC=com'