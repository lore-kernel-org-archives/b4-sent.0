From: Igor Velkov <iav@iav.lv>
Date: Sat, 24 Oct 2026 22:15:04 +0000
Subject: [PATCH v2] arm64: dts: rockchip: Add the GPIO expander to Kobol
 Helios64
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-helios64-pca9655-v2-1-97210e9aafb1@iav.lv>
X-B4-Tracking: v=1; b=H4sIAOgt3WoC/32NSwrCMBRFt1Le2Ej+EkfuQzoI6at5UJqSlKCU7
 N3YBTg8B+65BxTMhAXuwwEZKxVKawd5GSBEv76Q0dQZJJdWcO5YxIVSsZptwTtrDFPOahWkD7O
 eoM+2jDO9z+Rz7Byp7Cl/zocqfvZPrArGmb0pRK2VtIY/yNfrUmFsrX0BjMhYFK0AAAA=
To: Heiko Stuebner <heiko@sntech.de>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Rosen Penev <rosenp@gmail.com>, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2516; i=iav@iav.lv;
 h=from:subject:message-id; bh=NxG+xHVeylkpzOnvEZLanDkLJTXNZz8dgrlgIaGTkKw=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFl3dV/d6TAQm7Npl2PW069avwLfBltsv2fFzcbnUztpR
 deDGd8COkpZGMS4GGTFFFkmHNK4lbHk6l9/D/MHMHNYmUCGMHBxCsBEbi1gZFgQbsmwMNKU9xyb
 bXLOMam4R1xHNzAl2y5cxxRXeUSqRIPhv3dFqTFXxhdWJSkTB/uIMt35/0uYZoWKbPqZlW43474
 aGwA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Helios64 has an ON Semiconductor PCA9655E 16-bit GPIO expander at 0x20
on I2C2, powered from VCC3V3_SYS_S3. Its 16 lines go to pins 4-19 of
the P5 GPIO header, one line per pin in order, so name them after the
pins. Its INT# output goes to GPIO0_B1 with an external pull-up (R59
to 1V8_S3), so the pin has no internal bias. Schematic, sheets 34 and
35:
https://wiki.kobol.io/helios64/files/schematics/Helios64_Schematics_Rev1.2.pdf

Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
The node is the one tested on the board in v1; the line names are
checked with dt-validate only.
---
Changes in v2:
- Drop the binding patch, applied by Bartosz as 356cab616b6f.
- Name the lines after the P5 header pins, label the node p5_gpio.
- Rebase on for-next.
- Link to v1: https://lore.kernel.org/r/20261009-helios64-pca9655-v1-0-673ee4432650@iav.lv
---
 .../boot/dts/rockchip/rk3399-kobol-helios64.dts    | 25 ++++++++++++++++++++++
 1 file changed, 25 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
index 63ad79b4c8ac..df993cbb17c8 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
@@ -461,6 +461,25 @@ &i2c2 {
 	i2c-scl-falling-time-ns = <30>;
 	status = "okay";
 
+	p5_gpio: gpio@20 {
+		compatible = "onnn,pca9655", "nxp,pca9555";
+		reg = <0x20>;
+		gpio-controller;
+		#gpio-cells = <2>;
+		/* All 16 lines go to pins 4-19 of the P5 GPIO header */
+		gpio-line-names = "PIN_4", "PIN_5", "PIN_6", "PIN_7",
+				  "PIN_8", "PIN_9", "PIN_10", "PIN_11",
+				  "PIN_12", "PIN_13", "PIN_14", "PIN_15",
+				  "PIN_16", "PIN_17", "PIN_18", "PIN_19";
+		interrupt-controller;
+		#interrupt-cells = <2>;
+		interrupt-parent = <&gpio0>;
+		interrupts = <RK_PB1 IRQ_TYPE_LEVEL_LOW>;
+		pinctrl-names = "default";
+		pinctrl-0 = <&exp16_int_l>;
+		vcc-supply = <&vcc3v3_sys_s3>;
+	};
+
 	temp@4c {
 		compatible = "national,lm75";
 		reg = <0x4c>;
@@ -501,6 +520,12 @@ user1_btn: user1-btn {
 		};
 	};
 
+	expander {
+		exp16_int_l: exp16-int-l {
+			rockchip,pins = <0 RK_PB1 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+	};
+
 	fan {
 		fan1_sense: fan1-sense {
 			rockchip,pins = <4 RK_PC5 RK_FUNC_GPIO &pcfg_pull_none>;

---
base-commit: d2abcbb905b0e4b2e06b257fa1e5bcf4faa6dbda
change-id: 20261009-helios64-pca9655-39643c2acf4d

Best regards,
-- 
Igor Velkov <iav@iav.lv>

