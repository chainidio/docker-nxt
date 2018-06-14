#!/bin/sh

if [ ! -f "/nxt/.init" ]; then 
	echo -e " init-nxt.sh: Performing init..."

	# If there is no .init, this can be a new install
	# or an upgrade... in the second case, we want to do some cleanup to ensure
	# that the upgrade will go smooth
	
	rm -Rf /nxt/lib && \
	mkdir /cid/conf
	
	# if a script was provided, we download it locally
	# then we run it before anything else starts
	if [ -n "${SCRIPT-}" ]; then
		filename=$(basename "$SCRIPT")
		wget "$SCRIPT" -O "/nxt-boot/scripts/$filename"
		chmod u+x "/nxt-boot/scripts/$filename"
		/nxt-boot/scripts/$filename
	fi  

	cd /
	
	# Now time to get the NRS client
	wget --no-check-certificate https://chainid.io/ChainPlatform.zip && \
	unzip -o ChainPlatform.zip && \
	rm *.zip && \
	cd /ChainPlatform && \
	rm -Rf *.exe src changelogs
	

	if [ -n "${PLUGINS-}" ]; then
		/nxt-boot/scripts/install-plugins.sh "$PLUGINS"
	else
		echo " PLUGINS not provided"
	fi  

	# We figure out what is the current db folder
	if [ "$NXTNET" = "main" ]; then
		DB="cid_db"
	else
		DB="cid_test_db"
	fi  

	# just to be sure :)
	echo " Database is $DB"

	# if we need to bootstrap, we do that first.
	# Warning, bootstrapping will delete the current blockchain.
	# $BLOCKCHAINDL must point to a zip that contains the nxt_db folder itself.
	if [ -n "${BLOCKCHAINDL-}" ] && [ ! -d "$DB" ]; then
		echo " init-nxt.sh: $DB not found, downloading blockchain from $BLOCKCHAINDL";
		wget "$BLOCKCHAINDL" && unzip *.zip && rm *.zip
		echo " init-nxt.sh: Blockchain download complete"
	else
		echo " BLOCKCHAINDL not provided"
	fi

	# linking of the config
	if [ "$NXTNET" = "main" ]; then
		echo " init-nxt.sh: Linking config to mainnet"
		cp /nxt-boot/conf/nxt-main.properties /cid/conf/cid.properties
	else
		echo " init-nxt.sh: Linking config to testnet"
		cp /nxt-boot/conf/nxt-test.properties /cid/conf/cid.properties
	fi  

	# if the admin password is defined in the ENV variable, we append to the config
	if [ -n "${ADMINPASSWD-}" ]; then
		echo -e "\nxt.adminPassword=${ADMINPASSWD-}" >> /cid/conf/cid.properties
	else
		echo " ADMINPASSWD not provided"
	fi

	# If we did all of that, we dump a file that will signal next time that we
	# should not run the init-script again
	touch /cid/.init
else
	echo -e " init-nxt.sh: Init already done, skipping init."
fi

cd /ChainPlatform
./run.sh
