From: Cristian Filipescu <filipescu.cristian@gmail.com>
Date: Wed, 21 Oct 2026 21:13:03 +0000
Subject: [PATCH 2/2] sunxi: Add Orange Pi 3 LTS defconfig
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-sunxi-orangepi-3-lts-v1-2-19a3df928d8e@gmail.com>
References: <20261021-sunxi-orangepi-3-lts-v1-0-19a3df928d8e@gmail.com>
In-Reply-To: <20261021-sunxi-orangepi-3-lts-v1-0-19a3df928d8e@gmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Andre Przywara <andre.przywara@arm.com>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Hans de Goede <hdegoede@redhat.com>, 
 Cristian Filipescu <filipescu.cristian@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792617188; l=1891;
 i=filipescu.cristian@gmail.com; s=uboot-20261021; h=from:subject:message-id;
 bh=HvU21ZMzEGvwYkPObbwn9lpHNTQRijMbSEhw2+ViKhA=;
 b=FJNrwcRX4fl0BLBBnIUcqbJKTDoXAlzMNRTPk7jQ37ir7d50h42S8IOLccCIKr3DnrOlq2l2z
 J2rmZ4KcW6iD+lpYHZlsVom7ACVjIsWh7sNqne/W+8vtDJhrrGTXv3o
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

Use the green power LED on PL7 for the SPL status indication.

Extend the board maintainer entry to cover the new configuration.

Signed-off-by: Cristian Filipescu <filipescu.cristian@gmail.com>
---
 board/sunxi/MAINTAINERS          |  1 +
 configs/orangepi_3_lts_defconfig | 19 +++++++++++++++++++
 2 files changed, 20 insertions(+)

diff --git a/board/sunxi/MAINTAINERS b/board/sunxi/MAINTAINERS
index a7c17fb4..40e1c505 100644
--- a/board/sunxi/MAINTAINERS
+++ b/board/sunxi/MAINTAINERS
@@ -442,6 +442,7 @@ ORANGEPI 3 LTS BOARD
 M:	Cristian Filipescu <filipescu.cristian@gmail.com>
 S:	Maintained
 F:	arch/arm/dts/sun50i-h6-orangepi-3-lts.dts
+F:	configs/orangepi_3_lts_defconfig
 
 ORANGEPI 4A BOARD
 M:	Chen-Yu Tsai <wens@kernel.org>
diff --git a/configs/orangepi_3_lts_defconfig b/configs/orangepi_3_lts_defconfig
new file mode 100644
index 00000000..5e5d872c
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
+CONFIG_SPL_SUNXI_LED_STATUS=y
+CONFIG_SPL_SUNXI_LED_STATUS_GPIO=359
+# CONFIG_SYS_MALLOC_CLEAR_ON_INIT is not set
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

