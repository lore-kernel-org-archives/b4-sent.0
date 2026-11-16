From: Igor Velkov <iav@iav.lv>
Date: Mon, 16 Nov 2026 00:19:57 +0000
Subject: [PATCH v2] board: rockchip: Add Kobol Helios64
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-b4-helios64-v2-1-3631141e429e@iav.lv>
X-B4-Tracking: v=1; b=H4sIACxM+moC/23MQQrCMBCF4auUWTuSCSGprryHdBHNxAyUVhIJS
 sndjV27/B+8b4PCWbjAedggc5Ui69JDHwa4J788GCX0Bq20JaUJbwYTz7IWa9BRVHQKPAYXoD+
 emaO8d+069U5SXmv+7Hil3/rfqYSEzvjIo/c2OH0RX49zham19gWN5CXRowAAAA==
To: Kever Yang <kever.yang@rock-chips.com>, 
 Quentin Schulz <u-boot@0leil.net>
Cc: Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 u-boot@lists.u-boot-project.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=8534; i=iav@iav.lv;
 h=from:subject:message-id; bh=FG8iV04kG5xqqb4pjZAAv2G2Zl4yqRflIsHr3IP1tNs=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFm/fPRyFk5aPX3lbo+C2p6fe+ceWhzeH7uv8P0c8elLj
 cRy1ooLdZSyMIhxMciKKbJMOKRxK2PJ1b/+HuYPYOawMoEMYeDiFICJZF9h+KfQN3HTB03ug//q
 mZtE4jc1qb1k22W0+m15O+9Vh25Zm6UM/4OSZNR4Xz74o5wZ8+Wwga7VUafLM2qULnmw/V3ONif
 KiAkA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the Kobol Helios64, an RK3399 NAS board with 4 GiB of
LPDDR4, eMMC, SD card, SPI NOR flash, a 1 GbE RTL8211F PHY, a 2.5 GbE
RTL8156 on USB and a JMB585 SATA controller on PCIe.

The board uses the upstream device tree. The -u-boot.dtsi adds the
LPDDR4 timings for the open-source TPL and the vdd_log PWM regulator
and the vdd_center RK808 buck, and sets both rails to 950 mV. RockPro64
sets vdd_center the same way, see commit f210cbc1f3d4 ("arm: dts:
rk3399-rockpro64: slightly increase center voltage").

The upstream device tree gains both rails in Linux 7.5. Until
dts/upstream catches up, the -u-boot.dtsi describes them; after that
only the 950 mV settings remain here.

Without the vdd_log and vdd_center nodes, Linux 7.3 reset or hung about
2.3 s into the boot in 2 of 2 cold boots. With both rails at 950 mV,
20 cold boots of Linux 7.3 showed no memory errors.

Linux can leave the SD card at 1.8 V across a watchdog reset or a panic,
and the RK808 LDO that supplies the card I/O (vcc_sdio_s0) keeps that
voltage. Enable the IO-domain driver in SPL, so that SPL sets the SDMMC
IO domain from the voltage of that regulator and can read the card.

U-Boot proper sits at 0xE0000 in SPI flash, the RK3399 default, rather
than at 0x80000 as in Kobol's vendor U-Boot. Kobol's instructions start
from microSD, and Armbian, the image Kobol recommended, always wrote the
whole loader to SPI at once. In normal use nobody flashes the U-Boot
stages to SPI separately, so old TPL/SPL never meet a new proper and
nothing depends on 0x80000. Whoever updates the stages one by one by
hand does it on purpose and knows where each goes. There is no reason
for a board-specific offset.

Features tested on a Helios64:
- eMMC boot (TF-A v2.13.0 BL31, open-source TPL), also after watchdog
  resets and power cycles
- SD card boot, also after a watchdog reset or a panic left the card
  at 1.8 V
- SPI flash boot
- GMAC Ethernet (DHCP, TFTP)
- USB 3 host

Not working yet: PCIe, and the RTL8156, which U-Boot has no driver for.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
vdd_log and vdd_center are applied for Linux 7.5:
https://lore.kernel.org/r/20261021-helios64-vdd-log-center-v1-1-4cafd110e0e5@iav.lv
I said I would wait for devicetree-rebasing, but the rest of this patch
does not depend on it. Until the sync the nodes stay in -u-boot.dtsi;
after it a follow-up reduces them to the 950 mV settings. Is that fine,
or should this wait for the sync?
---
Changes in v2:
- Add an R: entry to board/rockchip/evb_rk3399/MAINTAINERS.
- Use the default ENV_OFFSET.
- Drop SPL_ATF_NO_PLATFORM_PARAM (upstream TF-A).
- Keep clock-names in the SPL DTB.
- Drop the USB Ethernet adapters and USB EHCI.
- Enable the IO-domain driver in SPL, for the SD card at 1.8 V (SPL I2C,
  PMIC and regulators; bootph on i2c0_xfer, io_domains, vcc_sdio_s0).
- Keep U-Boot proper at the RK3399 default 0xE0000 in SPI, see the
  commit message.
- Test SD card and SPI flash boot, watchdog resets and power cycles.
- Rebase on main.
- Link to v1: https://lore.kernel.org/r/20261021-b4-helios64-v1-1-74afe8aa6d72@iav.lv
---
 arch/arm/dts/rk3399-kobol-helios64-u-boot.dtsi | 68 ++++++++++++++++++++++
 board/rockchip/evb_rk3399/MAINTAINERS          |  6 ++
 configs/helios64-rk3399_defconfig              | 80 ++++++++++++++++++++++++++
 doc/board/rockchip/rockchip.rst                |  1 +
 4 files changed, 155 insertions(+)

diff --git a/arch/arm/dts/rk3399-kobol-helios64-u-boot.dtsi b/arch/arm/dts/rk3399-kobol-helios64-u-boot.dtsi
new file mode 100644
index 00000000000..89b063af418
--- /dev/null
+++ b/arch/arm/dts/rk3399-kobol-helios64-u-boot.dtsi
@@ -0,0 +1,68 @@
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
+&i2c0_xfer {
+	bootph-pre-ram;
+};
+
+&io_domains {
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
+
+&vcc_sdio_s0 {
+	bootph-pre-ram;
+};
diff --git a/board/rockchip/evb_rk3399/MAINTAINERS b/board/rockchip/evb_rk3399/MAINTAINERS
index 860dd028759..57ed4d43f73 100644
--- a/board/rockchip/evb_rk3399/MAINTAINERS
+++ b/board/rockchip/evb_rk3399/MAINTAINERS
@@ -20,6 +20,12 @@ S:	Maintained
 F:	configs/generic-rk3399_defconfig
 F:	arch/arm/dts/rk3399-generic*
 
+HELIOS64
+R:	Igor Velkov <iav@iav.lv>
+S:	Maintained
+F:	configs/helios64-rk3399_defconfig
+F:	arch/arm/dts/rk3399-kobol-helios64*
+
 KHADAS-EDGE
 M:	Nick Xie <nick@khadas.com>
 S:	Maintained
diff --git a/configs/helios64-rk3399_defconfig b/configs/helios64-rk3399_defconfig
new file mode 100644
index 00000000000..3c70b566e6b
--- /dev/null
+++ b/configs/helios64-rk3399_defconfig
@@ -0,0 +1,80 @@
+CONFIG_ARM=y
+CONFIG_SKIP_LOWLEVEL_INIT=y
+CONFIG_COUNTER_FREQUENCY=24000000
+CONFIG_ARCH_ROCKCHIP=y
+CONFIG_SPL_GPIO=y
+CONFIG_NR_DRAM_BANKS=1
+CONFIG_SF_DEFAULT_SPEED=25000000
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
+CONFIG_SPL_I2C=y
+CONFIG_SPL_POWER=y
+CONFIG_SPL_SPI_LOAD=y
+CONFIG_SYS_SPI_U_BOOT_OFFS=0xE0000
+CONFIG_TPL=y
+CONFIG_CMD_BOOTZ=y
+CONFIG_CMD_GPT=y
+CONFIG_CMD_MMC=y
+CONFIG_CMD_PCI=y
+CONFIG_CMD_POWEROFF=y
+CONFIG_CMD_USB=y
+CONFIG_CMD_TIME=y
+CONFIG_SPL_OF_CONTROL=y
+CONFIG_OF_SPL_REMOVE_PROPS="interrupt-parent assigned-clocks assigned-clock-rates assigned-clock-parents"
+CONFIG_ENV_IS_IN_MMC=y
+CONFIG_ENV_RELOC_GD_ENV_ADDR=y
+CONFIG_SCSI_AHCI=y
+CONFIG_AHCI_PCI=y
+CONFIG_ROCKCHIP_GPIO=y
+CONFIG_SYS_I2C_ROCKCHIP=y
+CONFIG_LED=y
+CONFIG_LED_GPIO=y
+CONFIG_SPL_ROCKCHIP_IODOMAIN=y
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
+CONFIG_SPL_PMIC_RK8XX=y
+CONFIG_SPL_DM_REGULATOR=y
+CONFIG_REGULATOR_PWM=y
+CONFIG_SPL_DM_REGULATOR_FIXED=y
+CONFIG_REGULATOR_RK8XX=y
+CONFIG_SPL_REGULATOR_RK8XX=y
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
+CONFIG_USB_DWC3=y
+CONFIG_USB_DWC3_GENERIC=y
+CONFIG_ERRNO_STR=y
diff --git a/doc/board/rockchip/rockchip.rst b/doc/board/rockchip/rockchip.rst
index e22c2d6c575..8b7a52233f5 100644
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
base-commit: 6487c50b8a40f2668ab98a892b9300ad5c181f38
change-id: 20261021-b4-helios64-71f019de8d7d

Best regards,
-- 
Igor Velkov <iav@iav.lv>

