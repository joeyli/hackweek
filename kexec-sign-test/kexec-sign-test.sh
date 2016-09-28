#!/bin/bash

WORKSPACE=/root/kexec-sign/

init()
{
        if [ -z "$1" ]; then
                echo ""
                echo "kexec-sign-test.sh init kernel_source_folder"
                echo "	kernel_source_folder 	The kernel source folder(absolute path) has signing_key.pem/.x509. "
                echo ""
                echo "  e.g. kexec-sign-test.sh init /usr/src/linux-3.12.47-1"
                echo "       It will copy signing_key.* and generates certdb to /root/kexec-sign folder"
                echo ""
                exit 0
        fi

	if test -z "$(rpm -qa mozilla-nss-tools)"; then
		echo "zypper in mozilla-nss-tools"
		echo ""
		zypper in mozilla-nss-tools
	fi
	if test -z "$(rpm -qa pesign)"; then
		echo "zypper in pesign"
		echo ""
		zypper in pesign
	fi
	if test -z "$(rpm -qa openssl)"; then
		echo "zypper in openssl"
		echo ""
		zypper in openssl
	fi

	KERNEL_SOURCE=$1

	cd /root
	mkdir kexec-sign
	cd $WORKSPACE
	cp $KERNEL_SOURCE/certs/signing_key.* ./

	mkdir certdb
	certutil -d certdb/ -A -i signing_key.x509 -n cert -t CT,CT,CT

	echo " "
	ls -R $WORKSPACE
}

sign()
{
        if [ -z "$1" ]; then
                echo ""
                echo "kexec-sign-test.sh sign target_kernel"
                echo "  target_kernel 	The name of kernel in boot folder that you want to sign"
                echo ""
                echo "  e.g. kexec-sign-test.sh sign vmlinuz-3.12.47-default"
                echo "       vmlinuz-3.12.47-default.signed will generated in /root/kexec-sign-test folder"
                echo ""
                exit 0
        fi

	TARGET_KERNEL=$1

	cd $WORKSPACE
	rm ./"$TARGET_KERNEL".s*
	pesign -n certdb/ -i /boot/"$TARGET_KERNEL" -E ./"$TARGET_KERNEL".sattrs
	openssl dgst -sha256 -sign signing_key.pem ./"$TARGET_KERNEL".sattrs > ./"$TARGET_KERNEL".sattrs.sig
	pesign -n certdb/ -c cert -i /boot/"$TARGET_KERNEL" -R ./"$TARGET_KERNEL".sattrs.sig -I ./"$TARGET_KERNEL".sattrs -o ./"$TARGET_KERNEL".signed
	pesign -S -i ./"$TARGET_KERNEL".signed

	echo " "	
	ls $WORKSPACE*.signed
}

loadtest()
{
        if [ -z "$1" ]; then
                echo ""
                echo "kexec-sign-test.sh loadtest target_signed_kernel"
                echo "  target_signed_kernel 	The name of signed kernel in workspace folder for kexec loading test"
                echo ""
                echo "  e.g. kexec-sign-test.sh loadtest vmlinuz-3.12.47-default.signed"
                echo "       Script will show dmesg log"
                echo ""
                exit 0
        fi

	SIGNED_KERNEL=$1

	cd $WORKSPACE
	/sbin/kexec -s -p ./$SIGNED_KERNEL --append="ro quiet elevator=deadline sysrq=yes\
	reset_devices acpi_no_memhotplug cgroup_disable=memory irqpoll nr_cpus=1 disable_cpu_apicid=0 noefi\
	acpi_rsdp=0xdfbfe014  panic=1" 

	dmesg | grep kexec
}

clean()
{
	echo "Clean the workspace in /root/kexec-sign"
	echo ""

	rm $WORKSPACE/*.*
	rm -rf $WORKSPACE/certdb
	ls -R $WORKSPACE
	ls -R /root/kexec-sign
}

case "$1" in
        init)
            init $2
            ;;

        sign)
            sign $2
            ;;

        loadtest)
            loadtest $2
            ;;

        clean)
            clean
            ;;

        *)
            echo $"Usage: $0 {init|sign|loadtest|clean}"
            exit 1
esac
