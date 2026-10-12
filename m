From: =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
Date: Mon, 12 Oct 2026 14:55:43 +0800
Subject: [PATCH 2/2] board: rockchip: Add FriendlyElec NanoPi R28S
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261012-nanopi-r28s-v1-2-042d62597829@proton.me>
References: <20261012-nanopi-r28s-v1-0-042d62597829@proton.me>
In-Reply-To: <20261012-nanopi-r28s-v1-0-042d62597829@proton.me>
To: u-boot@lists.u-boot-project.org
Cc: Kever Yang <kever.yang@rock-chips.com>, 
 Quentin Schulz <u-boot@0leil.net>, Jonas Karlman <jonas@kwiboo.se>, 
 Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4645;
 i=HystericalDragons@proton.me; h=from:subject:message-id;
 bh=h2uOPfV9i4tlc0R4y0H4cVqMfdPL5EaYzrXjaZL/NA0=;
 b=owGbwMvMwCUmepz3XUtTHjvjabUkhqwzLfnr3F7ITe28n8ui9ZV7Y020UM8lxfxXDtLv2lkOt
 C8LPGTYUcrCIMbFICumyCK7qTpSaFX0zCIWqeMwc1iZQIYwcHEKwERCqxgZdvKqFsZdDOoMfZ+5
 stlS5rLn3WOuSmeK3q1e/+G2VKumFcP/mDWrF+o+NedfPaNj5QLuvUxVN6eFZL/8JpZ/6mLy1Ck
 TmQE=
X-Developer-Key: i=HystericalDragons@proton.me; a=openpgp;
 fpr=1DB27B5912AA5B9972041AC715C70DEE84826E07
X-Endpoint-Received: by B4 Relay for HystericalDragons@proton.me/default with auth_id=1004
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FriendlyElec NanoPi R28S is a dual gigabit Ethernet router board
based on the Rockchip RK3528 SoC. It shares most of its design with the
NanoPi Zero2.

Specifications:
- SoC: Rockchip RK3528, quad-core Cortex-A53 @ 2.0 GHz
- RAM: 1 GB LPDDR4
- Storage: microSD slot, optional onboard eMMC
- Ethernet: 1x GbE (GMAC1 + Realtek RTL8211F),
            1x GbE (Realtek RTL8111H over PCIe)
- WiFi: AICSemi AIC8800D80 over SDIO
- USB: 1x USB 2.0 Type-C (power input and OTG)
- UART: USB Type-C debug console (onboard WCH CH340E), 1500000 8N1
- Buttons: user (GPIO), MaskROM (SARADC)

Add support for the board based on the NanoPi Zero2, and enable
CONFIG_BUTTON_GPIO for the user button.

Features tested on NanoPi R28S:
- SD-card boot
- Ethernet

Signed-off-by: 安容 <HystericalDragons@proton.me>
---
 arch/arm/dts/rk3528-nanopi-r28s-u-boot.dtsi |  3 ++
 arch/arm/mach-rockchip/rk3528/MAINTAINERS   |  6 +++
 configs/nanopi-r28s-rk3528_defconfig        | 65 +++++++++++++++++++++++++++++
 doc/board/rockchip/rockchip.rst             |  1 +
 4 files changed, 75 insertions(+)

diff --git a/arch/arm/dts/rk3528-nanopi-r28s-u-boot.dtsi b/arch/arm/dts/rk3528-nanopi-r28s-u-boot.dtsi
new file mode 100644
index 00000000000..151f1872fed
--- /dev/null
+++ b/arch/arm/dts/rk3528-nanopi-r28s-u-boot.dtsi
@@ -0,0 +1,3 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
+
+#include "rk3528-nanopi-u-boot.dtsi"
diff --git a/arch/arm/mach-rockchip/rk3528/MAINTAINERS b/arch/arm/mach-rockchip/rk3528/MAINTAINERS
index d1810fb0528..78e0bfb2701 100644
--- a/arch/arm/mach-rockchip/rk3528/MAINTAINERS
+++ b/arch/arm/mach-rockchip/rk3528/MAINTAINERS
@@ -10,6 +10,12 @@ S:	Maintained
 F:	arch/arm/dts/rk3528-hinlink-h28k*
 F:	configs/hinlink-h28k-rk3528_defconfig
 
+NANOPI-R28S-RK3528
+M:	安容 <HystericalDragons@proton.me>
+S:	Maintained
+F:	arch/arm/dts/rk3528-nanopi-r28s*
+F:	configs/nanopi-r28s-rk3528_defconfig
+
 NANOPI-ZERO2-RK3528
 M:	Jonas Karlman <jonas@kwiboo.se>
 S:	Maintained
diff --git a/configs/nanopi-r28s-rk3528_defconfig b/configs/nanopi-r28s-rk3528_defconfig
new file mode 100644
index 00000000000..f24bf2c65f2
--- /dev/null
+++ b/configs/nanopi-r28s-rk3528_defconfig
@@ -0,0 +1,65 @@
+CONFIG_ARM=y
+CONFIG_SKIP_LOWLEVEL_INIT=y
+CONFIG_COUNTER_FREQUENCY=24000000
+CONFIG_ARCH_ROCKCHIP=y
+CONFIG_DEFAULT_DEVICE_TREE="rockchip/rk3528-nanopi-r28s"
+CONFIG_ROCKCHIP_RK3528=y
+CONFIG_SYS_LOAD_ADDR=0xc00800
+CONFIG_DEBUG_UART_BASE=0xFF9F0000
+CONFIG_DEBUG_UART_CLOCK=24000000
+CONFIG_DEBUG_UART=y
+CONFIG_DEFAULT_FDT_FILE="rockchip/rk3528-nanopi-r28s.dtb"
+# CONFIG_DISPLAY_CPUINFO is not set
+CONFIG_BOARD_RNG_SEED=y
+CONFIG_SPL_MAX_SIZE=0x40000
+# CONFIG_SPL_RAW_IMAGE_SUPPORT is not set
+CONFIG_CMD_MEMINFO=y
+CONFIG_CMD_MEMINFO_MAP=y
+CONFIG_CMD_ADC=y
+CONFIG_CMD_GPIO=y
+CONFIG_CMD_GPT=y
+CONFIG_CMD_MISC=y
+CONFIG_CMD_MMC=y
+CONFIG_CMD_USB=y
+CONFIG_CMD_ROCKUSB=y
+CONFIG_CMD_USB_MASS_STORAGE=y
+# CONFIG_CMD_SETEXPR is not set
+CONFIG_CMD_RNG=y
+CONFIG_CMD_REGULATOR=y
+# CONFIG_SPL_DOS_PARTITION is not set
+CONFIG_OF_SPL_REMOVE_PROPS="clock-names interrupt-parent assigned-clocks assigned-clock-rates assigned-clock-parents"
+CONFIG_BUTTON=y
+CONFIG_BUTTON_ADC=y
+CONFIG_BUTTON_GPIO=y
+# CONFIG_USB_FUNCTION_FASTBOOT is not set
+CONFIG_ROCKCHIP_GPIO=y
+CONFIG_LED=y
+CONFIG_LED_GPIO=y
+CONFIG_SUPPORT_EMMC_RPMB=y
+CONFIG_MMC_DW=y
+CONFIG_MMC_DW_ROCKCHIP=y
+CONFIG_MMC_SDHCI=y
+CONFIG_MMC_SDHCI_SDMA=y
+CONFIG_MMC_SDHCI_ROCKCHIP=y
+CONFIG_DM_MDIO=y
+CONFIG_DWC_ETH_QOS=y
+CONFIG_DWC_ETH_QOS_ROCKCHIP=y
+CONFIG_PHY_REALTEK=y
+CONFIG_PHY_ROCKCHIP_INNO_USB2=y
+CONFIG_PHY_ROCKCHIP_NANENG_COMBOPHY=y
+CONFIG_REGULATOR_PWM=y
+CONFIG_DM_REGULATOR_GPIO=y
+CONFIG_PWM_ROCKCHIP=y
+CONFIG_BAUDRATE=1500000
+CONFIG_DEBUG_UART_SHIFT=2
+CONFIG_SYS_NS16550_MEM32=y
+CONFIG_USB=y
+CONFIG_USB_XHCI_HCD=y
+CONFIG_USB_EHCI_HCD=y
+CONFIG_USB_EHCI_GENERIC=y
+CONFIG_USB_DWC3=y
+CONFIG_USB_DWC3_GENERIC=y
+CONFIG_USB_GADGET=y
+CONFIG_USB_GADGET_DOWNLOAD=y
+CONFIG_USB_FUNCTION_ROCKUSB=y
+CONFIG_ERRNO_STR=y
diff --git a/doc/board/rockchip/rockchip.rst b/doc/board/rockchip/rockchip.rst
index 1f4e58c8be2..faca4fc425a 100644
--- a/doc/board/rockchip/rockchip.rst
+++ b/doc/board/rockchip/rockchip.rst
@@ -103,6 +103,7 @@ List of mainline supported Rockchip boards:
 
 * rk3528
      - ArmSoM Sige1 (sige1-rk3528)
+     - FriendlyElec NanoPi R28S (nanopi-r28s-rk3528)
      - FriendlyElec NanoPi Zero2 (nanopi-zero2-rk3528)
      - Generic RK3528 (generic-rk3528)
      - HINLINK H28K (hinlink-h28k-rk3528)

-- 
2.56.0

