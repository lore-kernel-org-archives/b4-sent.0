From: Joachim Eastwood <joachim.eastwood@gmail.com>
Date: Tue, 28 Jul 2026 14:00:36 +0200
Subject: [PATCH v5 09/12] arm64: dts: rockchip: rk3588s-nanopi-r6: remove
 bogus vcc5v0_usb regulator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260728-nanopi-m6-v5-9-cbc1eb0d8d56@gmail.com>
References: <20260728-nanopi-m6-v5-0-cbc1eb0d8d56@gmail.com>
In-Reply-To: <20260728-nanopi-m6-v5-0-cbc1eb0d8d56@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, diederik@cknow-tech.com, 
 jonas@kwiboo.se, Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785240146; l=1672;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=UrZzPlopCnQpNaQi4ZiWK7IzfEGC03e+DmeotQv9vOE=;
 b=sxjyU4hawUkO6mc4VPr7YSyPFpOYyWguab8zMh0FfY0eMMSaAgQV8/nNWwsTGOuLAeLBmlAOG
 +yZF+W2cMZmCp62ygaCyXp7LvqnYR4EDSbWVdliUwLpKSEJeUi6gofH
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
index 206cc88fdaa1..5a42e7dadc92 100644
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

