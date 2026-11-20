From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 20 Nov 2026 06:30:08 +0000
Subject: [PATCH v3 1/2] arm64: dts: allwinner: orangepi-zero2/zero3: Set
 the SPI NOR supply by label
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-zero2-spi-nor-dual-read-v3-1-1cbb0caaed91@gmail.com>
References: <20261120-zero2-spi-nor-dual-read-v3-0-1cbb0caaed91@gmail.com>
In-Reply-To: <20261120-zero2-spi-nor-dual-read-v3-0-1cbb0caaed91@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: Andre Przywara <andre.przywara@arm.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795156207; l=2431;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=/FJTmo3i66dNfZqxF9WLXYNpaf/9aeDUvFfosXiYN8E=;
 b=J2WHGsYmMyWqVDJrcMintnsJAsO4BksZ2s9MpOWF9K21/LCEC39FZpeuciqWRSzVDqDChg5g2
 klC0o2urSPiCsu/1U7ESosS/zs+q9h2p0fQYIjN4PpdZ/UC7zDOJ9J1
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Label the flash node in the shared dtsi, so each board sets its supply
through the label. The Zero2 keeps reg_aldo1. On the Zero3 the flash VDD
is on the 3.3V rail from the AXP313A DLDO1 pin (schematic v1.2), so it
gets reg_dldo1.

Suggested-by: Andre Przywara <andre.przywara@arm.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Andre: reg_dldo1 instead of reg_aldo1 on the Zero3. Schematic v1.2
sheet 4 labels the 3.3V net "ALDO1", but it comes from AXP313A pin 12
(DLDO1, VCC33-DLDO); pin 15 (ALDO1) is the 1.8V VCC18-ALDO. The flash
VDD (U61 pin 8, net DCDCE) is on that 3.3V net. Not tested, no Zero3
here.
---
 arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi | 2 +-
 arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts | 6 ++----
 arch/arm64/boot/dts/allwinner/sun50i-h618-orangepi-zero3.dts | 4 ++++
 3 files changed, 7 insertions(+), 5 deletions(-)

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi
index 0d3e761f6466..cd1f67ad7c2b 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi
@@ -104,7 +104,7 @@ &spi0 {
 	pinctrl-names = "default";
 	pinctrl-0 = <&spi0_pins>, <&spi0_cs0_pin>;
 
-	flash@0 {
+	spi_flash: flash@0 {
 		#address-cells = <1>;
 		#size-cells = <1>;
 		compatible = "jedec,spi-nor";
diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts
index 90c25e12e189..2f8a16d1c9aa 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts
@@ -148,8 +148,6 @@ &pio {
 	vcc-pi-supply = <&reg_aldo1>;
 };
 
-&spi0 {
-	flash@0 {
-		vcc-supply = <&reg_aldo1>;
-	};
+&spi_flash {
+	vcc-supply = <&reg_aldo1>;
 };
diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h618-orangepi-zero3.dts b/arch/arm64/boot/dts/allwinner/sun50i-h618-orangepi-zero3.dts
index c51d4d9120de..afa753dead30 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h618-orangepi-zero3.dts
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h618-orangepi-zero3.dts
@@ -103,3 +103,7 @@ &pio {
 	vcc-ph-supply = <&reg_dldo1>;
 	vcc-pi-supply = <&reg_dldo1>;
 };
+
+&spi_flash {
+	vcc-supply = <&reg_dldo1>;
+};

-- 
2.55.0

