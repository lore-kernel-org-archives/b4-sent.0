From: Valerio Setti <vsetti@baylibre.com>
Date: Mon, 08 Sep 2025 21:50:03 +0200
Subject: [PATCH v2] arm64: dts: amlogic: gxbb-odroidc2: remove UHS
 capability for SD card
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250908-fix-reboot-v2-1-354d0e57c855@baylibre.com>
X-B4-Tracking: v=1; b=H4sIAGozv2gC/23MTQqDMBCG4avIrDtlEvwhXfUe4iKmYx1oTUkkV
 CR3b3Td5TvD9+wQOQhHuFU7BE4SxS8l9KUCN9vlySiP0qBJN2Sow0m+GHj0fkWqmSZnlLFMUAa
 fwOV7Yv1Qepa4+rCddlLH9S+TFCrsWmoPSzc130e7vWQMfHX+DUPO+QcGgIQ9pwAAAA==
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2045; i=vsetti@baylibre.com;
 h=from:subject:message-id; bh=BJc4SXxGYBhMfaPaAFk61MykLFrvMDIrqRdHH0rt9IY=;
 b=owGbwMvMwCF2z3ty7kUrRgbG02pJDBn7jRuDXn3+sOHcgT2cDKu9ThrvSJgZ9VuAP9956mm9K
 rNPfIqNHaUsDGIcDLJiiiws0+/9LihVe2iccLIAZg4rE8gQBi5OAZiIdhUjQ8eu7/dYbVV89FJ8
 JDoFqtsmSq7tVWzIrV2loFGjF6IjzvDfZ97m1ZYLFvRJ2yT5vAq8z7zmp3f339s5Zzv4zBP3y/5
 jAQA=
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

Therefore this commit removes all UHS modes which would cause
"vqmmc-summply" to switch from 3.3V to 1.8V.

In terms of performance the main drawback of this commit is limiting the
SD card bus speed to HS (25 MB/s) instead of UHS DDR50 (50 MB/s). However
this comes with the benefit of being able to reboot the board, so it
sounds like a reasonable compromise.

Reviewed-by: Jerome Brunet <jbrunet@baylibre.com>
Signed-off-by: Valerio Setti <vsetti@baylibre.com>
---
Changes in v2:
- Re-added vqmmc-supply to sd_emmc_b node.
- Link to v1: https://lore.kernel.org/r/20250907-fix-reboot-v1-1-7606fc91254e@baylibre.com
---
 arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts | 4 ----
 1 file changed, 4 deletions(-)

diff --git a/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts b/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts
index 959bd8d77a82ebc78c5e0592d7613e692e4ede4e..12e26f99d4f080a216e305981dc4291a49063b60 100644
--- a/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts
+++ b/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts
@@ -348,10 +348,6 @@ &sd_emmc_b {
 
 	bus-width = <4>;
 	cap-sd-highspeed;
-	sd-uhs-sdr12;
-	sd-uhs-sdr25;
-	sd-uhs-sdr50;
-	sd-uhs-ddr50;
 	max-frequency = <100000000>;
 	disable-wp;
 

---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250907-fix-reboot-04e0fc919ae0

Best regards,
-- 
Valerio Setti <vsetti@baylibre.com>

