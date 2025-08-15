From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 15 Aug 2025 16:37:34 +0800
Subject: [PATCH 08/13] arm64: dts: amlogic: Unify the compatible property
 for clk-measure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250815-add-more-socs-to-support-clk_measure-v1-8-59f04ba67457@amlogic.com>
References: <20250815-add-more-socs-to-support-clk_measure-v1-0-59f04ba67457@amlogic.com>
In-Reply-To: <20250815-add-more-socs-to-support-clk_measure-v1-0-59f04ba67457@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755247057; l=3522;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=EHJwnnddK5r6qztNb2TJl7JYxmXy90quB+2alicslFc=;
 b=zv242H2x9f/LEwB89LfCTL3Z61M1JxVpanUqgW4kxMvHUmoNhs0D9AxOm8Z5gvO/ddNsWqG0v
 va6BgMWpjgGDcMk0PIbiWWiDNCXJscS56n/rDO9UWGfJHIWQNOfPSMD
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The clk-measure IPs across Amlogic SoCs have minimal differences, so
they can be managed with a unified compatible property.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi       | 2 +-
 arch/arm64/boot/dts/amlogic/meson-axg.dtsi        | 2 +-
 arch/arm64/boot/dts/amlogic/meson-g12-common.dtsi | 2 +-
 arch/arm64/boot/dts/amlogic/meson-gx.dtsi         | 2 +-
 arch/arm64/boot/dts/amlogic/meson-s4.dtsi         | 2 +-
 arch/arm64/boot/dts/amlogic/meson-sm1.dtsi        | 1 -
 6 files changed, 5 insertions(+), 6 deletions(-)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi
index ab9ebabce171..570cac451d63 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi
@@ -761,7 +761,7 @@ internal_ephy: ethernet_phy@8 {
 			};
 
 			clk_msr: clock-measure@48000 {
-				compatible = "amlogic,c3-clk-measure";
+				compatible = "amlogic,clk-measure";
 				reg = <0x0 0x48000 0x0 0x1c>;
 				clkmsr-reg-v2;
 				clkmsr-indices = <0>,
diff --git a/arch/arm64/boot/dts/amlogic/meson-axg.dtsi b/arch/arm64/boot/dts/amlogic/meson-axg.dtsi
index d4a4a037e0f6..e939ec6186c6 100644
--- a/arch/arm64/boot/dts/amlogic/meson-axg.dtsi
+++ b/arch/arm64/boot/dts/amlogic/meson-axg.dtsi
@@ -1858,7 +1858,7 @@ spicc1: spi@15000 {
 			};
 
 			clk_msr: clock-measure@18000 {
-				compatible = "amlogic,meson-axg-clk-measure";
+				compatible = "amlogic,clk-measure";
 				reg = <0x0 0x18000 0x0 0x10>;
 				clkmsr-indices = <0>,
 						 <1>,
diff --git a/arch/arm64/boot/dts/amlogic/meson-g12-common.dtsi b/arch/arm64/boot/dts/amlogic/meson-g12-common.dtsi
index dcc927a9da80..54220f105a4d 100644
--- a/arch/arm64/boot/dts/amlogic/meson-g12-common.dtsi
+++ b/arch/arm64/boot/dts/amlogic/meson-g12-common.dtsi
@@ -2385,7 +2385,7 @@ i2c0: i2c@1f000 {
 			};
 
 			clk_msr: clock-measure@18000 {
-				compatible = "amlogic,meson-g12a-clk-measure";
+				compatible = "amlogic,clk-measure";
 				reg = <0x0 0x18000 0x0 0x10>;
 			};
 
diff --git a/arch/arm64/boot/dts/amlogic/meson-gx.dtsi b/arch/arm64/boot/dts/amlogic/meson-gx.dtsi
index 4510e3403174..4330a6284873 100644
--- a/arch/arm64/boot/dts/amlogic/meson-gx.dtsi
+++ b/arch/arm64/boot/dts/amlogic/meson-gx.dtsi
@@ -365,7 +365,7 @@ uart_C: serial@8700 {
 			};
 
 			clock-measure@8758 {
-				compatible = "amlogic,meson-gx-clk-measure";
+				compatible = "amlogic,clk-measure";
 				reg = <0x0 0x8758 0x0 0x10>;
 				clkmsr-indices = <0>,
 						 <1>,
diff --git a/arch/arm64/boot/dts/amlogic/meson-s4.dtsi b/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
index 21a9fb27ee3f..8df234ad78e8 100644
--- a/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
+++ b/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
@@ -630,7 +630,7 @@ internal_ephy: ethernet-phy@8 {
 			};
 
 			clk_msr: clock-measure@48000 {
-				compatible = "amlogic,s4-clk-measure";
+				compatible = "amlogic,clk-measure";
 				reg = <0x0 0x48000 0x0 0x1c>;
 				clkmsr-reg-v2;
 				clkmsr-indices = <0>,
diff --git a/arch/arm64/boot/dts/amlogic/meson-sm1.dtsi b/arch/arm64/boot/dts/amlogic/meson-sm1.dtsi
index 8ecf876c73ee..2279237db793 100644
--- a/arch/arm64/boot/dts/amlogic/meson-sm1.dtsi
+++ b/arch/arm64/boot/dts/amlogic/meson-sm1.dtsi
@@ -478,7 +478,6 @@ &cecb_AO {
 };
 
 &clk_msr {
-	compatible = "amlogic,meson-sm1-clk-measure";
 	clkmsr-indices = <0>,
 			 <1>,
 			 <2>,

-- 
2.42.0

