From: =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
Date: Tue, 03 Nov 2026 18:37:11 +0800
Subject: [PATCH v3 6/6] board: rockchip: Add FriendlyElec NanoPi R28S
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261103-nanopi-r28s-v3-6-ae8664fd168f@proton.me>
References: <20261103-nanopi-r28s-v3-0-ae8664fd168f@proton.me>
In-Reply-To: <20261103-nanopi-r28s-v3-0-ae8664fd168f@proton.me>
To: u-boot@lists.u-boot-project.org
Cc: Kever Yang <kever.yang@rock-chips.com>, 
 Quentin Schulz <u-boot@0leil.net>, Jonas Karlman <jonas@kwiboo.se>, 
 Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>, 
 Quentin Schulz <quentin.schulz@cherry.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4705;
 i=HystericalDragons@proton.me; s=20261103; h=from:subject:message-id;
 bh=Lvd/g+bpF8LTLWdIkvzptn7vN0IScMw4IvfOk3iqv1U=;
 b=owGbwMvMwCU8Ldb53x4TtgLG02pJDFkvdwZHMhfqr0txq/o2l7X+AYNwvfDB5lPWt5y57U0+3
 q+9rLiwYwcLgzAXg6yYIkun9OeJXx5fmP715qQsmDmsTCBDGLg4BWAiikxM7K6KL/N2N/cf7/h1
 i0N38jGFx91y01POP3YPDHDRUJzy7toaLYdo+5pfCYkmolu9lpYlJ0ea/F1deOHmo07HjRM3Mx/
 OYuJkbIrhEL594kPOnsndk8Kelfuppb0t3vfqUd7ySRdD0zcbnNCadvHehff1MltVfAo3SqwKzV
 wz0XvnAf2sG2XzPprKXttaDQA=
X-Developer-Key: i=HystericalDragons@proton.me; a=openpgp;
 fpr=5A3AC293DCEEAA41A8A3266A910205A0AEB09D84
X-Endpoint-Received: by B4 Relay for HystericalDragons@proton.me/20261103 with auth_id=1393
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

Add the board to the NanoPi RK3528 board target, which selects the
R28S FDT based on its HW_ID, and enable CONFIG_BUTTON_GPIO for the user
button.

Features tested on NanoPi R28S:
- SD-card boot
- Ethernet

Signed-off-by: 安容 <HystericalDragons@proton.me>
Reviewed-by: Quentin Schulz <quentin.schulz@cherry.de>
---
 arch/arm/dts/rk3528-nanopi-r28s-u-boot.dtsi      | 3 +++
 arch/arm/mach-rockchip/rk3528/Kconfig            | 5 +++--
 board/friendlyelec/nanopi-rk3528/MAINTAINERS     | 2 ++
 board/friendlyelec/nanopi-rk3528/nanopi-rk3528.c | 1 +
 configs/nanopi-zero2-rk3528_defconfig            | 2 ++
 doc/board/rockchip/rockchip.rst                  | 2 +-
 6 files changed, 12 insertions(+), 3 deletions(-)

diff --git a/arch/arm/dts/rk3528-nanopi-r28s-u-boot.dtsi b/arch/arm/dts/rk3528-nanopi-r28s-u-boot.dtsi
new file mode 100644
index 00000000000..151f1872fed
--- /dev/null
+++ b/arch/arm/dts/rk3528-nanopi-r28s-u-boot.dtsi
@@ -0,0 +1,3 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
+
+#include "rk3528-nanopi-u-boot.dtsi"
diff --git a/arch/arm/mach-rockchip/rk3528/Kconfig b/arch/arm/mach-rockchip/rk3528/Kconfig
index 87b65d666e9..6e934408e56 100644
--- a/arch/arm/mach-rockchip/rk3528/Kconfig
+++ b/arch/arm/mach-rockchip/rk3528/Kconfig
@@ -1,9 +1,10 @@
 if ROCKCHIP_RK3528
 
 config TARGET_NANOPI_RK3528
-	bool "FriendlyElec NanoPi Zero2"
+	bool "FriendlyElec NanoPi R28S/Zero2"
 	help
-	  FriendlyElec NanoPi Zero2 single board computer with a RK3528A SoC.
+	  FriendlyElec NanoPi R28S/Zero2 single board computers with a RK3528A
+	  SoC.
 
 config TARGET_RADXA_ROCK_2_RK3528
 	bool "Radxa ROCK 2A/2F"
diff --git a/board/friendlyelec/nanopi-rk3528/MAINTAINERS b/board/friendlyelec/nanopi-rk3528/MAINTAINERS
index 67f14661087..c2e3bbba6d7 100644
--- a/board/friendlyelec/nanopi-rk3528/MAINTAINERS
+++ b/board/friendlyelec/nanopi-rk3528/MAINTAINERS
@@ -1,7 +1,9 @@
 NANOPI-RK3528
 M:	Jonas Karlman <jonas@kwiboo.se>
+M:	安容 <HystericalDragons@proton.me>
 S:	Maintained
 F:	board/friendlyelec/nanopi-rk3528
 F:	arch/arm/dts/rk3528-nanopi-u-boot.dtsi
+F:	arch/arm/dts/rk3528-nanopi-r28s*
 F:	arch/arm/dts/rk3528-nanopi-zero2*
 F:	configs/nanopi-zero2-rk3528_defconfig
diff --git a/board/friendlyelec/nanopi-rk3528/nanopi-rk3528.c b/board/friendlyelec/nanopi-rk3528/nanopi-rk3528.c
index 86932eab7c7..c7f2ebe32fa 100644
--- a/board/friendlyelec/nanopi-rk3528/nanopi-rk3528.c
+++ b/board/friendlyelec/nanopi-rk3528/nanopi-rk3528.c
@@ -16,6 +16,7 @@ struct board_model {
 /* HW_ID buckets from the FriendlyElec vendor U-Boot hwrev.c */
 static const struct board_model board_models[] = {
 	{  82, 150, "rockchip/rk3528-nanopi-zero2.dtb" },
+	{ 212, 274, "rockchip/rk3528-nanopi-r28s.dtb" },
 };
 
 static const struct board_model *get_board_model(void)
diff --git a/configs/nanopi-zero2-rk3528_defconfig b/configs/nanopi-zero2-rk3528_defconfig
index dde9134112f..0af811d0ea2 100644
--- a/configs/nanopi-zero2-rk3528_defconfig
+++ b/configs/nanopi-zero2-rk3528_defconfig
@@ -28,9 +28,11 @@ CONFIG_CMD_USB_MASS_STORAGE=y
 CONFIG_CMD_RNG=y
 CONFIG_CMD_REGULATOR=y
 # CONFIG_SPL_DOS_PARTITION is not set
+CONFIG_OF_LIST="rockchip/rk3528-nanopi-zero2 rockchip/rk3528-nanopi-r28s"
 CONFIG_OF_SPL_REMOVE_PROPS="clock-names interrupt-parent assigned-clocks assigned-clock-rates assigned-clock-parents"
 CONFIG_BUTTON=y
 CONFIG_BUTTON_ADC=y
+CONFIG_BUTTON_GPIO=y
 # CONFIG_USB_FUNCTION_FASTBOOT is not set
 CONFIG_ROCKCHIP_GPIO=y
 CONFIG_LED=y
diff --git a/doc/board/rockchip/rockchip.rst b/doc/board/rockchip/rockchip.rst
index e22c2d6c575..bf02b700b0d 100644
--- a/doc/board/rockchip/rockchip.rst
+++ b/doc/board/rockchip/rockchip.rst
@@ -103,7 +103,7 @@ List of mainline supported Rockchip boards:
 
 * rk3528
      - ArmSoM Sige1 (sige1-rk3528)
-     - FriendlyElec NanoPi Zero2 (nanopi-zero2-rk3528)
+     - FriendlyElec NanoPi R28S/Zero2 (nanopi-zero2-rk3528)
      - Generic RK3528 (generic-rk3528)
      - HINLINK H28K (hinlink-h28k-rk3528)
      - Radxa E20C (radxa-e20c-rk3528)

-- 
2.56.0

