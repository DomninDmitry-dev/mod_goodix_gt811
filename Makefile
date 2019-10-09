DEV_KERNEL_DIR = 4.19.59-sunxi
HOST_KERNEL_DIR = orange-pi-4.19.59
PROJ_NAME = driver-gt811
DEV_ROOT_IP = root@192.168.0.120
MOD_DIR = input/touchscreen/
MOD_NAME = goodix_gt811
DTB_NAME = sun8i-h3-orangepi-one
#PROG_NAME = test
USER_DIR=dmitry

ifeq ($(shell uname -m), x86_64)
	KDIR = $(HOME)/Kernels/$(HOST_KERNEL_DIR)
else
	KDIR = /lib/modules/$(shell uname -r)/build
endif

ARCH = arm
CCFLAGS = -C
REMFLAGS = -g -O0
COMPILER_PROG = arm-unknown-linux-gnueabihf-
COMPILER = arm-linux-gnueabihf-
PWD = $(shell pwd)

# Опция -g - помещает в объектный или исполняемый файл информацию необходимую для
# работы отладчика gdb. При сборке какого-либо проекта с целью последующей отладки,
# опцию -g необходимо включать как на этапе компиляции так и на этапе компоновки.

# Опция -O0 - отменяет какую-либо оптимизацию кода. Опция необходима на этапе
# отладки приложения. Как было показано выше, оптимизация может привести к
# изменению структуры программы до неузнаваемости, связь между исполняемым и
# исходным кодом не будет явной, соответственно, пошаговая отладка программы
# будет не возможна. При включении опции -g, рекомендуется включать и -O0.

obj-m   := $(MOD_NAME).o
CFLAGS_$(MOD_NAME).o := -DDEBUG

all:
ifeq ($(shell uname -m), x86_64)
	$(MAKE) $(CCFLAGS) $(KDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(COMPILER) modules
else
	$(MAKE) $(CCFLAGS) $(KDIR) M=$(PWD) modules
endif

#test: $(PROG_NAME).cpp
#ifeq ($(shell uname -m), x86_64)
#	$(COMPILER_PROG)g++ $(PROG_NAME).cpp -o $(PROG_NAME) $(REMFLAGS)
#else
#	g++ $(PROG_NAME).cpp -o $(PROG_NAME) $(REMFLAGS)
#endif
	
copy_dtbo:
	echo "Copy $(MOD_NAME).dtbo"
	scp ~/eclipse-workspace-drivers-OPI/$(PROJ_NAME)/DTS/$(MOD_NAME).dtbo $(DEV_ROOT_IP):/boot/overlay-user
copy_dtb:
	echo "Copy $(DTB_NAME).dtb"
	scp ~/Kernels/$(HOST_KERNEL_DIR)/arch/arm/boot/dts/$(DTB_NAME).dtb $(DEV_ROOT_IP):/boot/dtb
del_mod:
	echo "Delete $(MOD_NAME).ko from board"
	ssh $(DEV_ROOT_IP) 'rm /lib/modules/$(DEV_KERNEL_DIR)/kernel/drivers/$(MOD_DIR)/$(MOD_NAME).ko'
copy_mod:
	echo "Copy $(MOD_NAME).ko to board"
	scp ~/eclipse-workspace-drivers-OPI/$(PROJ_NAME)/$(MOD_NAME).ko $(DEV_ROOT_IP):/lib/modules/$(DEV_KERNEL_DIR)/kernel/drivers/$(MOD_DIR)
compile_dts:
	echo "Copy dts from my project to kernel host"
	cp ~/eclipse-workspace-drivers-OPI/$(PROJ_NAME)/DTS/$(DTB_NAME).dts ~/Kernels/$(HOST_KERNEL_DIR)/arch/arm/boot/dts
	echo "Compiling dts"
	cd ~/Kernels/$(HOST_KERNEL_DIR) && $(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(COMPILER) $(DTB_NAME).dtb
	echo "Copy dtb from kernel host to my project"
	cp ~/Kernels/$(HOST_KERNEL_DIR)/arch/arm/boot/dts/$(DTB_NAME).dtb ~/eclipse-workspace-drivers-OPI/$(PROJ_NAME)/DTS
	
compile_dtsi:
	~/Kernels/$(HOST_KERNEL_DIR)/scripts/dtc/dtc -I dts -O dtb -o \
											~/eclipse-workspace-drivers-OPI/$(PROJ_NAME)/DTS/$(MOD_NAME).dtbo \
														~/eclipse-workspace-drivers-OPI/$(PROJ_NAME)/DTS/$(MOD_NAME).dtsi
reboot_dev:
	echo "Reboot"
	ssh $(DEV_ROOT_IP) 'reboot'

#copy_prog:
	#echo "Copy prog"
	#scp ~/eclipse-workspace-drivers-OPI/$(PROJ_NAME)/test $(DEV_ROOT_IP):/home/$(USER_DIR)

clean:
	@rm -f *.o .*.cmd .*.flags *.mod.c *.order *.dwo *.mod.dwo .*.dwo
	@rm -f .*.*.cmd *~ *.*~ TODO.*
	@rm -fR .tmp*
	@rm -rf .tmp_versions
	@rm -f *.ko *.symvers
