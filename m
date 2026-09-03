From: Joachim Eastwood <joachim.eastwood@gmail.com>
Date: Thu, 03 Sep 2026 23:23:19 +0200
Subject: [PATCH v6 07/12] arm64: dts: rockchip: rk3588s-nanopi-r6: remove
 useless vcc_3v3_pcie20
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260903-nanopi-m6-v6-7-37416bbd6862@gmail.com>
References: <20260903-nanopi-m6-v6-0-37416bbd6862@gmail.com>
In-Reply-To: <20260903-nanopi-m6-v6-0-37416bbd6862@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, diederik@cknow-tech.com, 
 jonas@kwiboo.se, Joachim Eastwood <joachim.eastwood@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788470611; l=1725;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=w2cXBopYBKJ6Vf2I5uUHUSmKKAcZ+ftsSxy14dp/jMA=;
 b=Y3KCbLcxa4SGSbJwcG6IrelFcY9Mn97PWJKnVc4TAbqEzioJaAh4LatldDFMUYZJKtkGm0GxQ
 U+WyBTHq3p+BUOevcjk7djjH/barv4LENZdAyTjXalucX52Hw+YnI9L
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There is no separate regulator for boards with RTL8125BG MACs.
The power is only separated from VCC_3V3_S3 with a ferrite bead.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi | 14 ++------------
 1 file changed, 2 insertions(+), 12 deletions(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi
index 8953dcebb93e..50af092f9cfa 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi
@@ -131,16 +131,6 @@ vcc_3v3_sd_s0: regulator-vcc-3v3-sd-s0 {
 		vin-supply = <&vcc_3v3_s3>;
 	};
 
-	vcc_3v3_pcie20: regulator-vcc3v3-pcie20 {
-		compatible = "regulator-fixed";
-		regulator-name = "vcc_3v3_pcie20";
-		regulator-always-on;
-		regulator-boot-on;
-		regulator-min-microvolt = <3300000>;
-		regulator-max-microvolt = <3300000>;
-		vin-supply = <&vcc_3v3_s3>;
-	};
-
 	vcc5v0_usb: regulator-vcc5v0-usb {
 		compatible = "regulator-fixed";
 		regulator-name = "vcc5v0_usb";
@@ -361,7 +351,7 @@ &pcie2x1l1 {
 	pinctrl-names = "default";
 	pinctrl-0 = <&pcie20x1_1_perstn_m2>;
 	reset-gpios = <&gpio1 RK_PA7 GPIO_ACTIVE_HIGH>;
-	vpcie3v3-supply = <&vcc_3v3_pcie20>;
+	vpcie3v3-supply = <&vcc_3v3_s3>;
 	status = "okay";
 };
 
@@ -370,7 +360,7 @@ &pcie2x1l2 {
 	pinctrl-0 = <&pcie20x1_2_perstn_m0>, <&pcie20x1m0_clkreqn>;
 	supports-clkreq;
 	reset-gpios = <&gpio3 RK_PD1 GPIO_ACTIVE_HIGH>;
-	vpcie3v3-supply = <&vcc_3v3_pcie20>;
+	vpcie3v3-supply = <&vcc_3v3_s3>;
 	status = "okay";
 };
 

-- 
2.55.0

