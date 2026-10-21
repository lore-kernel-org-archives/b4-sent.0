From: Igor Velkov <iav@iav.lv>
Date: Wed, 21 Oct 2026 01:04:56 +0000
Subject: [PATCH] board: rockchip: Add Kobol Helios64
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-b4-helios64-v1-1-74afe8aa6d72@iav.lv>
X-B4-Tracking: v=1; b=H4sIALcP2GoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAyND3SQT3YzUnMz8YjMTXXPDNANDy5RUixTzFCWgjoKi1LTMCrBp0bG
 1tQBlaRCuXQAAAA==
To: Kever Yang <kever.yang@rock-chips.com>, 
 Quentin Schulz <u-boot@0leil.net>
Cc: Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 u-boot@lists.u-boot-project.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=6017; i=iav@iav.lv;
 h=from:subject:message-id; bh=3+UEmDnW08wUi5ddmfoslkMBlNYflMFw3+LKhxEgaU4=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFk3+Hdp2pWV7Ck++Ca85/78ld3rNl7247LcFTsp7cDmZ
 jFr+6btHaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAiZuqMDDv+Xnu1z+bI/u9l
 vpGRem95d8p7FQnoiVjfYOK6/nTfOQeGf/qXf5goS1/4np612Gtdq5+21iznAKl7x3jFOf+emCE
 4kwkA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the Kobol Helios64, an RK3399 NAS board with 4 GiB of
LPDDR4, eMMC, SD card, SPI NOR flash, a 1 GbE RTL8211F PHY, a 2.5 GbE
RTL8156 on USB and a JMB585 SATA controller on PCIe.

The board uses the upstream device tree. The -u-boot.dtsi adds the
LPDDR4 timings for the open-source TPL and the vdd_log PWM regulator
and the vdd_center RK808 buck, which the upstream device tree does not
describe yet, and sets both rails to 950 mV. RockPro64 sets vdd_center
the same way, see commit f210cbc1f3d4 ("arm: dts: rk3399-rockpro64:
slightly increase center voltage").

Without the vdd_log and vdd_center nodes, Linux 7.3 reset or hung about
2.3 s into the boot in 2 of 2 cold boots. With both rails at 950 mV,
20 cold boots of Linux 7.3 showed no memory errors.

Features tested on a Helios64:
- eMMC boot (TF-A v2.13.0 BL31, open-source TPL)
- GMAC Ethernet (DHCP, TFTP)
- USB 3 host

Not working yet: PCIe (pcie_rockchip fails to request ep-gpios).
SD card and SPI flash boot are untested.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
No MAINTAINERS entry on purpose: I cannot commit to maintaining the
board. It falls under ARM ROCKCHIP via "N: rk3", and
buildman --maintainer-check passes.
---
 arch/arm/dts/rk3399-kobol-helios64-u-boot.dtsi | 56 +++++++++++++++++
 configs/helios64-rk3399_defconfig              | 84 ++++++++++++++++++++++++++
 doc/board/rockchip/rockchip.rst                |  1 +
 3 files changed, 141 insertions(+)

diff --git a/arch/arm/dts/rk3399-kobol-helios64-u-boot.dtsi b/arch/arm/dts/rk3399-kobol-helios64-u-boot.dtsi
new file mode 100644
index 00000000000..0f8e9353066
--- /dev/null
+++ b/arch/arm/dts/rk3399-kobol-helios64-u-boot.dtsi
@@ -0,0 +1,56 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+#include "rk3399-u-boot.dtsi"
+#include "rk3399-sdram-lpddr4-100.dtsi"
+
+/ {
+	vdd_log: regulator-vdd-log {
+		compatible = "pwm-regulator";
+		pwms = <&pwm2 0 25000 1>;
+		pwm-supply = <&vcc5v0_sys>;
+		regulator-name = "vdd_log";
+		regulator-always-on;
+		regulator-boot-on;
+		regulator-min-microvolt = <830000>;
+		regulator-max-microvolt = <1400000>;
+		regulator-init-microvolt = <950000>;
+	};
+};
+
+&pwm2 {
+	status = "okay";
+};
+
+&rk808 {
+	regulators {
+		vdd_center: DCDC_REG1 {
+			regulator-name = "vdd_center";
+			regulator-always-on;
+			regulator-boot-on;
+			regulator-min-microvolt = <950000>;
+			regulator-max-microvolt = <950000>;
+		};
+	};
+};
+
+&gpio0 {
+	bootph-pre-ram;
+};
+
+&sdhci {
+	cap-mmc-highspeed;
+	mmc-ddr-1_8v;
+};
+
+&sdmmc0_pwr_h {
+	bootph-pre-ram;
+};
+
+&spiflash {
+	bootph-pre-ram;
+	bootph-some-ram;
+};
+
+&vcc3v0_sd {
+	bootph-pre-ram;
+};
diff --git a/configs/helios64-rk3399_defconfig b/configs/helios64-rk3399_defconfig
new file mode 100644
index 00000000000..16cddc71e0d
--- /dev/null
+++ b/configs/helios64-rk3399_defconfig
@@ -0,0 +1,84 @@
+CONFIG_ARM=y
+CONFIG_SKIP_LOWLEVEL_INIT=y
+CONFIG_COUNTER_FREQUENCY=24000000
+CONFIG_ARCH_ROCKCHIP=y
+CONFIG_SPL_GPIO=y
+CONFIG_NR_DRAM_BANKS=1
+CONFIG_SF_DEFAULT_SPEED=25000000
+CONFIG_ENV_OFFSET=0x3F8000
+CONFIG_DEFAULT_DEVICE_TREE="rockchip/rk3399-kobol-helios64"
+CONFIG_DM_RESET=y
+CONFIG_ROCKCHIP_RK3399=y
+CONFIG_ROCKCHIP_SPI_IMAGE=y
+CONFIG_TARGET_EVB_RK3399=y
+CONFIG_SYS_LOAD_ADDR=0x800800
+CONFIG_SF_DEFAULT_BUS=1
+CONFIG_DEBUG_UART_BASE=0xFF1A0000
+CONFIG_DEBUG_UART_CLOCK=24000000
+CONFIG_SPL_SPI_FLASH_SUPPORT=y
+CONFIG_SPL_SPI=y
+CONFIG_PCI=y
+CONFIG_DEBUG_UART=y
+CONFIG_DEFAULT_FDT_FILE="rockchip/rk3399-kobol-helios64.dtb"
+CONFIG_DISPLAY_BOARDINFO_LATE=y
+CONFIG_SPL_MAX_SIZE=0x40000
+# CONFIG_SPL_RAW_IMAGE_SUPPORT is not set
+CONFIG_SPL_SPI_LOAD=y
+CONFIG_SYS_SPI_U_BOOT_OFFS=0xE0000
+CONFIG_SPL_ATF_NO_PLATFORM_PARAM=y
+CONFIG_TPL=y
+CONFIG_CMD_BOOTZ=y
+CONFIG_CMD_GPT=y
+CONFIG_CMD_MMC=y
+CONFIG_CMD_PCI=y
+CONFIG_CMD_POWEROFF=y
+CONFIG_CMD_USB=y
+CONFIG_CMD_TIME=y
+CONFIG_SPL_OF_CONTROL=y
+CONFIG_OF_SPL_REMOVE_PROPS="clock-names interrupt-parent assigned-clocks assigned-clock-rates assigned-clock-parents"
+CONFIG_ENV_IS_IN_MMC=y
+CONFIG_ENV_RELOC_GD_ENV_ADDR=y
+CONFIG_SCSI_AHCI=y
+CONFIG_AHCI_PCI=y
+CONFIG_ROCKCHIP_GPIO=y
+CONFIG_SYS_I2C_ROCKCHIP=y
+CONFIG_LED=y
+CONFIG_LED_GPIO=y
+CONFIG_MMC_DW=y
+CONFIG_MMC_DW_ROCKCHIP=y
+CONFIG_MMC_SDHCI=y
+CONFIG_MMC_SDHCI_SDMA=y
+CONFIG_MMC_SDHCI_ROCKCHIP=y
+CONFIG_SPI_FLASH_SFDP_SUPPORT=y
+CONFIG_SPI_FLASH_WINBOND=y
+CONFIG_DM_ETH_PHY=y
+CONFIG_ETH_DESIGNWARE=y
+CONFIG_GMAC_ROCKCHIP=y
+CONFIG_PHY_REALTEK=y
+CONFIG_PHY_ROCKCHIP_INNO_USB2=y
+CONFIG_PHY_ROCKCHIP_TYPEC=y
+CONFIG_PMIC_RK8XX=y
+CONFIG_REGULATOR_PWM=y
+CONFIG_SPL_DM_REGULATOR_FIXED=y
+CONFIG_REGULATOR_RK8XX=y
+CONFIG_PWM_ROCKCHIP=y
+CONFIG_RAM_ROCKCHIP_LPDDR4=y
+CONFIG_SCSI=y
+CONFIG_BAUDRATE=1500000
+CONFIG_DEBUG_UART_SHIFT=2
+CONFIG_SYS_NS16550_MEM32=y
+CONFIG_ROCKCHIP_SPI=y
+CONFIG_SYSRESET=y
+CONFIG_USB=y
+CONFIG_USB_XHCI_HCD=y
+CONFIG_USB_EHCI_HCD=y
+CONFIG_USB_EHCI_GENERIC=y
+CONFIG_USB_DWC3=y
+CONFIG_USB_DWC3_GENERIC=y
+CONFIG_USB_HOST_ETHER=y
+CONFIG_USB_ETHER_ASIX=y
+CONFIG_USB_ETHER_ASIX88179=y
+CONFIG_USB_ETHER_MCS7830=y
+CONFIG_USB_ETHER_RTL8152=y
+CONFIG_USB_ETHER_SMSC95XX=y
+CONFIG_ERRNO_STR=y
diff --git a/doc/board/rockchip/rockchip.rst b/doc/board/rockchip/rockchip.rst
index 1f4e58c8be2..5a842fc6b30 100644
--- a/doc/board/rockchip/rockchip.rst
+++ b/doc/board/rockchip/rockchip.rst
@@ -92,6 +92,7 @@ List of mainline supported Rockchip boards:
      - Khadas Edge (khadas-edge-rk3399)
      - Khadas Edge-Captain (khadas-edge-captain-rk3399)
      - Khadas Edge-V (hadas-edge-v-rk3399)
+     - Kobol Helios64 (helios64-rk3399)
      - Orange Pi RK3399 (orangepi-rk3399)
      - Pine64 RockPro64 (rockpro64-rk3399)
      - Radxa ROCK 4C+ (rock-4c-plus-rk3399)

---
base-commit: 8d534cec0cc0109a37c0ded8854da03f1526dc0e
change-id: 20261021-b4-helios64-71f019de8d7d

Best regards,
-- 
Igor Velkov <iav@iav.lv>

