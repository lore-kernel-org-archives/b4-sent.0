From: Joachim Eastwood <joachim.eastwood@gmail.com>
Date: Mon, 13 Jul 2026 22:30:13 +0200
Subject: [PATCH v3 09/12] arm64: dts: rockchip: rk3588s-nanopi-r6: remove
 bogus vcc5v0_usb regulator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260713-nanopi-m6-v3-9-227567ffc5dc@gmail.com>
References: <20260713-nanopi-m6-v3-0-227567ffc5dc@gmail.com>
In-Reply-To: <20260713-nanopi-m6-v3-0-227567ffc5dc@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, diederik@cknow-tech.com, 
 jonas@kwiboo.se, Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783974651; l=1672;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=iPy2X35YL+LpSjA3UQEe7qm+WPZWFPTt/yLokJTeBU0=;
 b=ntfUyTUDty3vJWNcfz9gac5nDz5BWxuwHfd33Di+1zZWW4PyP5ZBTM6GdthzA14oDqyA3PjTw
 5TOW8Jxf/VqDnO8RaHjiquKzlScCsQ2n0hEA9qvUp+vgOogM58JkV5B
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All USB regulators (power switches) are feed from the main vcc5v0
supply. There is no regulator or switch in between.

Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi | 14 ++------------
 1 file changed, 2 insertions(+), 12 deletions(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi
index aa074ecda050..84fde8a669a7 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi
@@ -131,16 +131,6 @@ vcc_3v3_sd_s0: regulator-vcc-3v3-sd-s0 {
 		vin-supply = <&vcc_3v3_s3>;
 	};
 
-	vcc5v0_usb: regulator-vcc5v0-usb {
-		compatible = "regulator-fixed";
-		regulator-name = "vcc5v0_usb";
-		regulator-always-on;
-		regulator-boot-on;
-		regulator-min-microvolt = <5000000>;
-		regulator-max-microvolt = <5000000>;
-		vin-supply = <&vcc5v0_sys>;
-	};
-
 	vcc5v0_usb_otg0: regulator-vcc5v0-usb-otg0 {
 		compatible = "regulator-fixed";
 		enable-active-high;
@@ -150,7 +140,7 @@ vcc5v0_usb_otg0: regulator-vcc5v0-usb-otg0 {
 		regulator-name = "vcc5v0_usb_otg0";
 		regulator-min-microvolt = <5000000>;
 		regulator-max-microvolt = <5000000>;
-		vin-supply = <&vcc5v0_usb>;
+		vin-supply = <&vcc5v0_sys>;
 	};
 
 	vcc5v0_host_20: regulator-vcc5v0-host-20 {
@@ -162,7 +152,7 @@ vcc5v0_host_20: regulator-vcc5v0-host-20 {
 		regulator-name = "vcc5v0_host_20";
 		regulator-min-microvolt = <5000000>;
 		regulator-max-microvolt = <5000000>;
-		vin-supply = <&vcc5v0_usb>;
+		vin-supply = <&vcc5v0_sys>;
 	};
 };
 

-- 
2.55.0

