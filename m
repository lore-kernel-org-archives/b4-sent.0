From: Dinesh kumar v <dinesh.v@adlinktech.com>
Date: Mon, 28 Sep 2026 13:09:00 +0530
Subject: [PATCH 4/4] doc: board: Add ADLINK LEC-iMX95 documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-lec-imx95-v1-v1-4-9e0c9b94ccbe@adlinktech.com>
References: <20260928-lec-imx95-v1-v1-0-9e0c9b94ccbe@adlinktech.com>
In-Reply-To: <20260928-lec-imx95-v1-v1-0-9e0c9b94ccbe@adlinktech.com>
To: "NXP i.MX U-Boot Team" <uboot-imx@nxp.com>, 
 Tanmay Kathpalia <tanmay.kathpalia@altera.com>, 
 u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Stefano Babic <sbabic@nabladev.com>, Fabio Estevam <festevam@gmail.com>, 
 Peng Fan <peng.fan@nxp.com>, Jaehoon Chung <jh80.chung@samsung.com>, 
 Alice Guo <alice.guo@nxp.com>, Primoz Fiser <primoz.fiser@norik.com>, 
 Johan Jonker <jbx6244@gmail.com>, Simona Toaca <simona.toaca@nxp.com>, 
 Francesco Dolcini <francesco.dolcini@toradex.com>, 
 Dinesh kumar v <dinesh.v@adlinktech.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790581138; l=6098;
 i=dinesh.v@adlinktech.com; s=20260928; h=from:subject:message-id;
 bh=D+6NvNmIm0LJXudZ7/tH+ziEcMPon/ZUEWt4pu5Yg7M=;
 b=IKKZbcSIOnoOALbxS+UI6z8J8HHpbw1EMqCal1vexaLheZtPdt1lAgHfBJW9nLfx0Bo4blCCE
 +aDpIgqS45UAgb9hF8gJJf7aOxbXfZ8fQ+CpYkUFIj+GZQ4hcYolAno
X-Developer-Key: i=dinesh.v@adlinktech.com; a=ed25519;
 pk=2+xm2aDQjQT68aPFzfLMgdZrQGpCMUU3Qp1CwWoRlus=
X-Endpoint-Received: by B4 Relay for dinesh.v@adlinktech.com/20260928 with auth_id=1074
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document how to build and boot U-Boot on the ADLINK
LEC-iMX95 SMARC module.

Signed-off-by: Dinesh kumar v <dinesh.v@adlinktech.com>
---
 doc/board/adlink/lec-imx95.rst | 183 +++++++++++++++++++++++++++++++++++++++++
 1 file changed, 183 insertions(+)

diff --git a/doc/board/adlink/lec-imx95.rst b/doc/board/adlink/lec-imx95.rst
new file mode 100644
index 00000000000..eab759d04df
--- /dev/null
+++ b/doc/board/adlink/lec-imx95.rst
@@ -0,0 +1,183 @@
+.. SPDX-License-Identifier: GPL-2.0-or-later
+
+Adlink SMARC iMX95 Module
+==========================
+
+ SoM: https://www.adlinktech.com/products/Computer_on_Modules/SMARC/LEC-IMX95
+ Carrier: https://www.adlinktech.com/products/computer_on_modules/SMARCStarterKits/I-Pi_SMARC_IMX95
+
+Quick Start
+-----------
+
+- Setup environment
+- Get ahab-container.img
+- Get DDR PHY Firmware Images
+- Get and Build OEI Images
+- Get and Build System Manager Image
+- Get and Build the ARM Trusted Firmware
+- Build the Bootloader Image
+- Boot
+
+Setup environment
+-----------------
+
+Suggested current toolchains are ARM 15.2 (https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads):
+
+- https://gitlab.arm.com/api/v4/projects/tooling%2Fgnu-toolchains-for-arm/packages/generic/gnu-toolchain/15.2.rel1/arm-gnu-toolchain-15.2.rel1-x86_64-arm-none-eabi.tar.xz
+
+.. code-block:: console
+
+    $ export TOOLS=<path/to/directory/with/toolchains>
+
+    # Update your package list
+	$ sudo apt update
+
+	# Install the aarch64 cross-compiler toolchain
+	$ sudo apt install gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
+
+Get ahab-container.img
+----------------------
+
+Note: `$srctree` is the U-Boot source directory
+
+.. code-block:: console
+
+    $ wget https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/firmware-ele-imx-2.0.2-89161a8.bin
+    $ sh firmware-ele-imx-2.0.2-89161a8.bin --auto-accept
+    $ cp firmware-ele-imx-2.0.2-89161a8/mx95b0-ahab-container.img $(srctree)
+
+Get DDR PHY Firmware Images
+---------------------------
+
+Note: `$srctree` is the U-Boot source directory
+
+.. code-block:: console
+
+    $ wget https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/firmware-imx-8.28-994fa14.bin
+    $ sh firmware-imx-8.28-994fa14.bin --auto-accept
+    $ cp firmware-imx-8.28-994fa14/firmware/ddr/synopsys/lpddr5*v202409.bin $(srctree)
+
+Get and Build OEI Images
+------------------------
+
+Note: `$srctree` is the U-Boot source directory
+Get OEI from: https://github.com/ADLINK/imx-oei.git
+branch: main
+
+.. code-block:: console
+
+    $ git clone -b main https://github.com/ADLINK/imx-oei.git
+    $ cd imx-oei
+
+    $ make board=mx95lp5 oei=ddr DEBUG=1 r=B0 all
+    $ cp build/mx95lp5/ddr/oei-m33-ddr.bin $(srctree)
+
+    $ make board=mx95lp5 oei=tcm DEBUG=1 r=B0 all
+    $ cp build/mx95lp5/tcm/oei-m33-tcm.bin $(srctree)
+
+    $ make board=mx95lp5 oei=dat DEBUG=1 r=B0 all
+    $ cp build/mx95lp5/dat/oei-m33-dat.bin $(srctree)
+
+
+Get and Build the System Manager Image
+--------------------------------------
+
+Note: `$srctree` is the U-Boot source directory
+Get System Manager from: https://github.com/ADLINK/imx-sm.git
+branch: main
+
+.. code-block:: console
+
+    $ git clone -b main https://github.com/ADLINK/imx-sm.git
+    $ cd imx-sm
+    $ make config=mx95lec all
+    $ cp build/mx95lec/m33_image.bin $(srctree)
+
+Get and Build the ARM Trusted Firmware
+--------------------------------------
+
+Note: `$srctree` is the U-Boot source directory
+Get ATF from: https://github.com/nxp-imx/imx-atf/
+branch: lf_v2.14
+
+.. code-block:: console
+
+    $ export CROSS_COMPILE=aarch64-linux-gnu-
+    $ unset LDFLAGS
+    $ unset AS
+    $ git clone -b lf_v2.14 https://github.com/nxp-imx/imx-atf.git
+    $ cd imx-atf
+    $ make PLAT=imx95 bl31
+    $ cp build/imx95/release/bl31.bin $(srctree)
+
+Build the Bootloader Image
+--------------------------
+
+.. code-block:: console
+
+    $ export CROSS_COMPILE=aarch64-linux-gnu-
+    $ make lec-imx95_defconfig
+    $ make
+
+Flash to SD card
+-------------
+
+.. code-block:: console
+
+	$ sudo dd if=flash.bin of=/dev/sd[x] bs=1k seek=32 conv=fsync
+
+
+Boot
+----
+
+Boot sequence is:
+
+* SPL ---> ATF (TF-A) ---> U-Boot proper
+
+Output:
+
+.. code-block:: console
+        U-Boot SPL 2026.10-rc5-00542-g2b8902913c19-dirty (Sep 28 2026 - 10:58:03 +0530)
+        SYS Boot reason: por
+        Normal Boot
+        Trying to boot from MMC2
+        Parse v2x container failed -14
+        Load image from MMC/SD 0x136c00
+        NOTICE:  BL31: v2.14.1(release):lf-6.18.20-2.0.0
+        NOTICE:  BL31: Built : 17:41:10, Sep  2 2026
+
+
+        U-Boot 2026.10-rc5-00542-g2b8902913c19-dirty (Sep 28 2026 - 10:58:03 +0530)
+
+        CPU:   NXP i.MX9596 Rev2.0 A55 at 1800 MHz
+        CPU:   Extended Industrial temperature grade (-40C to 125C)
+        Model: Adlink LEC iMX95 on I-Pi SMARC Development Board
+        DRAM:  3.8 GiB
+        Core:  270 devices, 23 uclasses, devicetree: separate
+        MMC:   FSL_SDHC: 0, FSL_SDHC: 1
+        Reading from MMC(1)... *** Warning - bad CRC, using default environment
+
+        In:    serial@44380000
+        Out:   serial@44380000
+        Err:   serial@44380000
+
+        BuildInfo:
+        - ELE firmware not included
+
+        switch to partitions #0, OK
+        mmc1 is current device
+        Net:   WARNING: no MAC address assigned for MAC0
+        imx_get_mac_from_fuse: fuse read err: 0
+
+        Warning: enetc-0 (eth0) using random MAC address - 1e:2c:49:99:cc:07
+        eth0: enetc-0 [PRIME]WARNING: no MAC address assigned for MAC1
+        imx_get_mac_from_fuse: fuse read err: 0
+
+        Warning: enetc-1 (eth1) using random MAC address - 86:60:fa:e7:ef:59
+        , eth1: enetc-1
+        Hit any key to stop autoboot: 0
+        u-boot=> net list
+        eth0 : enetc-0 1e:2c:49:99:cc:07 active
+        eth1 : enetc-1 86:60:fa:e7:ef:59
+        u-boot=>
+```

-- 
2.25.1

