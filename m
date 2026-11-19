From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 05:29:34 +0000
Subject: [PATCH v2 1/2] arm64: dts: allwinner: orangepi-zero2: Reference
 the SPI NOR by label
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-zero2-spi-nor-dual-read-v2-1-185c87065e39@gmail.com>
References: <20261119-zero2-spi-nor-dual-read-v2-0-185c87065e39@gmail.com>
In-Reply-To: <20261119-zero2-spi-nor-dual-read-v2-0-185c87065e39@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: Andre Przywara <andre.przywara@arm.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795066173; l=1653;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Q67hG4LUmhhGEHNYhzy/cl5VtGg3Fnoo9rBc5WdZgVg=;
 b=QrPHNczIJ3tpZjilTnMJlGmRdNz9hN+huIkd/Hg9qAHyJ105T47Sa1JjlqhqPvMgKnRUyLyt6
 51zPNn9l0f/AfQ8TFGJtpZfn/1vOovDcSIOaWnKJZ59LbZGkNAXKcf0
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Andre Przywara suggested labelling the flash node, so the Zero2 sets its
supply through the label instead of nesting flash@0 in &spi0.

Suggested-by: Andre Przywara <andre.przywara@arm.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi |  2 +-
 arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts | 10 ++++------
 2 files changed, 5 insertions(+), 7 deletions(-)

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi
index 0d3e761f6466..646d92e0f724 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi
@@ -104,7 +104,7 @@ &spi0 {
 	pinctrl-names = "default";
 	pinctrl-0 = <&spi0_pins>, <&spi0_cs0_pin>;
 
-	flash@0 {
+	flash: flash@0 {
 		#address-cells = <1>;
 		#size-cells = <1>;
 		compatible = "jedec,spi-nor";
diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts
index 90c25e12e189..59bbb09bcdbf 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts
@@ -24,6 +24,10 @@ &emac0 {
 	phy-supply = <&reg_dcdce>;
 };
 
+&flash {
+	vcc-supply = <&reg_aldo1>;
+};
+
 &gpu {
 	mali-supply = <&reg_dcdcc>;
 };
@@ -147,9 +151,3 @@ &pio {
 	vcc-ph-supply = <&reg_aldo1>;
 	vcc-pi-supply = <&reg_aldo1>;
 };
-
-&spi0 {
-	flash@0 {
-		vcc-supply = <&reg_aldo1>;
-	};
-};

-- 
2.55.0

