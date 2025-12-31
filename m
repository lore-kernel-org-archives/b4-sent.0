From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Wed, 31 Dec 2025 20:45:03 +0100
Subject: [PATCH next] board: amediatech: Add X96Q support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251231-x96q-v1-1-316d703b8f03@posteo.net>
X-B4-Tracking: v=1; b=H4sIAD59VWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDI2ND3QpLs0JdS0uLZENjc7PUpKQ0JaDSgqLUtMwKsDHRSnmpFSVKsbW
 1APXQEa9cAAAA
X-Change-ID: 20251231-x96q-998c1376ebbf
To: u-boot@lists.denx.de
Cc: Tom Rini <trini@konsulko.com>, Svyatoslav Ryhel <clamor95@gmail.com>, 
 Leo Yu-Chi Liang <ycliang@andestech.com>, Peter Geis <pgwipeout@gmail.com>, 
 Lukasz Majewski <lukma@denx.de>, Junhui Liu <junhui.liu@pigmoral.tech>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767210416; l=5199;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=DW6XfQTXEVovMGUjbqnFXyz4iJ8rNX4DfzYlvi/iLRI=;
 b=mPMQT9vStbtOzmSpCjA3U3FEl2qXjcYFcRbGjb/g01Au6ZR8StSEoUIW9OYUZLvlcc7u1XIXL
 lUU0pbGFnwHBGeHG2m8Cf/eqS2I2Am+qAXcBgiYY05sTMXYWQ6ulhhd
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The X96Q is a set-top box with an H313 SoC, AXP305 PMIC, 1 or 2 GiB RAM,
8 or 16 GiB eMMC flash, 2x USB A, Micro-SD, HDMI, Ethernet, audio/video
output, and infrared input.

  https://x96mini.com/products/x96q-tv-box-android-10-set-top-box

This commit adds a defconfig and some documentation. The devicetree is
already in dts/upstream.

The CONFIG_DRAM_SUNXI_* settings are chosen such that the register
values in the DRAM PHY's MMIO space are as close as possible to those
observed when booting with the preinstalled vendor U-Boot.

---
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 configs/x96q_defconfig         | 46 ++++++++++++++++++++++++++++++++++
 doc/board/amediatech/index.rst |  9 +++++++
 doc/board/amediatech/x96q.rst  | 57 ++++++++++++++++++++++++++++++++++++++++++
 doc/board/index.rst            |  1 +
 4 files changed, 113 insertions(+)

diff --git a/configs/x96q_defconfig b/configs/x96q_defconfig
new file mode 100644
index 00000000000..650fecca624
--- /dev/null
+++ b/configs/x96q_defconfig
@@ -0,0 +1,46 @@
+CONFIG_ARM=y
+CONFIG_ARCH_SUNXI=y
+CONFIG_DEFAULT_DEVICE_TREE="allwinner/sun50i-h313-x96q"
+CONFIG_SPL=y
+
+CONFIG_DRAM_CLK=600
+CONFIG_DRAM_SUNXI_DX_ODT=0x03030303
+CONFIG_DRAM_SUNXI_DX_DRI=0x0e0e0e0e
+CONFIG_DRAM_SUNXI_CA_DRI=0x1f12
+CONFIG_DRAM_SUNXI_TPR0=0xc0001002
+CONFIG_DRAM_SUNXI_TPR2=0x00000100
+CONFIG_DRAM_SUNXI_TPR10=0x002f0107
+CONFIG_DRAM_SUNXI_TPR11=0xddddcccc
+CONFIG_DRAM_SUNXI_TPR12=0xeddc7665
+
+CONFIG_MACH_SUN50I_H616=y
+CONFIG_SUNXI_DRAM_H616_DDR3_1333=y    # DDR3 is correct, but vendor uboot mentions 600 MHz DRAM CLK
+#CONFIG_MMC_SUNXI_SLOT_EXTRA=2
+CONFIG_R_I2C_ENABLE=y
+# CONFIG_SYS_MALLOC_CLEAR_ON_INIT is not set
+CONFIG_SPL_I2C=y
+CONFIG_SPL_SYS_I2C_LEGACY=y
+CONFIG_SYS_I2C_MVTWSI=y
+CONFIG_SYS_I2C_SLAVE=0x7f
+CONFIG_SYS_I2C_SPEED=400000
+CONFIG_SUPPORT_EMMC_BOOT=y
+CONFIG_AXP305_POWER=y
+CONFIG_USB_EHCI_HCD=y
+CONFIG_USB_OHCI_HCD=y
+
+CONFIG_SPL_USE_TINY_PRINTF_POINTER_SUPPORT=y
+CONFIG_CMD_UFETCH=y
+#CONFIG_SPL_PAYLOAD="u-boot.img"
+#CONFIG_SYS_MMCSD_RAW_MODE_U_BOOT_SECTOR=0x60
+
+CONFIG_CMD_CAT=y
+
+#CONFIG_SYS_MMCSD_RAW_MODE_U_BOOT_SECTOR=60   # os = 0, uboot not detected
+#CONFIG_SYS_MMCSD_RAW_MODE_U_BOOT_SECTOR=61   # e59f002c e5810000 f57ff04f f57ff06f (4a0000cc)
+#CONFIG_SYS_MMCSD_RAW_MODE_U_BOOT_SECTOR=62   # a9431e66 a9442668 a9452e6a a946366c (4a0002cc)
+#CONFIG_SYS_MMCSD_RAW_MODE_U_BOOT_SECTOR=64   # 52800000 91008081 79400025 34000080 (4a0006cc)
+#CONFIG_SYS_MMCSD_RAW_MODE_U_BOOT_SECTOR=96   # 340007c0 f9401673 eb1302ff 54000760 (4a006acc)
+#CONFIG_SYS_MMCSD_RAW_MODE_U_BOOT_SECTOR=112  # f9003fe0 f94047e0 6b1c001f 54fffcc0 (4a0162cc)
+
+CONFIG_SUN8I_EMAC=y
+CONFIG_FIT_BEST_MATCH=y
diff --git a/doc/board/amediatech/index.rst b/doc/board/amediatech/index.rst
new file mode 100644
index 00000000000..7bc42833ec0
--- /dev/null
+++ b/doc/board/amediatech/index.rst
@@ -0,0 +1,9 @@
+.. SPDX-License-Identifier: GPL-2.0+
+
+Amediatech
+==========
+
+.. toctree::
+   :maxdepth: 2
+
+   x96q
diff --git a/doc/board/amediatech/x96q.rst b/doc/board/amediatech/x96q.rst
new file mode 100644
index 00000000000..27485c1b363
--- /dev/null
+++ b/doc/board/amediatech/x96q.rst
@@ -0,0 +1,57 @@
+.. SPDX-License-Identifier: GPL-2.0+
+
+U-Boot for the Amediatech X96Q set-top box
+==========================================
+
+Quick Start
+-----------
+
+- Get and Build the ARM Trusted Firmware (TF-A)
+- Build U-Boot
+- Write U-Boot to a microSD card
+- Boot
+
+Get and Build the ARM Trusted Firmware (TF-A)
+---------------------------------------------
+
+.. code-block:: bash
+
+    $ echo "Downloading and building TF-A..."
+    $ git clone https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git
+    $ cd trusted-firmware-a
+
+Then build TF-A:
+
+.. code-block:: bash
+
+    $ export CROSS_COMPILE=aarch64-linux-gnu-
+    $ make PLAT=sun50i_h616 bl31
+    $ cp build/sun50i_h616/release/bl31.bin ../
+
+Build U-Boot
+------------
+
+.. code-block:: bash
+
+    $ export CROSS_COMPILE=aarch64-none-elf-
+    $ make x96q_defconfig
+    $ make
+
+After the build succeeds, you will obtain the final ``u-boot-sunxi-with-spl.bin``
+image, which you can then write to a microSD card.
+
+Write U-Boot to a microSD card
+------------------------------
+
+You can then flash U-Boot to the microSD card (replace ``/dev/sdX`` with the
+card's device file):
+
+.. code-block:: bash
+
+    $ dd if=u-boot-sunxi-with-spl.bin of=/dev/sdX bs=8k seek=1
+
+Boot
+----
+
+When the X96Q is booted with the prepared microSD card inserted, it should boot
+into the freshly installed U-Boot.
diff --git a/doc/board/index.rst b/doc/board/index.rst
index 7870f1bc246..767e1831912 100644
--- a/doc/board/index.rst
+++ b/doc/board/index.rst
@@ -9,6 +9,7 @@ Board-specific doc
    acer/index
    actions/index
    advantech/index
+   amediatech/index
    andestech/index
    allwinner/index
    amlogic/index

---
base-commit: 8f520c0d5656196ec4912c837cc156a399350c33
change-id: 20251231-x96q-998c1376ebbf

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

