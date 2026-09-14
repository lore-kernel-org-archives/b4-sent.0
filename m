From: =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
Date: Mon, 14 Sep 2026 16:24:10 +0800
Subject: [PATCH v5 4/4] arm64: dts: rockchip: Follow the DTS coding style
 in the NanoPi RK3528 devicetrees
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260914-r28s-upstream-v5-4-7409c498e8dc@proton.me>
References: <20260914-r28s-upstream-v5-0-7409c498e8dc@proton.me>
In-Reply-To: <20260914-r28s-upstream-v5-0-7409c498e8dc@proton.me>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chukun Pan <amadeus@jmu.edu.cn>, Jonas Karlman <jonas@kwiboo.se>, 
 jensen <jensenhuang@friendlyarm.com>, 
 Andrey Korshunov <razor1702@gmail.com>, 
 Diederik de Haas <diederik@cknow-tech.com>, 
 =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2532;
 i=HystericalDragons@proton.me; h=from:subject:message-id;
 bh=axQv03VI0SPoMzFgZAAgEWAflE5+RNrxFv6cJ6dO4AU=;
 b=owGbwMvMwCUmepz3XUtTHjvjabUkhqzl6/Urj34+npb2imvPHTZ29bdvG51nnLw/eZPidn3m/
 vaU6zW7O0pZGMS4GGTFFFlkN1VHCq2KnlnEInUcZg4rE8gQBi5OAZjIIXVGhu28cV94L8pHVjzg
 LjLRv/T3346TYqsSdLmrF+0paC1hXcDwP+FojeLuEDXjiHemTjNW7A1csFnEzP2vXa+LgpWJEcN
 3dgA=
X-Developer-Key: i=HystericalDragons@proton.me; a=openpgp;
 fpr=1DB27B5912AA5B9972041AC715C70DEE84826E07
X-Endpoint-Received: by B4 Relay for HystericalDragons@proton.me/default with auth_id=1004
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Documentation/devicetree/bindings/dts-coding-style.rst asks for "status"
to be preceded by a blank line when there is content before it in the
node. The shared NanoPi RK3528 devicetree and the NanoPi Zero2 board
devicetree do not do that.

Add the missing blank lines. No functional changes.

Suggested-by: Diederik de Haas <diederik@cknow-tech.com>
Signed-off-by: 安容 <HystericalDragons@proton.me>
---
 arch/arm64/boot/dts/rockchip/rk3528-nanopi-zero2.dts |  1 +
 arch/arm64/boot/dts/rockchip/rk3528-nanopi.dtsi      | 10 ++++++++++
 2 files changed, 11 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3528-nanopi-zero2.dts b/arch/arm64/boot/dts/rockchip/rk3528-nanopi-zero2.dts
index a8d99f983f..7d1ed8815d 100644
--- a/arch/arm64/boot/dts/rockchip/rk3528-nanopi-zero2.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3528-nanopi-zero2.dts
@@ -76,5 +76,6 @@ &usb_host0_ohci {
 
 &usb2phy_host {
 	phy-supply = <&usb2_host_5v>;
+
 	status = "okay";
 };
diff --git a/arch/arm64/boot/dts/rockchip/rk3528-nanopi.dtsi b/arch/arm64/boot/dts/rockchip/rk3528-nanopi.dtsi
index 06a6c0dc82..9637f91ef0 100644
--- a/arch/arm64/boot/dts/rockchip/rk3528-nanopi.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3528-nanopi.dtsi
@@ -170,17 +170,20 @@ &gmac1 {
 	pinctrl-names = "default";
 	pinctrl-0 = <&rgmii_miim>, <&rgmii_tx_bus2>, <&rgmii_rx_bus2>,
 		    <&rgmii_rgmii_clk>, <&rgmii_rgmii_bus>;
+
 	status = "okay";
 };
 
 &gpu {
 	mali-supply = <&vdd_logic>;
+
 	status = "okay";
 };
 
 &i2c1 {
 	pinctrl-names = "default";
 	pinctrl-0 = <&i2c1m0_xfer>;
+
 	status = "okay";
 
 	hym8563: rtc@51 {
@@ -244,17 +247,20 @@ sdmmc_vol_ctrl_h: sdmmc-vol-ctrl-h {
 &pwm1 {
 	pinctrl-names = "default";
 	pinctrl-0 = <&pwm1m0_pins>;
+
 	status = "okay";
 };
 
 &pwm2 {
 	pinctrl-names = "default";
 	pinctrl-0 = <&pwm2m0_pins>;
+
 	status = "okay";
 };
 
 &saradc {
 	vref-supply = <&vcc_1v8>;
+
 	status = "okay";
 };
 
@@ -267,6 +273,7 @@ &sdhci {
 	non-removable;
 	vmmc-supply = <&vcc_3v3>;
 	vqmmc-supply = <&vcc_1v8>;
+
 	status = "okay";
 };
 
@@ -278,12 +285,14 @@ &sdmmc {
 	sd-uhs-sdr104;
 	vmmc-supply = <&vcc3v3_sd>;
 	vqmmc-supply = <&vccio_sd>;
+
 	status = "okay";
 };
 
 &uart0 {
 	pinctrl-names = "default";
 	pinctrl-0 = <&uart0m0_xfer>;
+
 	status = "okay";
 };
 
@@ -292,6 +301,7 @@ &usb_host0_xhci {
 	maximum-speed = "high-speed";
 	phys = <&usb2phy_otg>;
 	phy-names = "usb2-phy";
+
 	status = "okay";
 };
 

-- 
2.55.0

