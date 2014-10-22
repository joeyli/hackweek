# Lee, Chun-Yi, for HMAC testing 

TARGET = hmactest

ifneq ($(KERNELRELEASE),)
	obj-m	:= $(TARGET).o
else
	KDIR	:= /lib/modules/$(shell uname -r)/build
	PWD	:= $(shell pwd)
default:
	$(MAKE) -C $(KDIR) M=$(PWD)
endif

clean:
	rm -rf *.ko *.o .hmactest.* hmactest.mod.* Module.symvers .tmp_versions
