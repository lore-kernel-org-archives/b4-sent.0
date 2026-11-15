From: Igor Velkov <iav@iav.lv>
Date: Sun, 15 Nov 2026 03:50:32 +0000
Subject: [PATCH 3/3] configs: odroid-c4, odroid-hc4: enable Wake-on-LAN
 from suspend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-b4-meson-scp-wol-v1-3-80c3e9f4deda@iav.lv>
References: <20261115-b4-meson-scp-wol-v1-0-80c3e9f4deda@iav.lv>
In-Reply-To: <20261115-b4-meson-scp-wol-v1-0-80c3e9f4deda@iav.lv>
To: Neil Armstrong <neil.armstrong@linaro.org>, u-boot-amlogic@groups.io
Cc: Tom Rini <trini@konsulko.com>, u-boot@lists.u-boot-project.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3105; i=iav@iav.lv;
 h=from:subject:message-id; bh=TR7+WSUw912x4EZh77Z+Wcm/UCk/rDcRO5KtEgwiol8=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFk/dTgiX8SIPuY++9jozibj8weXz5lx9O2Bp++28Tcoa
 YYFe92Y01HKwiDGxSArpsgy4ZDGrYwlV//6e5g/gJnDygQyhIGLUwAmUj2X4Z/u4qVr2R973hUN
 +una0cPo8ftPZuU1sTnL03pm/he5vzyJ4a9Q59b8bzkfdqterz1qoyyiniC4NMzo76brqxguVF1
 u+cEOAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable CONFIG_MESON_G12A_SCPI so that U-Boot tells BL301 whether to
wake the board on the Ethernet PHY in suspend, and describe it in the
board docs.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 configs/odroid-c4_defconfig      | 1 +
 configs/odroid-hc4_defconfig     | 1 +
 doc/board/amlogic/odroid-c4.rst  | 9 +++++++++
 doc/board/amlogic/odroid-hc4.rst | 9 +++++++++
 4 files changed, 20 insertions(+)

diff --git a/configs/odroid-c4_defconfig b/configs/odroid-c4_defconfig
index f42fa0789d6..55e62f7f1cf 100644
--- a/configs/odroid-c4_defconfig
+++ b/configs/odroid-c4_defconfig
@@ -11,6 +11,7 @@ CONFIG_DEFAULT_DEVICE_TREE="amlogic/meson-sm1-odroid-c4"
 CONFIG_OF_LIBFDT_OVERLAY=y
 CONFIG_DM_RESET=y
 CONFIG_MESON_G12A=y
+CONFIG_MESON_G12A_SCPI=y
 CONFIG_SYS_LOAD_ADDR=0x1000000
 CONFIG_DEBUG_UART_BASE=0xff803000
 CONFIG_DEBUG_UART_CLOCK=24000000
diff --git a/configs/odroid-hc4_defconfig b/configs/odroid-hc4_defconfig
index 694db0684e7..1d18070d265 100644
--- a/configs/odroid-hc4_defconfig
+++ b/configs/odroid-hc4_defconfig
@@ -11,6 +11,7 @@ CONFIG_DEFAULT_DEVICE_TREE="amlogic/meson-sm1-odroid-hc4"
 CONFIG_OF_LIBFDT_OVERLAY=y
 CONFIG_DM_RESET=y
 CONFIG_MESON_G12A=y
+CONFIG_MESON_G12A_SCPI=y
 CONFIG_SYS_LOAD_ADDR=0x1000000
 CONFIG_DEBUG_UART_BASE=0xff803000
 CONFIG_DEBUG_UART_CLOCK=24000000
diff --git a/doc/board/amlogic/odroid-c4.rst b/doc/board/amlogic/odroid-c4.rst
index 6994b958cf8..2df7afd71bc 100644
--- a/doc/board/amlogic/odroid-c4.rst
+++ b/doc/board/amlogic/odroid-c4.rst
@@ -141,3 +141,12 @@ Then write the image to SD or eMMC with:
     $ DEV=/dev/boot_device
     $ dd if=fip/u-boot.bin.sd.bin of=$DEV conv=fsync,notrunc bs=512 skip=1 seek=1
     $ dd if=fip/u-boot.bin.sd.bin of=$DEV conv=fsync,notrunc bs=1 count=440
+
+Wake-on-LAN from suspend
+------------------------
+
+The BL301 firmware built from the Hardkernel sources wakes the board on the
+Ethernet PHY interrupt, and keeps the VCCK_B and 3.3 V rails on in suspend
+for it, only when told to. With ``CONFIG_MESON_G12A_SCPI``, U-Boot tells it
+to when the PHY node of the device tree passed to the OS has the
+``wakeup-source`` property, and tells it not to otherwise.
diff --git a/doc/board/amlogic/odroid-hc4.rst b/doc/board/amlogic/odroid-hc4.rst
index 1d37be2d80e..ccf30de5350 100644
--- a/doc/board/amlogic/odroid-hc4.rst
+++ b/doc/board/amlogic/odroid-hc4.rst
@@ -140,3 +140,12 @@ Then write U-Boot to SD or SPI-NOR with:
     $ DEV=/dev/boot_device
     $ dd if=fip/u-boot.bin.sd.bin of=$DEV conv=fsync,notrunc bs=512 skip=1 seek=1
     $ dd if=fip/u-boot.bin.sd.bin of=$DEV conv=fsync,notrunc bs=1 count=440
+
+Wake-on-LAN from suspend
+------------------------
+
+The BL301 firmware built from the Hardkernel sources wakes the board on the
+Ethernet PHY interrupt, and keeps the VCCK_B and 3.3 V rails on in suspend
+for it, only when told to. With ``CONFIG_MESON_G12A_SCPI``, U-Boot tells it
+to when the PHY node of the device tree passed to the OS has the
+``wakeup-source`` property, and tells it not to otherwise.

-- 
2.43.0

