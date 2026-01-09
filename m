From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Sat, 10 Jan 2026 00:10:32 +0100
Subject: [PATCH next v2] board: amediatech: Add X96Q support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260110-x96q-v2-1-1d6a725eb825@posteo.net>
X-B4-Tracking: v=1; b=H4sIAOeKYWkC/1XMSw7CIBAG4Ks0sxbDQKTFVe9hXEg7WDZQgRBMw
 90l3bn8H/kOSBQdJbgPB0QqLrngexCXAZbt5d/E3NozCC5uKCSyqtWHaT0tKEdFxljo1z2SdfV
 kHuCpZnj2dnMph/g97YLn9s8UZMgkqnXk0kyWy3kPKVO4eupCa+0HQq0tv58AAAA=
X-Change-ID: 20251231-x96q-998c1376ebbf
To: u-boot@lists.denx.de
Cc: Tom Rini <trini@konsulko.com>, Svyatoslav Ryhel <clamor95@gmail.com>, 
 Leo Yu-Chi Liang <ycliang@andestech.com>, Peter Geis <pgwipeout@gmail.com>, 
 Lukasz Majewski <lukma@denx.de>, Junhui Liu <junhui.liu@pigmoral.tech>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Andre Przywara <andre.przywara@arm.com>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768000246; l=4812;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=lwxA+pVpi1zVG1Z9trQLk9vTs+/3l5841fsJtjOQVsQ=;
 b=qqzQucuPNH5WCSrk01ybLOzckSH/h1/5QVsfPLdyD8JO4A68XSdwpGZ2P+TUEnGV0cNE8Sq7O
 oI5YkEijzo3ARbxvkUUoaJvOp6KJad1FLTuuZZCllxppfRXVUEfe1kV
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
observed when booting with the preinstalled vendor U-Boot. The DRAM
clock frequency of 600 MHz was reported in the vendor U-Boot's output.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
Changes in v2:
- Add missing Signed-off-by
- Re-generate x96q_defconfig with 'make savedefconfig'
- Move DRAM frequency comment to commit message
- Use GPL-2.0-or-later instead of deprecated GPL-2.0+
- Link to v1: https://lore.kernel.org/r/20251231-x96q-v1-1-316d703b8f03@posteo.net
---
 configs/x96q_defconfig         | 31 +++++++++++++++++++++++
 doc/board/amediatech/index.rst |  9 +++++++
 doc/board/amediatech/x96q.rst  | 57 ++++++++++++++++++++++++++++++++++++++++++
 doc/board/index.rst            |  1 +
 4 files changed, 98 insertions(+)

diff --git a/configs/x96q_defconfig b/configs/x96q_defconfig
new file mode 100644
index 00000000000..b74a1b61f3c
--- /dev/null
+++ b/configs/x96q_defconfig
@@ -0,0 +1,31 @@
+CONFIG_ARM=y
+CONFIG_ARCH_SUNXI=y
+CONFIG_DEFAULT_DEVICE_TREE="allwinner/sun50i-h313-x96q"
+CONFIG_DRAM_CLK=600
+CONFIG_SPL=y
+CONFIG_DRAM_SUNXI_DX_ODT=0x03030303
+CONFIG_DRAM_SUNXI_DX_DRI=0x0e0e0e0e
+CONFIG_DRAM_SUNXI_CA_DRI=0x1f12
+CONFIG_DRAM_SUNXI_TPR0=0xc0001002
+CONFIG_DRAM_SUNXI_TPR2=0x00000100
+CONFIG_DRAM_SUNXI_TPR10=0x002f0107
+CONFIG_DRAM_SUNXI_TPR11=0xddddcccc
+CONFIG_DRAM_SUNXI_TPR12=0xeddc7665
+CONFIG_MACH_SUN50I_H616=y
+CONFIG_SUNXI_DRAM_H616_DDR3_1333=y
+CONFIG_R_I2C_ENABLE=y
+# CONFIG_SYS_MALLOC_CLEAR_ON_INIT is not set
+CONFIG_FIT_BEST_MATCH=y
+CONFIG_SPL_I2C=y
+CONFIG_CMD_UFETCH=y
+CONFIG_CMD_CAT=y
+CONFIG_SPL_SYS_I2C_LEGACY=y
+CONFIG_SYS_I2C_MVTWSI=y
+CONFIG_SYS_I2C_SLAVE=0x7f
+CONFIG_SYS_I2C_SPEED=400000
+CONFIG_SUPPORT_EMMC_BOOT=y
+CONFIG_SUN8I_EMAC=y
+CONFIG_AXP305_POWER=y
+CONFIG_USB_EHCI_HCD=y
+CONFIG_USB_OHCI_HCD=y
+CONFIG_SPL_USE_TINY_PRINTF_POINTER_SUPPORT=y
diff --git a/doc/board/amediatech/index.rst b/doc/board/amediatech/index.rst
new file mode 100644
index 00000000000..fd0241e3459
--- /dev/null
+++ b/doc/board/amediatech/index.rst
@@ -0,0 +1,9 @@
+.. SPDX-License-Identifier: GPL-2.0-or-later
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
index 00000000000..f220b7005b2
--- /dev/null
+++ b/doc/board/amediatech/x96q.rst
@@ -0,0 +1,57 @@
+.. SPDX-License-Identifier: GPL-2.0-or-later
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
base-commit: 6cdd7597a2fbfc1572c1b0af23d3daf1cefa2de7
change-id: 20251231-x96q-998c1376ebbf

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

