########################
#                      #
#     VARIABLES        #
#                      #
########################

STATIC_IP="10.13.254.77/30"
GATEWAY="$(echo $STATIC_IP | cut -f1,2,3 -d'.').254"
INTERFACE=$(ip addr show | awk '/inet.*brd/{print $NF; exit}')

rm -rf REPLACEMENTS
mkdir -p REPLACEMENTS

#######################
#    STATIC IP        #
#######################

sed -e "s#<INTERFACE>#$INTERFACE#g" ./templates/interface.TEMP > ./REPLACEMENTS/interface
sed -i "s#<STATIC_IP>#$STATIC_IP#g" ./REPLACEMENTS/interface
sed -i "s#<GATEWAY>#$GATEWAY#g" ./REPLACEMENTS/interface
mv /etc/network/interface /etc/network/interface.old
cp ./REPLACEMENTS/interface /etc/network/interface
/etc/init.d/networking restart
