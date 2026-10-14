From: Joachim Eastwood <joachim.eastwood@gmail.com>
Date: Wed, 14 Oct 2026 18:33:04 +0200
Subject: [PATCH 4/9] arm64: dts: rockchip: rk3588s-nanopi: move vcc_3v3_s0
 to nanopi-r6
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-nanopi-m6-improvements-v1-4-e713f71eb4d3@gmail.com>
References: <20261014-nanopi-m6-improvements-v1-0-e713f71eb4d3@gmail.com>
In-Reply-To: <20261014-nanopi-m6-improvements-v1-0-e713f71eb4d3@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Diederik de Haas <diederik@cknow-tech.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791995685; l=3028;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=LW5ZqnxsOBSTr6UvbPg/uqbC8B0uUFOPy+2nS2Lvnv0=;
 b=xobRsExttICvlp8s0V+6I7q0DL9iq1IbxeHH7rjT7TMHvmLis5EnZc3ilg6J95NCik+ehSEON
 JX9Xmt+uojMBJjXqLVxnJpbUUnyQuzCcsr7RgF8UnCCVM35fbKZA1pi
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This regulator (power switch) is only present on R6 boards, and not M6
boards. It is regulator-always-on and regulator-boot-on because it's
controlled by the vcc_1v8_s0 power rail from the PMIC.

On R6 boards it's used by the Ethernet phy, and some VCCIO rails on the
SoC itself.

Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588s-nanopi-m6.dtsi |  4 ++++
 arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi | 14 ++++++++++++++
 arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi    | 11 -----------
 3 files changed, 18 insertions(+), 11 deletions(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-m6.dtsi b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-m6.dtsi
index 6644d3b72c9c..6205a542cd1a 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-m6.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-m6.dtsi
@@ -85,6 +85,10 @@ &i2s0_sdi0
 	status = "okay";
 };
 
+&gmac1 {
+	phy-supply = <&vcc_3v3_s3>;
+};
+
 &pcie2x1l1 { /* M.2 E-key 2230 */
 	vpcie3v3-supply = <&vdd_mpcie_3v3>;
 };
diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi
index ac9eebd2b790..b0892a3c633b 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi
@@ -48,6 +48,16 @@ lan2_led: led-3 {
 		};
 	};
 
+	vcc_3v3_s0: regulator-vcc-3v3-s0 {
+		compatible = "regulator-fixed";
+		regulator-always-on;
+		regulator-boot-on;
+		regulator-min-microvolt = <3300000>;
+		regulator-max-microvolt = <3300000>;
+		regulator-name = "vcc_3v3_s0";
+		vin-supply = <&vcc_3v3_s3>;
+	};
+
 	vcc5v0_usb_otg0: regulator-vcc5v0-usb-otg0 {
 		compatible = "regulator-fixed";
 		enable-active-high;
@@ -61,6 +71,10 @@ vcc5v0_usb_otg0: regulator-vcc5v0-usb-otg0 {
 	};
 };
 
+&gmac1 {
+	phy-supply = <&vcc_3v3_s0>;
+};
+
 &pinctrl {
 	gpio-key {
 		key1_pin: key1-pin {
diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi
index a47677926a59..a99e2e60c5f7 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi
@@ -61,16 +61,6 @@ vcc_1v1_nldo_s3: regulator-vcc-1v1-nldo-s3 {
 		vin-supply = <&vcc5v0_sys>;
 	};
 
-	vcc_3v3_s0: regulator-vcc-3v3-s0 {
-		compatible = "regulator-fixed";
-		regulator-always-on;
-		regulator-boot-on;
-		regulator-min-microvolt = <3300000>;
-		regulator-max-microvolt = <3300000>;
-		regulator-name = "vcc_3v3_s0";
-		vin-supply = <&vcc_3v3_s3>;
-	};
-
 	vcc_3v3_sd_s0: regulator-vcc-3v3-sd-s0 {
 		compatible = "regulator-fixed";
 		enable-active-high;
@@ -154,7 +144,6 @@ &gmac1 {
 	clock_in_out = "output";
 	phy-handle = <&rgmii_phy1>;
 	phy-mode = "rgmii-rxid"; /* Vendor provided tx delay value below */
-	phy-supply = <&vcc_3v3_s3>;
 	pinctrl-0 = <&gmac1_miim
 		     &gmac1_tx_bus2
 		     &gmac1_rx_bus2

-- 
2.56.0

