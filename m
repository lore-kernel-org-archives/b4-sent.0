From: Cristian Filipescu <filipescu.cristian@gmail.com>
Date: Tue, 17 Nov 2026 22:40:48 +0000
Subject: [PATCH v3] sunxi: Add Orange Pi 3 LTS defconfig
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-sunxi-orangepi-3-lts-v3-1-473ed5569351@gmail.com>
X-B4-Tracking: v=1; b=H4sIAO/X/GoC/4XOTQ7CIBAF4KsY1o4pUNG68h7GBS2DHaNtw1Sia
 Xp3QTcuNC7f/Hx5k2AMhCx2i0kEjMTUdyno5UI0re1OCORSFqpQRhZKAt+6O0Ef8m4g0HAZGZS
 3G+PQeG2kSK9DQE/3F3s4vjPf6jM2Y7byRW0ZoU5K0+bRVzVqcDhwPm+Jxz48XjWjzOyfRlFCA
 bKy2vlKbd0W96erpcuq6a8iN4rqE1E/EJWQ0tSV82tfYak/kXmenxxb6to+AQAA
X-Change-ID: 20261021-sunxi-orangepi-3-lts-2fa76de6f361
To: Andre Przywara <andre.przywara@arm.com>, 
 u-boot@lists.u-boot-project.org
Cc: Hans de Goede <hdegoede@redhat.com>, Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Cristian Filipescu <filipescu.cristian@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794955247; l=3847;
 i=filipescu.cristian@gmail.com; s=uboot-20261021; h=from:subject:message-id;
 bh=RtlKPWjNtEXF0V5zt9qRofSTktGUys8yyv2cqLufyu8=;
 b=SirQuTYr0H4Ns1jO9KpQVx9CsHPZyjl+EO+hgcZgmp7KW7/IwTi6U//WpCp0rZ1LJpPrrHEVa
 GpDtUGY3D7xCq8Q8PFxMnjZHHW7Y1eHmROQTCAcuimWx4jUyaGTAe9w
X-Developer-Key: i=filipescu.cristian@gmail.com; a=ed25519;
 pk=o7Ui0tU3x+X/6Pq6PZHmd2KFtOdPWttoPuNFOvdD8t0=
X-Endpoint-Received: by B4 Relay for filipescu.cristian@gmail.com/uboot-20261021 with auth_id=1255
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a configuration for the H6-based Orange Pi 3 LTS using the upstream
Linux device tree. Enable the Motorcomm PHY driver and use red PL4 as
the power indicator through the existing SPL LED hook.

The sun8i EMAC driver reads MAC-level reset properties rather than the
MDIO bus reset in the Linux DTS. Provide the equivalent PD14 reset and
timings in a U-Boot-specific fragment.

Signed-off-by: Cristian Filipescu <filipescu.cristian@gmail.com>
---
Add the Orange Pi 3 LTS defconfig using the upstream Linux DTS and the
existing SPL power LED hook.

The Linux DTS is accepted in sunxi/dt-for-7.5:
https://git.kernel.org/sunxi/linux/c/a203a4bac331
This revision depends on its devicetree-rebasing import and the shared H6
DVFS update. The local DT staging commit is excluded from this submission.

Both defconfigs build with GCC 14.2 and TF-A v2.13.0. On the LTS board,
SD boot, U-Boot DHCP/ping, USB 3 storage enumeration at 5 Gb/s, and red-on /
green-off LED state passed. Linux boots successfully; its board checks and
768 MiB of eMMC HS200 reads at 150 MHz passed with zero reported errors.
Preparation used OpenAI Codex.
---
Changes in v3:
- Select OF_UPSTREAM and the accepted Linux board description.
- Remove the board-specific handoff hook and main U-Boot LED settings;
  use the SPL LED hook for red PL4.
- Supply the existing EMAC driver's reset properties in a U-Boot fragment.
- Rebase onto U-Boot main (2027.01-rc2).

Link to v2: https://lore.kernel.org/u-boot/20261022-sunxi-orangepi-3-lts-v2-0-46b9df5f9e43@gmail.com/
---
 arch/arm/dts/sun50i-h6-orangepi-3-lts-u-boot.dtsi |  9 +++++++++
 board/sunxi/MAINTAINERS                           |  6 ++++++
 configs/orangepi_3_lts_defconfig                  | 20 ++++++++++++++++++++
 3 files changed, 35 insertions(+)

diff --git a/arch/arm/dts/sun50i-h6-orangepi-3-lts-u-boot.dtsi b/arch/arm/dts/sun50i-h6-orangepi-3-lts-u-boot.dtsi
new file mode 100644
index 00000000..cfbfe60e
--- /dev/null
+++ b/arch/arm/dts/sun50i-h6-orangepi-3-lts-u-boot.dtsi
@@ -0,0 +1,9 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
+
+#include "sunxi-u-boot.dtsi"
+
+/* The sun8i EMAC driver uses the MAC-level reset properties. */
+&emac {
+	snps,reset-gpio = <&pio 3 14 GPIO_ACTIVE_LOW>; /* PD14 */
+	snps,reset-delays-us = <0 15000 100000>;
+};
diff --git a/board/sunxi/MAINTAINERS b/board/sunxi/MAINTAINERS
index 344f52ea..36db194e 100644
--- a/board/sunxi/MAINTAINERS
+++ b/board/sunxi/MAINTAINERS
@@ -443,6 +443,12 @@ M:	Andre Heider <a.heider@gmail.com>
 S:	Maintained
 F:	configs/orangepi_3_defconfig
 
+ORANGEPI 3 LTS BOARD
+M:	Cristian Filipescu <filipescu.cristian@gmail.com>
+S:	Maintained
+F:	arch/arm/dts/sun50i-h6-orangepi-3-lts-u-boot.dtsi
+F:	configs/orangepi_3_lts_defconfig
+
 ORANGEPI 4A BOARD
 M:	Chen-Yu Tsai <wens@kernel.org>
 S:	Maintained
diff --git a/configs/orangepi_3_lts_defconfig b/configs/orangepi_3_lts_defconfig
new file mode 100644
index 00000000..85ee37c2
--- /dev/null
+++ b/configs/orangepi_3_lts_defconfig
@@ -0,0 +1,20 @@
+CONFIG_ARM=y
+CONFIG_ARCH_SUNXI=y
+CONFIG_DEFAULT_DEVICE_TREE="allwinner/sun50i-h6-orangepi-3-lts"
+CONFIG_SPL=y
+CONFIG_MACH_SUN50I_H6=y
+CONFIG_SUNXI_DRAM_H6_LPDDR3=y
+CONFIG_MMC_SUNXI_SLOT_EXTRA=2
+CONFIG_SPL_SUNXI_LED_STATUS=y
+CONFIG_SPL_SUNXI_LED_STATUS_GPIO=356
+# CONFIG_SYS_MALLOC_CLEAR_ON_INIT is not set
+CONFIG_OF_UPSTREAM=y
+CONFIG_SUN8I_EMAC=y
+CONFIG_PHY_MOTORCOMM=y
+CONFIG_PHY_SUN50I_USB3=y
+CONFIG_USB_XHCI_HCD=y
+CONFIG_USB_XHCI_DWC3=y
+CONFIG_USB_EHCI_HCD=y
+CONFIG_USB_OHCI_HCD=y
+CONFIG_USB_DWC3=y
+# CONFIG_USB_DWC3_GADGET is not set

---
base-commit: 45516c31e1227746cda1078897fd44ec1e494a98
change-id: 20261021-sunxi-orangepi-3-lts-2fa76de6f361

Best regards,
--  
Cristian Filipescu <filipescu.cristian@gmail.com>

