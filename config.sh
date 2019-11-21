########################
#                      #
#     VARIABLES        #
#                      #
########################

STATIC_IP="10.13.254.77/30"
GATEWAY="$(echo $STATIC_IP | cut -f1,2,3 -d'.').254"
sed -i "s#dhcp#static#g" /etc/network/interfaces
	echo address $STATIC_IP >> /etc/network/interfaces
	echo gateway $GATEWAY   >> /etc/network/interfaces
/etc/init.d/networking restart
