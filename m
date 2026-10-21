From: Cunhao Lu <1579567540@qq.com>
Subject: [PATCH 00/27] rockchip: Add RK3572 and Forlinx OK3572-C support
Date: Thu, 22 Oct 2026 00:10:57 +0800
Message-Id: <20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABHk2GoC/yXMQQqDMBBA0avIrB1IUrTaq0gXSWaso2BKYosg3
 t2oy7f4f4PEUTjBq9gg8l+ShDlDlwX4wc4fRqFsMMrUWhmNlghdsJEwTI/qadBjw6Qb16q6Igs
 5/EbuZb2m3ft2+rmR/XKeYN8Pd33xTnYAAAA=
X-Change-ID: 20261021-add-board-ok3572-c-8ed18b9065da
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Elaine Zhang <zhangqing@rock-chips.com>, Lee Jones <lee@kernel.org>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Richard Cochran <richardcochran@gmail.com>, Ulf Hansson <ulfh@kernel.org>, 
 Andi Shyti <andi.shyti@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Jisheng Zhang <jszhang@kernel.org>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 David Wu <david.wu@rock-chips.com>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>, 
 Shawn Lin <shawn.lin@rock-chips.com>
Cc: Cunhao Lu <1579567540@qq.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 mfd@lists.linux.dev, linux-gpio@vger.kernel.org, netdev@vger.kernel.org, 
 linux-pm@vger.kernel.org, linux-i2c@vger.kernel.org, 
 linux-serial@vger.kernel.org, linux-mmc@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, linux-phy@lists.infradead.org, 
 linux-usb@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792599138; l=44832;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=5XJDeNaqAi+MHoGKgNAKBGcpsbtPWBGnjaMS9hjBkN4=;
 b=rbqE7b3pL+GA5+bBsH8TGOOjGEymtfE4BHTvBSwzGbHXe73t1l3faz4oFNDyOKTsnAcgTuIC+
 dTDALCwhtHvBttR2rluzGWkhwlnlgCREDeWx2nvbBvEqtrvVOasmtS3
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds initial support for the RK3572 SoC and the Forlinx
OK3572-C board. It includes the bindings, drivers, and device trees
needed to bring up a minimal system.

The RK3572 SoC has eight CPU cores: two Cortex-A73 cores and six
Cortex-A53 cores. It also integrates an Arm Mali-G310V2 MC1 GPU.
The OK3572-C board provides two Gigabit Ethernet ports, three USB3 Type-A
ports, a Type-C dual-role port, eMMC, microSD, and UART.

Testing was performed with Debian 13 minimal and Linux 7.3 on the
OK3572-C with the FET3572-C module. Shared peripheral tests were run with
the system booted from SD, while eMMC validation covered the complete
boot chain.

Passed functionality:

- SD and eMMC complete the firmware, kernel, and root filesystem
  boot chain.
- UART console works at 1500000 baud.
- SD read/write and data persistence checks pass.
- All eight CPUs start; CPU frequency scaling and hotplug checks pass.
- Both Ethernet ports obtain IPv4 addresses and pass bidirectional file
  transfers.
- All three Type-A ports pass USB2 and USB3 enumeration, data transfers,
  and reconnect persistence checks.
- Type-C host and device modes pass in both plug orientations. Physical
  reconnects correctly select the expected device, host, and device roles
  in sequence.

Stability:

- Repeated cold and software reboots complete on SD and eMMC without data
  integrity failures.
- A combined CPU, memory, network, SD, and USB3 stress test completes
  without a crash, lockup, CPU offline event, or thermal shutdown.
- Ethernet error and drop counters do not increase during bidirectional
  network tests.

Build and checks:

- The kernel, modules, and board DTB build successfully.
- The series passes checkpatch with --strict; only generic reminders about
  new MAINTAINERS entries remain.

Untested hardware and paths:

- NPU
- PCIe
- GPU, video output, and audio
- CPU rates above 1.2 GHz and voltage scaling
- Other low-speed external interfaces

Some files in this series are derived from the Forlinx OK3572-C BSP
Alpha1. Thanks to Forlinx for their support.

AI assistance:

- Codex / DeepSeek V4.1 Flash were used for:
  - Collecting data
  - Automating tests
  - Reviewing and adjusting code to follow community conventions

Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
Raw dmesg from the OK3572-C boot:

[    0.000000] Booting Linux on physical CPU 0x0000000000 [0x410fd034]
[    0.000000] Linux version 7.3.0-bleedingedge-rk3572 (build@armbian) (aarch64-linux-gnu-gcc (Ubuntu 11.4.0-1ubuntu1~22.04.3) 11.4.0, GNU ld (GNU Binutils for Ubuntu) 2.38) #1 SMP PREEMPT Wed Oct 21 14:04:07 CST 2026
[    0.000000] Machine model: Forlinx OK3572-C
[    0.000000] efi: UEFI not found.
[    0.000000] OF: reserved mem: Reserved memory: No reserved-memory node in the DT
[    0.000000] psci: probing for conduit method from DT.
[    0.000000] psci: PSCIv1.1 detected in firmware.
[    0.000000] psci: Using standard PSCI v0.2 function IDs
[    0.000000] psci: MIGRATE_INFO_TYPE not supported.
[    0.000000] psci: SMC Calling Convention v1.5
[    0.000000] Zone ranges:
[    0.000000]   DMA      [mem 0x0000000040200000-0x00000000ffffffff]
[    0.000000]   DMA32    empty
[    0.000000]   Normal   [mem 0x0000000100000000-0x000000013fffffff]
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000040200000-0x000000013fffffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000040200000-0x000000013fffffff]
[    0.000000] On node 0, zone DMA: 512 pages in unavailable ranges
[    0.000000] percpu: Embedded 30 pages/cpu s82136 r8192 d32552 u122880
[    0.000000] pcpu-alloc: s82136 r8192 d32552 u122880 alloc=30*4096
[    0.000000] pcpu-alloc: [0] 0 [0] 1 [0] 2 [0] 3 [0] 4 [0] 5 [0] 6 [0] 7 
[    0.000000] CPU features: detected: ARM erratum 845719
[    0.000000] alternatives: applying boot alternatives
[    0.000000] Kernel command line: root=UUID=2520cc50-b3ea-430f-ba9b-552afa4b6f82 rootwait rootfstype=ext4 splash=verbose console=ttyS0,1500000 console=tty1 consoleblank=0 loglevel=1 ubootpart=48cd0da4-4dfb-4b7c-b03f-e4a0c57ddacd usb-storage.quirks=0x2537:0x1066:u,0x2537:0x1068:u   cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory
[    0.000000] Unknown kernel command line parameters "splash=verbose ubootpart=48cd0da4-4dfb-4b7c-b03f-e4a0c57ddacd cgroup_enable=memory cgroup_memory=1", will be passed to user space.
[    0.000000] printk: log buffer data + meta data: 131072 + 458752 = 589824 bytes
[    0.000000] Dentry cache hash table entries: 524288 (order: 10, 4194304 bytes, linear)
[    0.000000] Inode-cache hash table entries: 262144 (order: 9, 2097152 bytes, linear)
[    0.000000] software IO TLB: area num 8.
[    0.000000] software IO TLB: mapped [mem 0x00000000f7f47000-0x00000000fbf47000] (64MB)
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 1048064
[    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=8, Nodes=1
[    0.000000] ftrace: allocating 40216 entries in 158 pages
[    0.000000] ftrace: allocated 158 pages with 5 groups
[    0.000000] rcu: Hierarchical RCU implementation.
[    0.000000] rcu: 	RCU event tracing is enabled.
[    0.000000] 	Trampoline variant of Tasks RCU enabled.
[    0.000000] 	Rude variant of Tasks RCU enabled.
[    0.000000] 	Tracing variant of Tasks RCU enabled.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 25 jiffies.
[    0.000000] RCU Tasks: Setting shift to 3 and lim to 1 rcu_task_cb_adjust=1 rcu_task_cpu_ids=8.
[    0.000000] RCU Tasks Rude: Setting shift to 3 and lim to 1 rcu_task_cb_adjust=1 rcu_task_cpu_ids=8.
[    0.000000] NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
[    0.000000] Root IRQ handler: gic_handle_irq
[    0.000000] GIC: Using split EOI/Deactivate mode
[    0.000000] rcu: srcu_init: Setting srcu_struct sizes based on contention.
[    0.000000] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 7645041785100000 ns
[    0.000000] arch_timer: cp15 timer running at 24.00MHz (phys).
[    0.000000] clocksource: arch_sys_counter: mask: 0xffffffffffffff max_cycles: 0x588fe9dc0, max_idle_ns: 440795202592 ns
[    0.000000] sched_clock: 56 bits at 24MHz, resolution 41ns, wraps every 4398046511097ns
[    0.000502] Console: colour dummy device 80x25
[    0.000516] printk: legacy console [tty1] enabled
[    0.000637] Calibrating delay loop (skipped), value calculated using timer frequency.. 48.00 BogoMIPS (lpj=96000)
[    0.000652] pid_max: default: 32768 minimum: 301
[    0.000874] Yama: becoming mindful.
[    0.001075] Mount-cache hash table entries: 8192 (order: 4, 65536 bytes, linear)
[    0.001097] Mountpoint-cache hash table entries: 8192 (order: 4, 65536 bytes, linear)
[    0.001450] VFS: Finished mounting rootfs on nullfs
[    0.004025] rcu: Hierarchical SRCU implementation.
[    0.004042] rcu: 	Max phase no-delay instances is 1000.
[    0.004294] Timer migration: 1 hierarchy levels; 8 children per group; 1 crossnode level
[    0.004820] EFI services will not be available.
[    0.005261] smp: Bringing up secondary CPUs ...
[    0.006096] CPU1: Booted secondary processor 0x0000000001 [0x410fd034]
[    0.006991] CPU2: Booted secondary processor 0x0000000002 [0x410fd034]
[    0.007847] CPU3: Booted secondary processor 0x0000000003 [0x410fd034]
[    0.008787] CPU4: Booted secondary processor 0x0000000100 [0x410fd034]
[    0.009715] CPU5: Booted secondary processor 0x0000000101 [0x410fd034]
[    0.010446] CPU features: detected: Spectre-BHB
[    0.010459] CPU features: detected: ARM erratum 858921
[    0.010576] arch_timer: Enabling local workaround for ARM erratum 858921
[    0.010590] arch_timer: CPU6: Trapping CNTVCT access
[    0.010600] CPU6: Booted secondary processor 0x0000000200 [0x411fd090]
[    0.011335] arch_timer: Enabling local workaround for ARM erratum 858921
[    0.011346] arch_timer: CPU7: Trapping CNTVCT access
[    0.011354] CPU7: Booted secondary processor 0x0000000201 [0x411fd090]
[    0.011443] smp: Brought up 1 node, 8 CPUs
[    0.011468] SMP: Total of 8 processors activated.
[    0.011473] CPU: All CPU(s) started at EL2
[    0.011480] CPU features: detected: 32-bit EL0 Support
[    0.011487] CPU features: detected: CRC32 instructions
[    0.011563] alternatives: applying system-wide alternatives
[    0.013503] Memory: 3994400K/4192256K available (12800K kernel code, 1804K rwdata, 8020K rodata, 4800K init, 367K bss, 188600K reserved, 0K cma-reserved)
[    0.014586] devtmpfs: initialized
[    0.023256] posixtimers hash table entries: 4096 (order: 4, 65536 bytes, linear)
[    0.023390] futex hash table entries: 2048 (131072 bytes on 1 NUMA nodes, total 128 KiB, linear).
[    0.023497] 25760 pages in range for non-PLT usage
[    0.023504] 517280 pages in range for PLT usage
[    0.024485] DMI: not present or invalid.
[    0.027105] NET: Registered PF_NETLINK/PF_ROUTE protocol family
[    0.027775] DMA: preallocated 512 KiB GFP_KERNEL pool for atomic allocations
[    0.027873] DMA: preallocated 512 KiB GFP_KERNEL|GFP_DMA pool for atomic allocations
[    0.027917] audit: initializing netlink subsys (disabled)
[    0.028106] audit: type=2000 audit(0.024:1): state=initialized audit_enabled=0 res=1
[    0.063844] thermal_sys: Registered thermal governor 'step_wise'
[    0.063969] ASID allocator initialised with 65536 entries
[    0.066221] /soc/i2c@2c040000/usb-typec@22/connector: Fixed dependency cycle(s) with /soc/usb@24000000
[    0.066238] /soc/usb@24000000: Fixed dependency cycle(s) with /soc/i2c@2c040000/usb-typec@22/connector
[    0.066401] /soc/interrupt-controller@2a601000: Fixed dependency cycle(s) with /soc/interrupt-controller@2a601000
[    0.074302] rockchip-gpio 26300000.gpio: probed /pinctrl/gpio@26300000
[    0.074859] rockchip-gpio 2b200000.gpio: probed /pinctrl/gpio@2b200000
[    0.075467] rockchip-gpio 2b300000.gpio: probed /pinctrl/gpio@2b300000
[    0.076065] rockchip-gpio 2b400000.gpio: probed /pinctrl/gpio@2b400000
[    0.076577] rockchip-gpio 2b500000.gpio: probed /pinctrl/gpio@2b500000
[    0.079569] iommu: Default domain type: Translated
[    0.079581] iommu: DMA domain TLB invalidation policy: strict mode
[    0.087665] SCSI subsystem initialized
[    0.087800] usbcore: registered new interface driver usbfs
[    0.087825] usbcore: registered new interface driver hub
[    0.087851] usbcore: registered new device driver usb
[    0.087962] pps_core: LinuxPPS API ver. 1 registered
[    0.087967] pps_core: Software ver. 5.3.6 - Copyright 2005-2007 Rodolfo Giometti <giometti@linux.it>
[    0.087977] PTP clock support registered
[    0.088046] scmi_core: SCMI protocol bus registered
[    0.088816] vgaarb: loaded
[    0.089111] clocksource: Switched to clocksource arch_sys_counter
[    0.095252] NET: Registered PF_INET protocol family
[    0.095435] IP idents hash table entries: 65536 (order: 7, 524288 bytes, linear)
[    0.098401] tcp_listen_portaddr_hash hash table entries: 2048 (order: 3, 32768 bytes, linear)
[    0.098444] Table-perturb hash table entries: 65536 (order: 6, 262144 bytes, linear)
[    0.098456] TCP established hash table entries: 32768 (order: 6, 262144 bytes, linear)
[    0.098599] TCP bind hash table entries: 32768 (order: 8, 1048576 bytes, linear)
[    0.099208] TCP: Hash tables configured (established 32768 bind 32768)
[    0.099320] UDP hash table entries: 2048 (order: 5, 131072 bytes, linear)
[    0.099566] NET: Registered PF_UNIX/PF_LOCAL protocol family
[    0.099609] PCI: CLS 0 bytes, default 64
[    0.099809] Unpacking initramfs...
[    0.113777] Initialise system trusted keyrings
[    0.114004] workingset: timestamp_bits=46 (anon: 41) max_order=20 bucket_order=0 (anon: 0)
[    0.114534] fuse: init (API version 7.46)
[    0.114817] NET: Registered PF_ALG protocol family
[    0.114828] Key type asymmetric registered
[    0.114833] Asymmetric key parser 'x509' registered
[    0.114866] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 249)
[    0.115027] io scheduler mq-deadline registered
[    0.115033] io scheduler kyber registered
[    0.115065] io scheduler bfq registered
[    0.603726] Freeing initrd memory: 13024K
[    0.641317] Serial: 8250/16550 driver, 4 ports, IRQ sharing disabled
[    0.642938] printk: console [ttyS0] disabled
[    0.643204] 2c130000.serial: ttyS0 MMIO32:0x000000002c130000 (irq = 36, base_baud = 1500000) is a 16550A
[    0.643447] printk: console [ttyS0] enabled
[    0.649403] loop: module loaded
[    0.650488] tun: Universal TUN/TAP device driver, 1.6
[    0.657994] xhci-hcd xhci-hcd.0.auto: xHCI Host Controller
[    0.658022] xhci-hcd xhci-hcd.0.auto: new USB bus registered, assigned bus number 1
[    0.658098] xhci-hcd xhci-hcd.0.auto: hcc params 0x0220fe64 hci version 0x110 quirks 0x0000808002000010
[    0.658139] xhci-hcd xhci-hcd.0.auto: irq 38, io mem 0x24400000
[    0.658251] xhci-hcd xhci-hcd.0.auto: xHCI Host Controller
[    0.658261] xhci-hcd xhci-hcd.0.auto: new USB bus registered, assigned bus number 2
[    0.658273] xhci-hcd xhci-hcd.0.auto: Host supports USB 3.0 SuperSpeed
[    0.658925] hub 1-0:1.0: USB hub found
[    0.658955] hub 1-0:1.0: 1 port detected
[    0.659569] usb usb2: We don't know the algorithms for LPM for this host, disabling LPM.
[    0.659953] hub 2-0:1.0: USB hub found
[    0.659977] hub 2-0:1.0: 1 port detected
[    0.660444] usbcore: registered new interface driver uas
[    0.660501] usbcore: registered new interface driver usb-storage
[    0.660521] usbcore: registered new device driver onboard-usb-dev
[    0.677538] vdda_hdmi_s0: Bringing 750000uV into 837500-837500uV
[    0.691929] pca953x 2-0023: using auto increment
[    0.704405] dwmmc_rockchip 2a090000.mmc: IDMAC supports 32-bit address mode.
[    0.704405] arm-scmi arm-scmi.4.auto: Using scmi_smc_transport
[    0.704420] arm-scmi arm-scmi.4.auto: SCMI max-rx-timeout: 30ms / max-msg-size: 104bytes / max-msg: 20
[    0.704437] dwmmc_rockchip 2a090000.mmc: Using internal DMA controller.
[    0.704446] dwmmc_rockchip 2a090000.mmc: Version ID is 270a
[    0.704482] dwmmc_rockchip 2a090000.mmc: DW MMC controller at irq 62,32 bit host data width,256 deep fifo
[    0.704546] scmi_protocol scmi_dev.1: Enabled polling mode TX channel - prot_id:16
[    0.704919] arm-scmi arm-scmi.4.auto: SCMI Notifications - Core Enabled.
[    0.704981] arm-scmi arm-scmi.4.auto: SCMI Protocol v2.0 'rockchip:' Firmware version 0x0
[    0.705018] arm-scmi arm-scmi.4.auto: Enabling SCMI Quirk [quirk_clock_rates_triplet_out_of_spec]
[    0.705787] mmc0: CQHCI version 5.10
[    0.708680] SMCCC: SOC_ID: ARCH_SOC_ID not implemented, skipping ....
[    0.708975] usbcore: registered new interface driver usbhid
[    0.708982] usbhid: USB HID core driver
[    0.709386] NET: Registered PF_INET6 protocol family
[    0.710254] Segment Routing with IPv6
[    0.710294] In-situ OAM (IOAM) with IPv6
[    0.710341] NET: Registered PF_PACKET protocol family
[    0.710370] bridge: filtering via arp/ip/ip6tables is no longer available by default. Update your scripts to load br_netfilter if you need this.
[    0.715466] Loading compiled-in X.509 certificates
[    0.717882] mmc_host mmc1: Bus speed = 400000Hz (req 400000Hz, actual 400000HZ div = 0)
[    0.721073] Key type encrypted registered
[    0.732592] mmc0: SDHCI controller on 2a010000.mmc [2a010000.mmc] using ADMA 64-bit
[    0.737594] dwc3-generic-plat 24400000.usb: Failed to create device link (0x180) with supplier regulator-usb-hub-1v2 for /soc/usb@24400000/hub@2
[    0.737903] rk_gmac-dwmac 29d20000.ethernet: IRQ sfty not found
[    0.738262] rk_gmac-dwmac 29d20000.ethernet: clock input or output? (output).
[    0.738271] rk_gmac-dwmac 29d20000.ethernet: TX delay(0x21).
[    0.738279] rk_gmac-dwmac 29d20000.ethernet: Can not read property: rx_delay.
[    0.738284] rk_gmac-dwmac 29d20000.ethernet: set rx_delay to 0x10
[    0.738298] rk_gmac-dwmac 29d20000.ethernet: integrated PHY? (no).
[    0.743326] rk_gmac-dwmac 29d20000.ethernet: init for RGMII_RXID
[    0.743496] rk_gmac-dwmac 29d20000.ethernet: User ID: 0x50, Synopsys ID: 0x51
[    0.743506] rk_gmac-dwmac 29d20000.ethernet: 	DWMAC4/5
[    0.743513] rk_gmac-dwmac 29d20000.ethernet: DMA HW capability register supported
[    0.743519] rk_gmac-dwmac 29d20000.ethernet: Active PHY interface: RGMII (1)
[    0.743525] rk_gmac-dwmac 29d20000.ethernet: RX Checksum Offload Engine supported
[    0.743530] rk_gmac-dwmac 29d20000.ethernet: TX Checksum insertion supported
[    0.743535] rk_gmac-dwmac 29d20000.ethernet: Wake-Up On Lan supported
[    0.743580] rk_gmac-dwmac 29d20000.ethernet: Enable RX Mitigation via HW Watchdog Timer
[    0.743587] rk_gmac-dwmac 29d20000.ethernet: Enabled L3L4 Flow TC (entries=2)
[    0.743594] rk_gmac-dwmac 29d20000.ethernet: Enabled RFS Flow TC (entries=10)
[    0.743599] rk_gmac-dwmac 29d20000.ethernet: TSO supported
[    0.743604] rk_gmac-dwmac 29d20000.ethernet: TSO feature enabled
[    0.743609] rk_gmac-dwmac 29d20000.ethernet: SPH feature enabled
[    0.743614] rk_gmac-dwmac 29d20000.ethernet: Using 40/40 bits DMA host/device width
[    0.801924] sdhci-dwcmshc 2a010000.mmc: Can't reduce the clock below 52MHz in HS200/HS400 mode
[    0.802190] mmc0: Command Queue Engine enabled
[    0.802216] mmc0: new HS400 Enhanced strobe MMC card at address 0001
[    0.802867] mmcblk0: mmc0:0001 C9A611 58.3 GiB
[    0.806837]  mmcblk0: p1
[    0.807374] mmcblk0boot0: mmc0:0001 C9A611 4.00 MiB
[    0.809014] mmcblk0boot1: mmc0:0001 C9A611 4.00 MiB
[    0.810526] mmcblk0rpmb: mmc0:0001 C9A611 16.0 MiB, chardev (248:0)
[    0.884811] rk_gmac-dwmac 2a040000.ethernet: IRQ sfty not found
[    0.885249] rk_gmac-dwmac 2a040000.ethernet: clock input or output? (output).
[    0.885262] rk_gmac-dwmac 2a040000.ethernet: TX delay(0x20).
[    0.885269] rk_gmac-dwmac 2a040000.ethernet: Can not read property: rx_delay.
[    0.885275] rk_gmac-dwmac 2a040000.ethernet: set rx_delay to 0x10
[    0.885362] rk_gmac-dwmac 2a040000.ethernet: integrated PHY? (no).
[    0.890392] rk_gmac-dwmac 2a040000.ethernet: init for RGMII_RXID
[    0.890584] rk_gmac-dwmac 2a040000.ethernet: User ID: 0x50, Synopsys ID: 0x51
[    0.890595] rk_gmac-dwmac 2a040000.ethernet: 	DWMAC4/5
[    0.890603] rk_gmac-dwmac 2a040000.ethernet: DMA HW capability register supported
[    0.890608] rk_gmac-dwmac 2a040000.ethernet: Active PHY interface: RGMII (1)
[    0.890615] rk_gmac-dwmac 2a040000.ethernet: RX Checksum Offload Engine supported
[    0.890620] rk_gmac-dwmac 2a040000.ethernet: TX Checksum insertion supported
[    0.890625] rk_gmac-dwmac 2a040000.ethernet: Wake-Up On Lan supported
[    0.890675] rk_gmac-dwmac 2a040000.ethernet: Enable RX Mitigation via HW Watchdog Timer
[    0.890682] rk_gmac-dwmac 2a040000.ethernet: Enabled L3L4 Flow TC (entries=2)
[    0.890693] rk_gmac-dwmac 2a040000.ethernet: Enabled RFS Flow TC (entries=10)
[    0.890699] rk_gmac-dwmac 2a040000.ethernet: TSO supported
[    0.890704] rk_gmac-dwmac 2a040000.ethernet: TSO feature enabled
[    0.890709] rk_gmac-dwmac 2a040000.ethernet: SPH feature enabled
[    0.890714] rk_gmac-dwmac 2a040000.ethernet: Using 40/40 bits DMA host/device width
[    0.913126] usb 1-1: new high-speed USB device number 2 using xhci-hcd
[    1.048394] clk: Disabling unused clocks
[    1.048873] PM: genpd: Disabling unused power domains
[    1.051000] Freeing unused kernel memory: 4800K
[    1.051125] Run /init as init process
[    1.051130]   with arguments:
[    1.051134]     /init
[    1.051137]   with environment:
[    1.051139]     HOME=/
[    1.051141]     TERM=linux
[    1.051144]     splash=verbose
[    1.051146]     ubootpart=48cd0da4-4dfb-4b7c-b03f-e4a0c57ddacd
[    1.051149]     cgroup_enable=memory
[    1.051151]     cgroup_memory=1
[    1.106465] hub 1-1:1.0: USB hub found
[    1.106513] hub 1-1:1.0: 4 ports detected
[    1.177969] usb 2-1: new SuperSpeed USB device number 2 using xhci-hcd
[    1.218522] hub 2-1:1.0: USB hub found
[    1.218968] hub 2-1:1.0: 4 ports detected
[    1.505447] usb 2-1.2: new SuperSpeed USB device number 3 using xhci-hcd
[    1.528547] usb-storage 2-1.2:1.0: USB Mass Storage device detected
[    1.529653] scsi host0: usb-storage 2-1.2:1.0
[    1.536346] rk_gmac-dwmac 29d20000.ethernet end0: renamed from eth0
[    1.537766] rk_gmac-dwmac 2a040000.ethernet end1: renamed from eth1
[    1.686075] raid6: using neon recovery algorithm
[    1.717069] raid6: int64x1  gen()   847 MB/s
[    1.737837] raid6: int64x2  gen()  1264 MB/s
[    1.752864] raid6: int64x4  gen()  1747 MB/s
[    1.763929] raid6: int64x8  gen()  2371 MB/s
[    1.773319] raid6: neonx1   gen()  2796 MB/s
[    1.781011] raid6: neonx2   gen()  3409 MB/s
[    1.786289] raid6: neonx4   gen()  4970 MB/s
[    1.791806] raid6: neonx8   gen()  4753 MB/s
[    1.791809] raid6: using algorithm neonx4 gen() 4970 MB/s
[    1.794906] raid6: .... xor() 4236 MB/s, rmw enabled
[    1.796085] xor: measuring software checksum speed
[    1.797076]    neon            : 13380 MB/sec
[    1.798330]    32regs          : 10491 MB/sec
[    1.799540]    8regs           : 10874 MB/sec
[    1.799542] xor: using function: neon (13380 MB/sec)
[    1.849991] Btrfs loaded, zoned=no, fsverity=no
[    1.937396] EXT4-fs (mmcblk0p1): mounted filesystem 2520cc50-b3ea-430f-ba9b-552afa4b6f82 ro with writeback data mode. Quota mode: disabled.
[    2.097144] usb 1-1.3: new high-speed USB device number 3 using xhci-hcd
[    2.124255] systemd[1]: System time advanced to timestamp on /var/lib/systemd/timesync/clock: Wed 2026-10-21 09:39:33 UTC
[    2.159722] systemd[1]: systemd 257.13-1~deb13u1 running in system mode (+PAM +AUDIT +SELINUX +APPARMOR +IMA +IPE +SMACK +SECCOMP +GCRYPT -GNUTLS +OPENSSL +ACL +BLKID +CURL +ELFUTILS +FIDO2 +IDN2 -IDN +IPTC +KMOD +LIBCRYPTSETUP +LIBCRYPTSETUP_PLUGINS +LIBFDISK +PCRE2 +PWQUALITY +P11KIT +QRENCODE +TPM2 +BZIP2 +LZ4 +XZ +ZLIB +ZSTD +BPF_FRAMEWORK +BTF -XKBCOMMON -UTMP +SYSVINIT +LIBARCHIVE)
[    2.159752] systemd[1]: Detected architecture arm64.
[    2.187497] usb-storage 1-1.3:1.0: USB Mass Storage device detected
[    2.187840] scsi host1: usb-storage 1-1.3:1.0
[    2.304474] systemd[1]: bpf-restrict-fs: BPF LSM hook not enabled in the kernel, BPF LSM not supported.
[    2.333489] dw-apb-uart 2c130000.serial: forbid DMA for kernel console
[    2.561278] scsi 0:0:0:0: Direct-Access     Generic  MassStorageClass 2962 PQ: 0 ANSI: 6
[    2.562581] sd 0:0:0:0: [sda] Media removed, stopped polling
[    2.563353] systemd[1]: Queued start job for default target graphical.target.
[    2.564595] scsi 0:0:0:1: Direct-Access     Generic  MassStorageClass 2962 PQ: 0 ANSI: 6
[    2.568510] systemd[1]: Created slice system-getty.slice - Slice /system/getty.
[    2.570149] systemd[1]: Created slice system-modprobe.slice - Slice /system/modprobe.
[    2.571561] systemd[1]: Created slice system-serial\x2dgetty.slice - Slice /system/serial-getty.
[    2.572692] systemd[1]: Created slice user.slice - User and Session Slice.
[    2.573163] systemd[1]: Started systemd-ask-password-console.path - Dispatch Password Requests to Console Directory Watch.
[    2.573510] systemd[1]: Started systemd-ask-password-wall.path - Forward Password Requests to Wall Directory Watch.
[    2.573797] systemd[1]: proc-sys-fs-binfmt_misc.automount - Arbitrary Executable File Formats File System Automount Point skipped, unmet condition check ConditionPathExists=/proc/sys/fs/binfmt_misc
[    2.573881] systemd[1]: Expecting device dev-ttyS0.device - /dev/ttyS0...
[    2.574097] systemd[1]: Reached target paths.target - Path Units.
[    2.574254] systemd[1]: Reached target remote-fs.target - Remote File Systems.
[    2.574386] systemd[1]: Reached target slices.target - Slice Units.
[    2.574522] systemd[1]: Reached target swap.target - Swaps.
[    2.575001] systemd[1]: Listening on syslog.socket - Syslog Socket.
[    2.577411] systemd[1]: Listening on systemd-creds.socket - Credential Encryption/Decryption.
[    2.577941] systemd[1]: Listening on systemd-initctl.socket - initctl Compatibility Named Pipe.
[    2.578412] systemd[1]: Listening on systemd-journald-dev-log.socket - Journal Socket (/dev/log).
[    2.578959] systemd[1]: Listening on systemd-journald.socket - Journal Sockets.
[    2.579632] systemd[1]: Listening on systemd-networkd.socket - Network Service Netlink Socket.
[    2.579893] systemd[1]: systemd-pcrextend.socket - TPM PCR Measurements skipped, unmet condition check ConditionSecurity=measured-uki
[    2.579945] systemd[1]: systemd-pcrlock.socket - Make TPM PCR Policy skipped, unmet condition check ConditionSecurity=measured-uki
[    2.580276] systemd[1]: Listening on systemd-udevd-control.socket - udev Control Socket.
[    2.580707] systemd[1]: Listening on systemd-udevd-kernel.socket - udev Kernel Socket.
[    2.581241] systemd[1]: dev-hugepages.mount - Huge Pages File System skipped, unmet condition check ConditionPathExists=/sys/kernel/mm/hugepages
[    2.584057] systemd[1]: Mounting dev-mqueue.mount - POSIX Message Queue File System...
[    2.586938] systemd[1]: Mounting run-lock.mount - Legacy Locks Directory /run/lock...
[    2.589826] systemd[1]: Mounting sys-kernel-debug.mount - Kernel Debug File System...
[    2.592783] systemd[1]: Mounting sys-kernel-tracing.mount - Kernel Trace File System...
[    2.593548] sd 0:0:0:0: [sda] Attached SCSI removable disk
[    2.596003] systemd[1]: Starting fake-hwclock-load.service - Restore the current clock...
[    2.600570] systemd[1]: Starting keyboard-setup.service - Set the console keyboard layout...
[    2.604814] systemd[1]: Starting kmod-static-nodes.service - Create List of Static Device Nodes...
[    2.613686] systemd[1]: Starting modprobe@configfs.service - Load Kernel Module configfs...
[    2.617598] systemd[1]: Starting modprobe@drm.service - Load Kernel Module drm...
[    2.626158] systemd[1]: Starting modprobe@efi_pstore.service - Load Kernel Module efi_pstore...
[    2.633752] systemd[1]: Starting modprobe@fuse.service - Load Kernel Module fuse...
[    2.634121] systemd[1]: netplan-ovs-cleanup.service - OpenVSwitch configuration for cleanup skipped, unmet condition check ConditionFileIsExecutable=/usr/bin/ovs-vsctl
[    2.634358] systemd[1]: systemd-hibernate-clear.service - Clear Stale Hibernate Storage Info skipped, unmet condition check ConditionPathExists=/sys/firmware/efi/efivars/HibernateLocation-8cf2644b-4b0b-428f-9387-6d876050dc67
[    2.639834] systemd[1]: Starting systemd-modules-load.service - Load Kernel Modules...
[    2.643700] systemd[1]: Starting systemd-network-generator.service - Generate Network Units from Kernel Command Line...
[    2.644139] systemd[1]: systemd-pcrmachine.service - TPM PCR Machine ID Measurement skipped, unmet condition check ConditionSecurity=measured-uki
[    2.644383] systemd[1]: systemd-tpm2-setup-early.service - Early TPM SRK Setup skipped, unmet condition check ConditionSecurity=measured-uki
[    2.648310] systemd[1]: Starting systemd-udev-load-credentials.service - Load udev Rules from Credentials...
[    2.652281] systemd[1]: Starting systemd-udev-trigger.service - Coldplug All udev Devices...
[    2.661621] systemd[1]: Mounted dev-mqueue.mount - POSIX Message Queue File System.
[    2.663368] systemd[1]: Mounted run-lock.mount - Legacy Locks Directory /run/lock.
[    2.664501] systemd[1]: Mounted sys-kernel-debug.mount - Kernel Debug File System.
[    2.665462] systemd[1]: Mounted sys-kernel-tracing.mount - Kernel Trace File System.
[    2.666583] systemd[1]: fake-hwclock-load.service: Deactivated successfully.
[    2.667169] systemd[1]: Finished fake-hwclock-load.service - Restore the current clock.
[    2.668734] systemd[1]: Finished kmod-static-nodes.service - Create List of Static Device Nodes.
[    2.669954] systemd[1]: modprobe@configfs.service: Deactivated successfully.
[    2.670577] systemd[1]: Finished modprobe@configfs.service - Load Kernel Module configfs.
[    2.671875] systemd[1]: modprobe@drm.service: Deactivated successfully.
[    2.672499] systemd[1]: Finished modprobe@drm.service - Load Kernel Module drm.
[    2.673859] systemd[1]: modprobe@efi_pstore.service: Deactivated successfully.
[    2.674460] systemd[1]: Finished modprobe@efi_pstore.service - Load Kernel Module efi_pstore.
[    2.675669] systemd[1]: modprobe@fuse.service: Deactivated successfully.
[    2.676291] systemd[1]: Finished modprobe@fuse.service - Load Kernel Module fuse.
[    2.683474] systemd[1]: Mounting sys-fs-fuse-connections.mount - FUSE Control File System...
[    2.686792] systemd[1]: Mounting sys-kernel-config.mount - Kernel Configuration File System...
[    2.687022] systemd[1]: systemd-fsck-root.service - File System Check on Root Device skipped, unmet condition check ConditionPathExists=!/run/initramfs/fsck-root
[    2.697694] systemd[1]: Starting systemd-remount-fs.service - Remount Root and Kernel File Systems...
[    2.705654] systemd[1]: Starting systemd-tmpfiles-setup-dev-early.service - Create Static Device Nodes in /dev gracefully...
[    2.708619] systemd[1]: Finished systemd-modules-load.service - Load Kernel Modules.
[    2.714637] systemd[1]: Finished systemd-network-generator.service - Generate Network Units from Kernel Command Line.
[    2.719008] systemd[1]: Finished systemd-udev-load-credentials.service - Load udev Rules from Credentials.
[    2.721423] systemd[1]: Mounted sys-fs-fuse-connections.mount - FUSE Control File System.
[    2.722109] systemd[1]: Reached target network-pre.target - Preparation for Network.
[    2.725804] systemd[1]: Starting systemd-sysctl.service - Apply Kernel Variables...
[    2.727801] systemd[1]: Mounted sys-kernel-config.mount - Kernel Configuration File System.
[    2.772223] systemd[1]: Finished systemd-tmpfiles-setup-dev-early.service - Create Static Device Nodes in /dev gracefully.
[    2.773872] EXT4-fs (mmcblk0p1): re-mounted 2520cc50-b3ea-430f-ba9b-552afa4b6f82 r/w.
[    2.777912] systemd[1]: Finished systemd-remount-fs.service - Remount Root and Kernel File Systems.
[    2.779673] systemd[1]: systemd-hwdb-update.service - Rebuild Hardware Database skipped, unmet condition check ConditionNeedsUpdate=/etc
[    2.779919] systemd[1]: systemd-pstore.service - Platform Persistent Storage Archival skipped, unmet condition check ConditionDirectoryNotEmpty=/sys/fs/pstore
[    2.783365] systemd[1]: Starting systemd-random-seed.service - Load/Save OS Random Seed...
[    2.783733] systemd[1]: systemd-sysusers.service - Create System Users skipped, no trigger condition checks were met.
[    2.790652] systemd[1]: Starting systemd-timesyncd.service - Network Time Synchronization...
[    2.793619] systemd[1]: Starting systemd-tmpfiles-setup-dev.service - Create Static Device Nodes in /dev...
[    2.793932] systemd[1]: systemd-tpm2-setup.service - TPM SRK Setup skipped, unmet condition check ConditionSecurity=measured-uki
[    2.795274] systemd[1]: Finished keyboard-setup.service - Set the console keyboard layout.
[    2.796841] systemd[1]: Finished systemd-sysctl.service - Apply Kernel Variables.
[    2.803118] systemd[1]: Starting systemd-resolved.service - Network Name Resolution...
[    2.852608] systemd[1]: Finished systemd-tmpfiles-setup-dev.service - Create Static Device Nodes in /dev.
[    2.853310] systemd[1]: Reached target local-fs-pre.target - Preparation for Local File Systems.
[    2.857305] systemd[1]: Starting systemd-udevd.service - Rule-based Manager for Device Events and Files...
[    2.956019] systemd[1]: Started systemd-timesyncd.service - Network Time Synchronization.
[    2.957257] systemd[1]: Reached target time-set.target - System Time Set.
[    3.028829] systemd[1]: Started systemd-udevd.service - Rule-based Manager for Device Events and Files.
[    3.037801] systemd[1]: Starting systemd-networkd.service - Network Configuration...
[    3.108456] sd 0:0:0:1: [sdb] Spinning up disk...
[    3.157455] systemd[1]: Finished systemd-udev-trigger.service - Coldplug All udev Devices.
[    3.185174] random: crng init done
[    3.193688] systemd[1]: Finished systemd-random-seed.service - Load/Save OS Random Seed.
[    3.194566] systemd[1]: first-boot-complete.target - First Boot Complete skipped, unmet condition check ConditionFirstBoot=yes
[    3.204351] scsi 1:0:0:0: Direct-Access     HIKSEMI  PSSD             0100 PQ: 0 ANSI: 6
[    3.210912] sd 1:0:0:0: [sdc] 2000409264 512-byte logical blocks: (1.02 TB/954 GiB)
[    3.212772] sd 1:0:0:0: [sdc] Write Protect is off
[    3.212811] sd 1:0:0:0: [sdc] Mode Sense: 43 00 00 00
[    3.213208] sd 1:0:0:0: [sdc] Write cache: enabled, read cache: enabled, doesn't support DPO or FUA
[    3.234251] cfg80211: Loading compiled-in X.509 certificates for regulatory database
[    3.239605] systemd[1]: Found device dev-ttyS0.device - /dev/ttyS0.
[    3.270004] Loaded X.509 cert 'sforshee: 00b28ddf47aef9cea7'
[    3.271763] Loaded X.509 cert 'wens: 61c038651aabdcf94bd0ac7ff06c7248db18c600'
[    3.277656] systemd[1]: Started systemd-resolved.service - Network Name Resolution.
[    3.288182]  sdc: sdc1 sdc2
[    3.288736] sd 1:0:0:0: [sdc] Attached SCSI disk
[    3.857154] systemd[1]: Reached target nss-lookup.target - Host and Network Name Lookups.
[    3.857424] systemd[1]: Reached target usb-gadget.target - Hardware activated USB gadget.
[    3.862630] systemd[1]: Mounting tmp.mount - /tmp...
[    3.891645] systemd[1]: Mounted tmp.mount - /tmp.
[    3.892193] systemd[1]: Reached target local-fs.target - Local File Systems.
[    3.894856] systemd[1]: Listening on systemd-sysext.socket - System Extension Image Management.
[    3.897761] systemd[1]: Starting armbian-zram-config.service - Armbian ZRAM config...
[    3.900711] systemd[1]: Starting console-setup.service - Set console font and keymap...
[    3.901703] systemd[1]: systemd-binfmt.service - Set Up Additional Binary Formats skipped, unmet condition check ConditionPathIsMountPoint=/proc/sys/fs/binfmt_misc
[    3.901895] systemd[1]: systemd-machine-id-commit.service - Save Transient machine-id to Disk skipped, unmet condition check ConditionPathIsMountPoint=/etc/machine-id
[    3.935051] systemd[1]: Finished console-setup.service - Set console font and keymap.
[    4.125129] .ready
[    4.496526] sd 0:0:0:1: [sdb] 122167296 512-byte logical blocks: (62.5 GB/58.3 GiB)
[    4.497199] sd 0:0:0:1: [sdb] Write Protect is off
[    4.497208] sd 0:0:0:1: [sdb] Mode Sense: 21 00 00 00
[    4.497863] sd 0:0:0:1: [sdb] Write cache: disabled, read cache: enabled, doesn't support DPO or FUA
[    4.526869]  sdb: sdb1
[    4.527177] sd 0:0:0:1: [sdb] Attached SCSI removable disk
[    4.536274] zram: Added device: zram0
[    4.536958] zram: Added device: zram1
[    4.537502] zram: Added device: zram2
[    4.560724] zswap: loaded using pool lzo
[    4.583622] zram0: detected capacity change from 0 to 4021480
[    4.602878] Adding 2010736k swap on /dev/zram0.  Priority:5 extents:1 across:2010736k SS
[    4.618289] systemd[1]: Started systemd-networkd.service - Network Configuration.
[    4.620664] rk_gmac-dwmac 2a040000.ethernet end1: Register MEM_TYPE_PAGE_POOL RxQ-0
[    4.623308] systemd[1]: Starting systemd-networkd-persistent-storage.service - Enable Persistent Storage in systemd-networkd...
[    4.635307] zram1: detected capacity change from 0 to 102400
[    4.649148] rk_gmac-dwmac 2a040000.ethernet end1: PHY [stmmac-1:01] driver [RTL8211F Gigabit Ethernet] (irq=POLL)
[    4.651091] dwmac4: Master AXI performs any burst length
[    4.651105] rk_gmac-dwmac 2a040000.ethernet end1: No Safety Features support found
[    4.651449] rk_gmac-dwmac 2a040000.ethernet end1: IEEE 1588-2008 Advanced Timestamp supported
[    4.651645] rk_gmac-dwmac 2a040000.ethernet end1: registered PTP clock
[    4.651652] rk_gmac-dwmac 2a040000.ethernet end1: configuring for phy/rgmii-rxid link mode
[    4.672612] systemd[1]: Finished armbian-zram-config.service - Armbian ZRAM config.
[    4.675764] systemd[1]: Starting armbian-ramlog.service - Armbian memory supported logging...
[    4.679240] rk_gmac-dwmac 29d20000.ethernet end0: Register MEM_TYPE_PAGE_POOL RxQ-0
[    4.705167] rk_gmac-dwmac 29d20000.ethernet end0: PHY [stmmac-0:02] driver [RTL8211F Gigabit Ethernet] (irq=POLL)
[    4.717129] dwmac4: Master AXI performs any burst length
[    4.717166] rk_gmac-dwmac 29d20000.ethernet end0: No Safety Features support found
[    4.717690] rk_gmac-dwmac 29d20000.ethernet end0: IEEE 1588-2008 Advanced Timestamp supported
[    4.718006] rk_gmac-dwmac 29d20000.ethernet end0: registered PTP clock
[    4.718031] rk_gmac-dwmac 29d20000.ethernet end0: configuring for phy/rgmii-rxid link mode
[    4.747457] systemd[1]: Finished systemd-networkd-persistent-storage.service - Enable Persistent Storage in systemd-networkd.
[    4.748565] EXT4-fs (zram1): mounted filesystem 839fe5ef-a8e2-4adc-b9a0-0c76a7cc60b4 r/w without journal. Quota mode: disabled.
[    5.000713] systemd[1]: Finished armbian-ramlog.service - Armbian memory supported logging.
[    5.007005] systemd[1]: Starting systemd-journald.service - Journal Service...
[    5.093778] systemd-journald[438]: Collecting audit messages is disabled.
[    5.173135] systemd[1]: Started systemd-journald.service - Journal Service.
[    5.231994] systemd-journald[438]: Received client request to flush runtime journal.
[    5.588283] systemd-journald[438]: Received client request to relinquish /var/log/journal/958cd540f0e041c6b855006cbba7667a access.
[    6.241260] NOTICE: Automounting of tracing to debugfs is deprecated and will be removed in 2030
[    7.806604] rk_gmac-dwmac 29d20000.ethernet end0: Link is Up - 1Gbps/Full - flow control rx/tx
[    8.766543] rk_gmac-dwmac 2a040000.ethernet end1: Link is Up - 1Gbps/Full - flow control rx/tx
[   31.709317] vdd_npu_s0: disabling

To: Stephen Boyd <sboyd@kernel.org>
To: Brian Masney <bmasney+clk@redhat.com>
To: Jerome Brunet <jbrunet+clk@baylibre.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Heiko Stuebner <heiko@sntech.de>
To: Philipp Zabel <p.zabel@pengutronix.de>
To: Elaine Zhang <zhangqing@rock-chips.com>
To: Lee Jones <lee@kernel.org>
To: Linus Walleij <linusw@kernel.org>
To: Bartosz Golaszewski <brgl@kernel.org>
To: Richard Cochran <richardcochran@gmail.com>
To: Ulf Hansson <ulfh@kernel.org>
To: Andi Shyti <andi.shyti@kernel.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
To: Jiri Slaby <jirislaby@kernel.org>
To: Jisheng Zhang <jszhang@kernel.org>
To: Andrew Lunn <andrew+netdev@lunn.ch>
To: "David S. Miller" <davem@davemloft.net>
To: Eric Dumazet <edumazet@kernel.org>
To: Jakub Kicinski <kuba@kernel.org>
To: Paolo Abeni <pabeni@redhat.com>
To: David Wu <david.wu@rock-chips.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>
To: Daniel Lezcano <daniel.lezcano@kernel.org>
To: Zhang Rui <rui.zhang@intel.com>
To: Lukasz Luba <lukasz.luba@arm.com>
To: Maxime Chevallier <maxime.chevallier@bootlin.com>
To: Maxime Coquelin <mcoquelin.stm32@gmail.com>
To: Alexandre Torgue <alexandre.torgue@foss.st.com>
To: Vinod Koul <vkoul@kernel.org>
To: Neil Armstrong <neil.armstrong@linaro.org>
To: Manivannan Sadhasivam <mani@kernel.org>
To: Cunhao Lu <1579567540@qq.com>
To: Thinh Nguyen <Thinh.Nguyen@synopsys.com>
To: Jaehoon Chung <jh80.chung@samsung.com>
To: Shawn Lin <shawn.lin@rock-chips.com>
Cc: linux-clk@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-rockchip@lists.infradead.org
Cc: linux-kernel@vger.kernel.org
Cc: mfd@lists.linux.dev
Cc: linux-gpio@vger.kernel.org
Cc: netdev@vger.kernel.org
Cc: linux-pm@vger.kernel.org
Cc: linux-i2c@vger.kernel.org
Cc: linux-serial@vger.kernel.org
Cc: linux-mmc@vger.kernel.org
Cc: linux-stm32@st-md-mailman.stormreply.com
Cc: linux-phy@lists.infradead.org
Cc: linux-usb@vger.kernel.org

---
Cunhao Lu (27):
      dt-bindings: clock: rockchip: Add RK3572 CRU
      dt-bindings: power: rockchip: Add RK3572 power domains
      dt-bindings: soc: rockchip: Add RK3572 PMU and GRF
      dt-bindings: mfd: syscon: Add RK3572 QoS register compatible
      dt-bindings: pinctrl: rockchip: Add RK3572
      dt-bindings: gpio: rockchip: Add RK3572 GPIO banks
      clk: rockchip: Add RK3572 clock and reset support
      pinctrl: rockchip: Add RK3572 support
      gpio: rockchip: Add RK3572 GPIO support
      pmdomain: rockchip: Add RK3572 boot peripheral domains
      dt-bindings: i2c: rk3x: Add RK3572
      dt-bindings: serial: snps-dw-apb-uart: Add RK3572
      dt-bindings: mmc: rockchip: Add RK3572 controllers
      dt-bindings: net: rockchip-dwmac: Add RK3572
      dt-bindings: thermal: rockchip: Add RK3572
      net: stmmac: dwmac-rk: Add RK3572 support
      thermal: rockchip: Add RK3572 support
      dt-bindings: phy: rockchip-inno-usb2: Add RK3572
      dt-bindings: phy: rockchip-naneng-combphy: Add RK3572
      dt-bindings: usb: rockchip: Add RK3572 DWC3 controller
      phy: rockchip-inno-usb2: Add RK3572 support
      phy: rockchip-naneng-combphy: Add RK3572 support
      usb: dwc3: Configure RK3572 PIPE port before discovery
      mmc: dw_mmc-rockchip: Keep RK3572 NVM domain powered
      dt-bindings: arm: rockchip: Add Forlinx OK3572-C
      arm64: dts: rockchip: Add RK3572 SoC
      arm64: dts: rockchip: Add initial support for Forlinx OK3572-C

 .../devicetree/bindings/arm/rockchip.yaml          |    6 +
 .../devicetree/bindings/arm/rockchip/pmu.yaml      |    2 +
 .../bindings/clock/rockchip,rk3572-cru.yaml        |   57 +
 .../bindings/gpio/rockchip,gpio-bank.yaml          |   24 +-
 .../devicetree/bindings/i2c/i2c-rk3x.yaml          |    1 +
 Documentation/devicetree/bindings/mfd/syscon.yaml  |    1 +
 .../devicetree/bindings/mmc/rockchip-dw-mshc.yaml  |    1 +
 .../bindings/mmc/snps,dwcmshc-sdhci.yaml           |    3 +
 .../devicetree/bindings/net/rockchip-dwmac.yaml    |    3 +
 .../bindings/phy/phy-rockchip-naneng-combphy.yaml  |   23 +
 .../bindings/phy/rockchip,inno-usb2phy.yaml        |   14 +
 .../bindings/pinctrl/rockchip,pinctrl.yaml         |    1 +
 .../bindings/power/rockchip,power-controller.yaml  |   17 +
 .../bindings/serial/snps-dw-apb-uart.yaml          |    1 +
 .../devicetree/bindings/soc/rockchip/grf.yaml      |   12 +
 .../bindings/thermal/rockchip-thermal.yaml         |    2 +
 .../bindings/usb/rockchip,rk3572-dwc3.yaml         |  100 +
 arch/arm64/boot/dts/rockchip/Makefile              |    1 +
 .../dts/rockchip/rk3572-forlinx-fet3572-c.dtsi     |  369 ++
 .../boot/dts/rockchip/rk3572-forlinx-ok3572-c.dts  |  286 ++
 arch/arm64/boot/dts/rockchip/rk3572-opp.dtsi       |  165 +
 arch/arm64/boot/dts/rockchip/rk3572-pinctrl.dtsi   | 3935 ++++++++++++++++++++
 arch/arm64/boot/dts/rockchip/rk3572.dtsi           | 1325 +++++++
 drivers/clk/rockchip/Kconfig                       |    7 +
 drivers/clk/rockchip/Makefile                      |    1 +
 drivers/clk/rockchip/clk-rk3572.c                  | 1972 ++++++++++
 drivers/clk/rockchip/clk.h                         |   36 +
 drivers/clk/rockchip/rst-rk3572.c                  |  739 ++++
 drivers/gpio/gpio-rockchip.c                       |   91 +-
 drivers/mmc/host/dw_mmc-rockchip.c                 |   24 +
 drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c     |   53 +
 drivers/phy/rockchip/phy-rockchip-inno-usb2.c      |  136 +
 drivers/phy/rockchip/phy-rockchip-naneng-combphy.c |  201 +
 drivers/pinctrl/pinctrl-rockchip.c                 |  230 +-
 drivers/pinctrl/pinctrl-rockchip.h                 |    9 +-
 drivers/pmdomain/rockchip/pm-domains.c             |  141 +-
 drivers/thermal/rockchip_thermal.c                 |   28 +
 drivers/usb/dwc3/dwc3-generic-plat.c               |   31 +
 include/dt-bindings/clock/rockchip,rk3572-cru.h    |  560 +++
 .../power/rockchip,rk3572-power-controller.h       |   30 +
 include/dt-bindings/reset/rockchip,rk3572-cru.h    |  713 ++++
 include/soc/rockchip/rockchip_sip.h                |    5 +
 42 files changed, 11332 insertions(+), 24 deletions(-)
---
base-commit: a804c5742bff224d4cb4d25dd383554d598be32b
change-id: 20261021-add-board-ok3572-c-8ed18b9065da

Best regards,
--  
Cunhao Lu <1579567540@qq.com>

