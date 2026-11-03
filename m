From: Igor Velkov <iav@iav.lv>
Date: Tue, 03 Nov 2026 06:05:59 +0000
Subject: [PATCH] rockchip: rk3399-rock-pi-4: Enable IO-domain driver in SPL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-b4-rock-pi-4-spl-iodomain-v1-1-8dfc34a5e2e2@iav.lv>
X-B4-Tracking: v=1; b=H4sIAMZ56WoC/x3MQQqAIBBA0avErBtQsxZdJVqYjjVUKgoRRHdPW
 r7F/w8UykwFxuaBTBcXjqFCtg3YzYSVkF01KKEGKUWHi8Yc7Y6JUWNJB3J08TQc0A+qE167noy
 F2qdMnu//Pc3v+wF17EVMawAAAA==
To: Jagan Teki <jagan@amarulasolutions.com>, 
 Kever Yang <kever.yang@rock-chips.com>, Quentin Schulz <u-boot@0leil.net>, 
 Christopher Obbard <chris.obbard@oss.qualcomm.com>, 
 Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>
Cc: Jonas Karlman <jonas@kwiboo.se>, Simon Glass <sjg@chromium.org>, 
 u-boot@lists.u-boot-project.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=6346; i=iav@iav.lv;
 h=from:subject:message-id; bh=NUk8Wk4P7MMJBvKKkJJQbczvVwvQytZgIODuS5gkBrA=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkvK49/fvV3BnOmRmXq86OF83UsnjDlt9Tp/VF2zFeqY
 tPoSVrWUcrCIMbFICumyDLhkMatjCVX//p7mD+AmcPKBDKEgYtTACZSVM3IcDk49cDGwDr1sw/D
 bDat38icNjmuV6bp8YbC3y2uW3pmsjMy3PlXMf+JzzfOGw36SULcDHXXuMVbUre+6faNvPhwo4M
 ZHwA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With the SD card in a UHS-I mode, vcc_sdio (RK808 LDO4) stays at 1.8 V
across a warm reset such as a watchdog reset or a panic: the PMIC is
not reset, and the card supply on ROCK Pi 4 is not switchable. The SD
I/O domain resets to 3.3 V, and SPL fails to load U-Boot from the card:

  mmc_load_image_raw_sector: mmc block read error

Enable the RK8XX regulator and Rockchip IO-domain drivers in SPL, and
drop regulator-always-on and regulator-boot-on from vcc_sdio, as these
commits do for the NanoPi 4 boards:

  commit 2abd7fff9ebf ("rockchip: rk3399-nanopi-4: Allow MMC driver to control SD regulators")
  commit 210ab4f60df8 ("rockchip: rk3399-nanopi-4: Enable IO-domain driver in SPL")

Without the boot-on flag U-Boot leaves vcc_sdio at its current voltage,
and the I/O-domain driver sets the I/O domain to match it.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on ROCK Pi 4A booting U-Boot from SD, with Linux running the
card in SDR104: sysrq-b 4/4, panic 2/2 and watchdog reset 2/2 boot,
where SPL without this change stops at "mmc block read error". With
the card left at 3.0 V (non-UHS DT) cold boot, reboot, sysrq-b and
watchdog reset still boot in high-speed mode. Not tested on ROCK Pi 4C
and ROCK 4SE, whose defconfigs and dtsi are changed the same way.
---
 arch/arm/dts/rk3399-rock-pi-4-u-boot.dtsi | 14 ++++++++++++++
 configs/rock-4se-rk3399_defconfig         |  7 +++++++
 configs/rock-pi-4-rk3399_defconfig        |  7 +++++++
 configs/rock-pi-4c-rk3399_defconfig       |  7 +++++++
 4 files changed, 35 insertions(+)

diff --git a/arch/arm/dts/rk3399-rock-pi-4-u-boot.dtsi b/arch/arm/dts/rk3399-rock-pi-4-u-boot.dtsi
index 4861574636e..7a15f613c99 100644
--- a/arch/arm/dts/rk3399-rock-pi-4-u-boot.dtsi
+++ b/arch/arm/dts/rk3399-rock-pi-4-u-boot.dtsi
@@ -14,12 +14,26 @@
 	};
 };
 
+&i2c0_xfer {
+	bootph-pre-ram;
+};
+
+&io_domains {
+	bootph-pre-ram;
+};
+
 &sdhci {
 	cap-mmc-highspeed;
 	mmc-ddr-1_8v;
 	mmc-hs200-1_8v;
 };
 
+&vcc_sdio {
+	bootph-pre-ram;
+	/delete-property/ regulator-always-on;
+	/delete-property/ regulator-boot-on;
+};
+
 &vdd_log {
 	regulator-init-microvolt = <950000>;
 };
diff --git a/configs/rock-4se-rk3399_defconfig b/configs/rock-4se-rk3399_defconfig
index 7f22aede912..dfec68ac4c0 100644
--- a/configs/rock-4se-rk3399_defconfig
+++ b/configs/rock-4se-rk3399_defconfig
@@ -9,6 +9,7 @@ CONFIG_DEFAULT_DEVICE_TREE="rockchip/rk3399-rock-4se"
 CONFIG_DM_RESET=y
 CONFIG_ROCKCHIP_RK3399=y
 CONFIG_ROCKCHIP_SPI_IMAGE=y
+CONFIG_SPL_DRIVERS_MISC=y
 CONFIG_TARGET_ROCKPI4_RK3399=y
 CONFIG_SYS_LOAD_ADDR=0x800800
 CONFIG_SF_DEFAULT_BUS=1
@@ -25,6 +26,8 @@ CONFIG_DEFAULT_FDT_FILE="rockchip/rk3399-rock-4se.dtb"
 CONFIG_DISPLAY_BOARDINFO_LATE=y
 CONFIG_SPL_MAX_SIZE=0x40000
 # CONFIG_SPL_RAW_IMAGE_SUPPORT is not set
+CONFIG_SPL_I2C=y
+CONFIG_SPL_POWER=y
 CONFIG_SPL_SPI_LOAD=y
 CONFIG_SYS_SPI_U_BOOT_OFFS=0xE0000
 CONFIG_TPL=y
@@ -52,6 +55,7 @@ CONFIG_ROCKCHIP_GPIO=y
 CONFIG_SYS_I2C_ROCKCHIP=y
 CONFIG_LED=y
 CONFIG_LED_GPIO=y
+CONFIG_SPL_ROCKCHIP_IODOMAIN=y
 CONFIG_MMC_DW=y
 CONFIG_MMC_DW_ROCKCHIP=y
 CONFIG_MMC_SDHCI=y
@@ -70,8 +74,11 @@ CONFIG_NVME_PCI=y
 CONFIG_PHY_ROCKCHIP_INNO_USB2=y
 CONFIG_PHY_ROCKCHIP_TYPEC=y
 CONFIG_PMIC_RK8XX=y
+CONFIG_SPL_PMIC_RK8XX=y
+CONFIG_SPL_DM_REGULATOR=y
 CONFIG_REGULATOR_PWM=y
 CONFIG_REGULATOR_RK8XX=y
+CONFIG_SPL_REGULATOR_RK8XX=y
 CONFIG_PWM_ROCKCHIP=y
 CONFIG_RAM_ROCKCHIP_LPDDR4=y
 CONFIG_SCSI=y
diff --git a/configs/rock-pi-4-rk3399_defconfig b/configs/rock-pi-4-rk3399_defconfig
index e5c9072c27f..fe120db9b8c 100644
--- a/configs/rock-pi-4-rk3399_defconfig
+++ b/configs/rock-pi-4-rk3399_defconfig
@@ -9,6 +9,7 @@ CONFIG_DEFAULT_DEVICE_TREE="rockchip/rk3399-rock-pi-4a"
 CONFIG_DM_RESET=y
 CONFIG_ROCKCHIP_RK3399=y
 CONFIG_ROCKCHIP_SPI_IMAGE=y
+CONFIG_SPL_DRIVERS_MISC=y
 CONFIG_TARGET_ROCKPI4_RK3399=y
 CONFIG_SYS_LOAD_ADDR=0x800800
 CONFIG_SF_DEFAULT_BUS=1
@@ -25,6 +26,8 @@ CONFIG_DEFAULT_FDT_FILE="rockchip/rk3399-rock-pi-4a.dtb"
 CONFIG_DISPLAY_BOARDINFO_LATE=y
 CONFIG_SPL_MAX_SIZE=0x40000
 # CONFIG_SPL_RAW_IMAGE_SUPPORT is not set
+CONFIG_SPL_I2C=y
+CONFIG_SPL_POWER=y
 CONFIG_SPL_SPI_LOAD=y
 CONFIG_SYS_SPI_U_BOOT_OFFS=0xE0000
 CONFIG_SPL_ATF_NO_PLATFORM_PARAM=y
@@ -53,6 +56,7 @@ CONFIG_ROCKCHIP_GPIO=y
 CONFIG_SYS_I2C_ROCKCHIP=y
 CONFIG_LED=y
 CONFIG_LED_GPIO=y
+CONFIG_SPL_ROCKCHIP_IODOMAIN=y
 CONFIG_MMC_DW=y
 CONFIG_MMC_DW_ROCKCHIP=y
 CONFIG_MMC_SDHCI=y
@@ -71,8 +75,11 @@ CONFIG_NVME_PCI=y
 CONFIG_PHY_ROCKCHIP_INNO_USB2=y
 CONFIG_PHY_ROCKCHIP_TYPEC=y
 CONFIG_PMIC_RK8XX=y
+CONFIG_SPL_PMIC_RK8XX=y
+CONFIG_SPL_DM_REGULATOR=y
 CONFIG_REGULATOR_PWM=y
 CONFIG_REGULATOR_RK8XX=y
+CONFIG_SPL_REGULATOR_RK8XX=y
 CONFIG_PWM_ROCKCHIP=y
 CONFIG_RAM_ROCKCHIP_LPDDR4=y
 CONFIG_SCSI=y
diff --git a/configs/rock-pi-4c-rk3399_defconfig b/configs/rock-pi-4c-rk3399_defconfig
index 4be7b0f8130..1a37190d077 100644
--- a/configs/rock-pi-4c-rk3399_defconfig
+++ b/configs/rock-pi-4c-rk3399_defconfig
@@ -9,6 +9,7 @@ CONFIG_DEFAULT_DEVICE_TREE="rockchip/rk3399-rock-pi-4c"
 CONFIG_DM_RESET=y
 CONFIG_ROCKCHIP_RK3399=y
 CONFIG_ROCKCHIP_SPI_IMAGE=y
+CONFIG_SPL_DRIVERS_MISC=y
 CONFIG_TARGET_ROCKPI4_RK3399=y
 CONFIG_SYS_LOAD_ADDR=0x800800
 CONFIG_SF_DEFAULT_BUS=1
@@ -25,6 +26,8 @@ CONFIG_DEFAULT_FDT_FILE="rockchip/rk3399-rock-pi-4c.dtb"
 CONFIG_DISPLAY_BOARDINFO_LATE=y
 CONFIG_SPL_MAX_SIZE=0x40000
 # CONFIG_SPL_RAW_IMAGE_SUPPORT is not set
+CONFIG_SPL_I2C=y
+CONFIG_SPL_POWER=y
 CONFIG_SPL_SPI_LOAD=y
 CONFIG_SYS_SPI_U_BOOT_OFFS=0xE0000
 CONFIG_SPL_ATF_NO_PLATFORM_PARAM=y
@@ -53,6 +56,7 @@ CONFIG_ROCKCHIP_GPIO=y
 CONFIG_SYS_I2C_ROCKCHIP=y
 CONFIG_LED=y
 CONFIG_LED_GPIO=y
+CONFIG_SPL_ROCKCHIP_IODOMAIN=y
 CONFIG_MMC_DW=y
 CONFIG_MMC_DW_ROCKCHIP=y
 CONFIG_MMC_SDHCI=y
@@ -71,8 +75,11 @@ CONFIG_NVME_PCI=y
 CONFIG_PHY_ROCKCHIP_INNO_USB2=y
 CONFIG_PHY_ROCKCHIP_TYPEC=y
 CONFIG_PMIC_RK8XX=y
+CONFIG_SPL_PMIC_RK8XX=y
+CONFIG_SPL_DM_REGULATOR=y
 CONFIG_REGULATOR_PWM=y
 CONFIG_REGULATOR_RK8XX=y
+CONFIG_SPL_REGULATOR_RK8XX=y
 CONFIG_PWM_ROCKCHIP=y
 CONFIG_RAM_ROCKCHIP_LPDDR4=y
 CONFIG_SCSI=y

---
base-commit: ab4dc5aacf957835c295b59ef2dd28281839cb20
change-id: 20261103-b4-rock-pi-4-spl-iodomain-f6230f4d5eac

Best regards,
-- 
Igor Velkov <iav@iav.lv>

