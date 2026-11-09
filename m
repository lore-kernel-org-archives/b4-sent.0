From: Ricardo Pardini <ricardo@pardini.net>
Date: Mon, 09 Nov 2026 13:32:21 +0100
Subject: [PATCH v6 6/6] arm64: dts: rockchip: describe PCIe RTL8125
 Ethernet on ROCK 5 ITX
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-rk3588-dts-rtl-eth-describe-dt-alias-v6-6-91f1efefba0b@pardini.net>
References: <20261109-rk3588-dts-rtl-eth-describe-dt-alias-v6-0-91f1efefba0b@pardini.net>
In-Reply-To: <20261109-rk3588-dts-rtl-eth-describe-dt-alias-v6-0-91f1efefba0b@pardini.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Sebastian Reichel <sebastian.reichel@collabora.com>, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1839; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=wCLAexHdVkD0jpxkUE9ppJGf4g2Tzpw3hn/wf3LCfHA=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBq8b1TWy6Z8ypuZjA136KddZ2dUSBysSOVhFyWT
 2MthJcSKISJATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCavG9UwAKCRA7Xj/jnsft
 6ZseB/9DPncY7tXNZ1Pc+fRxccZBkMS/xty8tA8bsrQ1Gm3LUiwmVVWcUVmuPmMUYx1XCF5VjkR
 oITtKrxpJlugGtCGHkScPy/X0WzmabA9Csz58gqrPhmi4NoK6InzzV9BRs9V+6+oa8rOLF6Rjp5
 Z2tvUE+oNWxzHzJz09o8Gdh/gNi3dAzHY7dgU6l12jKciOQyV4yu/ovK7I3DbuGY/ysQwcL8kih
 oC+rmL7i4eidMAkaspJKUqlBwc+11muQyBj29KidP/NxIk2AcKisGEN15e/VzehklW5S1ToOPnm
 5cCMFjLK4OJwnyVzJJYxL2QHzlMDTQzi6QeuVISb2LSIf2QW
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Radxa ROCK 5 ITX carries two on-board Realtek RTL8125 NICs behind
pcie2x1l1 and pcie2x1l2.

Describe the PCI function nodes and attach ethernet0/ethernet1
aliases, so that U-Boot's fdt_fixup_ethernet() can fill in their MAC
addresses from its ethaddr/eth1addr environment.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 arch/arm64/boot/dts/rockchip/rk3588-rock-5-itx.dts | 30 ++++++++++++++++++++++
 1 file changed, 30 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-rock-5-itx.dts b/arch/arm64/boot/dts/rockchip/rk3588-rock-5-itx.dts
index 9d3d26d4600b..dd9767edd42c 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-rock-5-itx.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3588-rock-5-itx.dts
@@ -20,6 +20,8 @@ / {
 	compatible = "radxa,rock-5-itx", "rockchip,rk3588";
 
 	aliases {
+		ethernet0 = &rtl_eth0;
+		ethernet1 = &rtl_eth1;
 		mmc0 = &sdhci;
 		mmc1 = &sdmmc;
 		mmc2 = &sdio;
@@ -631,6 +633,20 @@ &pcie2x1l1 {
 	reset-gpios = <&gpio4 RK_PA2 GPIO_ACTIVE_HIGH>;
 	vpcie3v3-supply = <&vcc3v3_lan>;
 	status = "okay";
+
+	pcie@0,0 {
+		reg = <0x300000 0 0 0 0>;
+		#address-cells = <3>;
+		#size-cells = <2>;
+		ranges;
+		device_type = "pci";
+		bus-range = <0x31 0x3f>;
+
+		rtl_eth0: ethernet@0,0 {
+			compatible = "pci10ec,8125";
+			reg = <0x310000 0 0 0 0>;
+		};
+	};
 };
 
 /* RTL8125B_2 */
@@ -640,6 +656,20 @@ &pcie2x1l2 {
 	reset-gpios = <&gpio3 RK_PB0 GPIO_ACTIVE_HIGH>;
 	vpcie3v3-supply = <&vcc3v3_lan_phy2>;
 	status = "okay";
+
+	pcie@0,0 {
+		reg = <0x400000 0 0 0 0>;
+		#address-cells = <3>;
+		#size-cells = <2>;
+		ranges;
+		device_type = "pci";
+		bus-range = <0x41 0x4f>;
+
+		rtl_eth1: ethernet@0,0 {
+			compatible = "pci10ec,8125";
+			reg = <0x410000 0 0 0 0>;
+		};
+	};
 };
 
 &pcie30phy {

-- 
2.47.3

