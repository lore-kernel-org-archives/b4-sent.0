From: Igor Velkov <iav@iav.lv>
Date: Wed, 30 Sep 2026 16:52:14 +0000
Subject: [PATCH 1/2] arm64: dts: amlogic: meson-sm1-odroid-hc4: mux the SPI
 NOR HOLD# and WP# pins
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-hc4-spi-nor-v1-1-9a3351e2984e@iav.lv>
References: <20260930-hc4-spi-nor-v1-0-9a3351e2984e@iav.lv>
In-Reply-To: <20260930-hc4-spi-nor-v1-0-9a3351e2984e@iav.lv>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Christian Hewitt <christianshewitt@gmail.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1637; i=iav@iav.lv;
 h=from:subject:message-id; bh=R8D2qAhBJWwSqWsnhy/mUQEbfBkFgY23nk2VBBtCEbk=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFl77RzlVLe+vHiscK+Rk1yE9gP+iQYOUqbny5YlnD5o9
 jFMRfFjRykLgxgXg6yYIsuEQxq3MpZc/evvYf4AZg4rE8gQBi5OAZhIWAbD/4pal4TPmxTyn1ny
 y6+Tblzzz7wkz7LAbeaEmksffY+4HmFkWCMocDpq1dE91UYaEat/ShZXGIm9vPTSVXaaofcZxj8
 zOAA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SPI NOR flash uses six lines, but nor_pins covers only four: data,
clock and chip select. Nothing claims HOLD# (BOOT_3) and WP# (BOOT_7),
so they keep the boot ROM setting. After a boot from SPI they are in
the nor function and the flash works. After a boot from SD with the
button under the board, they stay eMMC data lines pulled low, and
spi-nor reports "unrecognized JEDEC id bytes: 00 00 00 00 00 00".

Mux them in a board-local group. nor_pins is shared with boards that
use BOOT_0..7 for eMMC, and the HC4 has eMMC disabled.

Tested on ODROID-HC4: after a boot from SD past the SPI, the flash
probes as a 16 MiB mtd0 and reads back correctly.

Fixes: 7178f340e929 ("arm64: dts: meson-sm1-odroid-hc4: add spifc node to ODROID-HC4")
Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts | 12 +++++++++++-
 1 file changed, 11 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts b/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts
index 3ece30a0a1ff..5ce76a1bfe02 100644
--- a/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts
+++ b/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts
@@ -124,9 +124,19 @@ &sd_emmc_c {
 	status = "disabled";
 };
 
+&periphs_pinctrl {
+	hc4_nor_hold_wp_pins: nor-hold-wp {
+		mux {
+			groups = "nor_hold", "nor_wp";
+			function = "nor";
+			bias-disable;
+		};
+	};
+};
+
 &spifc {
 	status = "okay";
-	pinctrl-0 = <&nor_pins>;
+	pinctrl-0 = <&nor_pins>, <&hc4_nor_hold_wp_pins>;
 	pinctrl-names = "default";
 
 	flash@0 {

-- 
2.43.0

