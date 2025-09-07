From: Valerio Setti <vsetti@baylibre.com>
Date: Sun, 07 Sep 2025 14:29:21 +0200
Subject: [PATCH] arm64: dts: amlogic: gxbb-odroidc2: remove UHS capability
 for SD card
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250907-fix-reboot-v1-1-7606fc91254e@baylibre.com>
X-B4-Tracking: v=1; b=H4sIAKB6vWgC/x2MQQqAIBAAvyJ7bmGVIuwr0cFsrb1oaEQg/T3pO
 AwzFQpn4QKTqpD5liIpNtCdAn+4uDPK1hgMmYEsjRjkwcxrShdSzxS81dYxQQvOzM3+s3l53w+
 6d6OLXAAAAA==
X-Change-ID: 20250907-fix-reboot-04e0fc919ae0
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Valerio Setti <vsetti@baylibre.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2226; i=vsetti@baylibre.com;
 h=from:subject:message-id; bh=8EBu8xBycRGsUBCELcsXSIlLy471WBn+C9oMzb171Ho=;
 b=owGbwMvMwCF2z3ty7kUrRgbG02pJDBl7qzZ+EotTzK5mWfxPQoD3/DQxnkX1aVs1a1Z1aVvlx
 HUkbd7ZUcrCIMbBICumyMIy/d7vglK1h8YJJwtg5rAygQxh4OIUgIkcFWD4X21T+C1i+zvvZQeO
 e5zqsmt76n9o+7IXy1Z+TO1bva5APYbhD4dH72EDe83XX45zHOD27/+wJdz7NJfMPtPW+jXLO05
 vYgIA
X-Developer-Key: i=vsetti@baylibre.com; a=openpgp;
 fpr=0497DEFB707526E13360C970DE4B936DD13A0100
X-Endpoint-Received: by B4 Relay for vsetti@baylibre.com/default with auth_id=515
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is meant to resolve reboot not working on this board.

The problem is as follows. In order to be able to switch from HS to UHS
mode the bus voltage needs to be reduced from 3.3V down to 1.8V and this
is achieved by the "vqmmc-supply" regulator. The ROM bootloader is only
able to manage the card in HS mode (3.3V) and the switch HS->UHS happen
at boottime in the kernel. The problem appears when the reboot command
is issued or watchdog expires because in this case the "vqmmc-supply"
voltage is not returned back at 3.3V before rebooting the board so the
ROM bootloader will be completely stuck.

Therefore this commit removes both "vqmmc-supply" property, which is the
one causing the reboot problem, as well as all the UHS modes which would
now became unreachable due to this regulator control removal.

In terms of performance the main drawback of this commit is limiting the
SD card bus speed to HS (25 MB/s) instead of UHS DDR50 (50 MB/s). However
this comes with the benefit of being able to reboot the board, so it
sounds like a reasonable compromise.

Signed-off-by: Valerio Setti <vsetti@baylibre.com>
---
 arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts | 9 ++++-----
 1 file changed, 4 insertions(+), 5 deletions(-)

diff --git a/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts b/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts
index 959bd8d77a82ebc78c5e0592d7613e692e4ede4e..331a0a62b884389b4e0d4d157fff7f9c8738c89d 100644
--- a/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts
+++ b/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts
@@ -348,17 +348,16 @@ &sd_emmc_b {
 
 	bus-width = <4>;
 	cap-sd-highspeed;
-	sd-uhs-sdr12;
-	sd-uhs-sdr25;
-	sd-uhs-sdr50;
-	sd-uhs-ddr50;
 	max-frequency = <100000000>;
 	disable-wp;
 
 	cd-gpios = <&gpio CARD_6 GPIO_ACTIVE_LOW>;
 
 	vmmc-supply = <&tflash_vdd>;
-	vqmmc-supply = <&tf_io>;
+	/*
+	 * Control of vqmmc-supply is intentionally omitted because it would
+	 * prevent the board from rebooting properly.
+	 */
 };
 
 /* eMMC */

---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250907-fix-reboot-04e0fc919ae0

Best regards,
-- 
Valerio Setti <vsetti@baylibre.com>

