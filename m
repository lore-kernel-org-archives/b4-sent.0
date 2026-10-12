From: =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
Date: Mon, 12 Oct 2026 21:22:18 +0800
Subject: [PATCH v2 3/3] board: rockchip: Add FriendlyElec NanoPi R28S
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261012-nanopi-r28s-v2-3-3d162759dd3d@proton.me>
References: <20261012-nanopi-r28s-v2-0-3d162759dd3d@proton.me>
In-Reply-To: <20261012-nanopi-r28s-v2-0-3d162759dd3d@proton.me>
To: u-boot@lists.u-boot-project.org
Cc: Kever Yang <kever.yang@rock-chips.com>, 
 Quentin Schulz <u-boot@0leil.net>, Jonas Karlman <jonas@kwiboo.se>, 
 Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4596;
 i=HystericalDragons@proton.me; h=from:subject:message-id;
 bh=TJybbvr0PctsDCGzRg8/U7Rw4E7ysvYnyze25HOPRPI=;
 b=owGbwMvMwCUmepz3XUtTHjvjabUkhqwz9znX6J8Is+M7tC+/M6rp9Ez5TsUjvTrsFnpf50fVS
 8Z2zIzsKGVhEONikBVTZJHdVB0ptCp6ZhGL1HGYOaxMIEMYuDgFYCLZaxj+Cun+V/o7Ze7krmSv
 J9fWXe9YGXY+5W91ipvaI65VMSIf7Bj+12WFzCvds/ZDROwT+VtljpznfHNX7z0fM+HKNrGPLLq
 fuQA=
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

Add the board to the NanoPi RK3528 board target, which selects the
R28S FDT based on its HW_ID, and enable CONFIG_BUTTON_GPIO for the user
button.

Features tested on NanoPi R28S:
- SD-card boot
- Ethernet

Signed-off-by: 安容 <HystericalDragons@proton.me>
---
 arch/arm/dts/rk3528-nanopi-r28s-u-boot.dtsi      | 3 +++
 arch/arm/mach-rockchip/rk3528/Kconfig            | 5 +++--
 board/friendlyelec/nanopi-rk3528/MAINTAINERS     | 6 ++++++
 board/friendlyelec/nanopi-rk3528/nanopi-rk3528.c | 1 +
 configs/nanopi-zero2-rk3528_defconfig            | 2 ++
 doc/board/rockchip/rockchip.rst                  | 2 +-
 6 files changed, 16 insertions(+), 3 deletions(-)

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
index 67f14661087..6665e35309a 100644
--- a/board/friendlyelec/nanopi-rk3528/MAINTAINERS
+++ b/board/friendlyelec/nanopi-rk3528/MAINTAINERS
@@ -5,3 +5,9 @@ F:	board/friendlyelec/nanopi-rk3528
 F:	arch/arm/dts/rk3528-nanopi-u-boot.dtsi
 F:	arch/arm/dts/rk3528-nanopi-zero2*
 F:	configs/nanopi-zero2-rk3528_defconfig
+
+NANOPI-R28S-RK3528
+M:	安容 <HystericalDragons@proton.me>
+R:	Jonas Karlman <jonas@kwiboo.se>
+S:	Maintained
+F:	arch/arm/dts/rk3528-nanopi-r28s*
diff --git a/board/friendlyelec/nanopi-rk3528/nanopi-rk3528.c b/board/friendlyelec/nanopi-rk3528/nanopi-rk3528.c
index 5719eba9a89..001a047650f 100644
--- a/board/friendlyelec/nanopi-rk3528/nanopi-rk3528.c
+++ b/board/friendlyelec/nanopi-rk3528/nanopi-rk3528.c
@@ -15,6 +15,7 @@ struct board_model {
 
 static const struct board_model board_models[] = {
 	{ 102, 144, "rockchip/rk3528-nanopi-zero2.dtb" },
+	{ 223, 265, "rockchip/rk3528-nanopi-r28s.dtb" },
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
index 1f4e58c8be2..c454d417444 100644
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

