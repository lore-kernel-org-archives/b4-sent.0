From: Cristian Filipescu <filipescu.cristian@gmail.com>
Date: Thu, 22 Oct 2026 05:55:02 +0000
Subject: [PATCH v2 2/2] sunxi: Add Orange Pi 3 LTS defconfig
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-sunxi-orangepi-3-lts-v2-2-46b9df5f9e43@gmail.com>
References: <20261022-sunxi-orangepi-3-lts-v2-0-46b9df5f9e43@gmail.com>
In-Reply-To: <20261022-sunxi-orangepi-3-lts-v2-0-46b9df5f9e43@gmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Andre Przywara <andre.przywara@arm.com>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Hans de Goede <hdegoede@redhat.com>, 
 Cristian Filipescu <filipescu.cristian@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792648514; l=3227;
 i=filipescu.cristian@gmail.com; s=uboot-20261021; h=from:subject:message-id;
 bh=wQbVA8bqEQVClwmJkwr0zVm+czfrqdl+XPM9uwHmMGM=;
 b=nitYkL+q0Mhp42nAwwGN+0BdMJbMnkLgqG8LCiXzI04SbHC/ENhCxvXJuvBipi3hgUasyvB7v
 UDUwhonlSUMDD8alFoX5VQ3E0ADi1yK6qBKUqEORGiuwQ1N5rtEEqmr
X-Developer-Key: i=filipescu.cristian@gmail.com; a=ed25519;
 pk=o7Ui0tU3x+X/6Pq6PZHmd2KFtOdPWttoPuNFOvdD8t0=
X-Endpoint-Received: by B4 Relay for filipescu.cristian@gmail.com/uboot-20261021 with auth_id=1255
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a separate configuration for the Orange Pi 3 LTS, using its local
device tree rather than the original Orange Pi 3 board description.

Reuse the H6 LPDDR3, SD/eMMC and USB configuration from orangepi_3.
Enable the sun8i EMAC and Motorcomm PHY driver for the LTS Ethernet
hardware, and omit the AP6256-specific Bluetooth fixup used by the
original board.

Enable GPIO LEDs in main U-Boot to light the green power LED on PL7.
Leave the early SPL status LED disabled. At the OS handoff, turn off
green and turn on red before Linux initializes its LED driver. Limit
this indication to the Orange Pi 3 LTS board compatible.

Extend the board maintainer entry to cover the new configuration.

Signed-off-by: Cristian Filipescu <filipescu.cristian@gmail.com>
---
 board/sunxi/MAINTAINERS          |  1 +
 board/sunxi/board.c              | 19 +++++++++++++++++++
 configs/orangepi_3_lts_defconfig | 19 +++++++++++++++++++
 3 files changed, 39 insertions(+)

diff --git a/board/sunxi/MAINTAINERS b/board/sunxi/MAINTAINERS
index e84219e2..6a47b9cc 100644
--- a/board/sunxi/MAINTAINERS
+++ b/board/sunxi/MAINTAINERS
@@ -442,6 +442,7 @@ ORANGEPI 3 LTS BOARD
 M:	Cristian Filipescu <filipescu.cristian@gmail.com>
 S:	Maintained
 F:	arch/arm/dts/sun50i-h6-orangepi-3-lts.dts
+F:	configs/orangepi_3_lts_defconfig
 F:	arch/arm/dts/sun50i-h6-orangepi-3-lts-u-boot.dtsi
 
 ORANGEPI 4A BOARD
diff --git a/board/sunxi/board.c b/board/sunxi/board.c
index 3d1afec7..7b735a26 100644
--- a/board/sunxi/board.c
+++ b/board/sunxi/board.c
@@ -10,6 +10,7 @@
  * Some board init for the Allwinner A10-evb board.
  */
 
+#include <bootm.h>
 #include <clock_legacy.h>
 #include <dm.h>
 #include <env.h>
@@ -17,6 +18,7 @@
 #include <i2c.h>
 #include <image.h>
 #include <init.h>
+#include <led.h>
 #include <log.h>
 #include <mmc.h>
 #include <axp_pmic.h>
@@ -875,6 +877,23 @@ int board_late_init(void)
 	return 0;
 }
 
+void board_quiesce_devices(void)
+{
+	struct udevice *dev;
+
+	if (!CONFIG_IS_ENABLED(LED))
+		return;
+
+	if (!of_machine_is_compatible("xunlong,orangepi-3-lts"))
+		return;
+
+	/* Indicate the OS handoff before Linux initializes its LED driver. */
+	if (!led_get_by_label("red:status", &dev))
+		led_set_state(dev, LEDST_ON);
+	if (!led_get_by_label("green:power", &dev))
+		led_set_state(dev, LEDST_OFF);
+}
+
 static void bluetooth_dt_fixup(void *blob)
 {
 	/* Some devices ship with a Bluetooth controller default address.
diff --git a/configs/orangepi_3_lts_defconfig b/configs/orangepi_3_lts_defconfig
new file mode 100644
index 00000000..b7571134
--- /dev/null
+++ b/configs/orangepi_3_lts_defconfig
@@ -0,0 +1,19 @@
+CONFIG_ARM=y
+CONFIG_ARCH_SUNXI=y
+CONFIG_DEFAULT_DEVICE_TREE="sun50i-h6-orangepi-3-lts"
+CONFIG_SPL=y
+CONFIG_MACH_SUN50I_H6=y
+CONFIG_SUNXI_DRAM_H6_LPDDR3=y
+CONFIG_MMC_SUNXI_SLOT_EXTRA=2
+# CONFIG_SYS_MALLOC_CLEAR_ON_INIT is not set
+CONFIG_LED=y
+CONFIG_LED_GPIO=y
+CONFIG_SUN8I_EMAC=y
+CONFIG_PHY_MOTORCOMM=y
+CONFIG_PHY_SUN50I_USB3=y
+CONFIG_USB_XHCI_HCD=y
+CONFIG_USB_XHCI_DWC3=y
+CONFIG_USB_EHCI_HCD=y
+CONFIG_USB_OHCI_HCD=y
+CONFIG_USB_DWC3=y
+# CONFIG_USB_DWC3_GADGET is not set

-- 
2.47.3

