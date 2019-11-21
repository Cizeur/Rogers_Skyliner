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

sed -e "s#<INTERFACE>#$INTERFACE#g" ./templates/interfacess.TEMP > ./REPLACEMENTS/interfaces
sed -i "s#<STATIC_IP>#$STATIC_IP#g" ./REPLACEMENTS/interfacess
sed -i "s#<GATEWAY>#$GATEWAY#g" ./REPLACEMENTS/interfacess
mv /etc/network/interfacess /etc/network/interfaces.old
cp ./REPLACEMENTS/interfacess /etc/network/interfaces
/etc/init.d/networking restart
