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

sed -e "s#<INTERFACE>#$INTERFACE#g" ./templates/interfaces.TEMP > ./REPLACEMENTS/interfaces
sed -i "s#<STATIC_IP>#$STATIC_IP#g" ./REPLACEMENTS/interfaces
sed -i "s#<GATEWAY>#$GATEWAY#g" ./REPLACEMENTS/interfaces
mv /etc/network/interfaces /etc/network/interfaces.old
cp ./REPLACEMENTS/interfaces /etc/network/interfaces
sudo ifdown $INTERFACE && sudo ifup $INTERFACE
