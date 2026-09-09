From: =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
Date: Wed, 09 Sep 2026 22:33:22 +0800
Subject: [PATCH v3 1/5] arm64: dts: rockchip: Reset the NanoPi Zero2 PHY
 from the MDIO bus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260909-r28s-upstream-v3-1-ee3e1a34a353@proton.me>
References: <20260909-r28s-upstream-v3-0-ee3e1a34a353@proton.me>
In-Reply-To: <20260909-r28s-upstream-v3-0-ee3e1a34a353@proton.me>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chukun Pan <amadeus@jmu.edu.cn>, jensen <jensenhuang@friendlyarm.com>, 
 Andrey Korshunov <razor1702@gmail.com>, 
 Diederik de Haas <diederik@cknow-tech.com>, 
 =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2540;
 i=HystericalDragons@proton.me; h=from:subject:message-id;
 bh=Uf1K3l1f7dmnIbSjn3YINB58f9z+/Y2KTLHOEJQ3J20=;
 b=owGbwMvMwCUmepz3XUtTHjvjabUkhqyFeYF5wTYZZufNc3dv9ruWplDnsHhyx9trYu0Lv3zrE
 u3q4vToKGVhEONikBVTZJHdVB0ptCp6ZhGL1HGYOaxMIEMYuDgFYCIvgxkZukw3NQa+aF/TeMRv
 6UcLK3PfqOgfIS5GTAs2Tt2+6M6XWwz/tH+27+k/yZp+dYfyf4YzmlpG4X+yPcw2WyzvS5Y0qw9
 kBwA=
X-Developer-Key: i=HystericalDragons@proton.me; a=openpgp;
 fpr=1DB27B5912AA5B9972041AC715C70DEE84826E07
X-Endpoint-Received: by B4 Relay for HystericalDragons@proton.me/default with auth_id=1004
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RGMII PHY reset is described in the PHY node, where it is applied
too late to be of use. __of_mdiobus_register() registers the bus before
walking its children, and for a PHY node without an explicit
ethernet-phy-idAAAA.BBBB compatible, fwnode_mdiobus_register_phy() calls
get_phy_device() to read the PHY ID over the bus before
phy_device_register() gets as far as requesting reset-gpios. A PHY that
the bootloader left in reset is therefore never found:

  mdio_bus stmmac-0: MDIO device at address 1 is missing.

This happens with mainline U-Boot (generic-rk3528), which does not touch
the pin, and leaves the port dead.

Describe the reset on the MDIO bus instead. __mdiobus_register() asserts
and releases the bus level reset-gpios before any device on the bus is
registered, so the PHY responds whatever state the bootloader left it
in. There is only one PHY on mdio1, so a bus wide reset is equivalent.

The pin is muxed by the GPIO request itself, but keep gmac1_rstn_l
described: move it to the MAC, as the MDIO bus has no device of its own
to apply pinctrl to.

Fixes: b944112abef4 ("arm64: dts: rockchip: Add FriendlyElec NanoPi Zero2")
Reported-by: Andrey Korshunov <razor1702@gmail.com>
Closes: https://lore.kernel.org/r/20260909134716.879-1-razor1702@gmail.com
Signed-off-by: 安容 <HystericalDragons@proton.me>
---
 arch/arm64/boot/dts/rockchip/rk3528-nanopi-zero2.dts | 11 +++++------
 1 file changed, 5 insertions(+), 6 deletions(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3528-nanopi-zero2.dts b/arch/arm64/boot/dts/rockchip/rk3528-nanopi-zero2.dts
index 97d85124d2..f3e543d261 100644
--- a/arch/arm64/boot/dts/rockchip/rk3528-nanopi-zero2.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3528-nanopi-zero2.dts
@@ -215,7 +215,7 @@ &gmac1 {
 	phy-supply = <&vcc_3v3>;
 	pinctrl-names = "default";
 	pinctrl-0 = <&rgmii_miim>, <&rgmii_tx_bus2>, <&rgmii_rx_bus2>,
-		    <&rgmii_rgmii_clk>, <&rgmii_rgmii_bus>;
+		    <&rgmii_rgmii_clk>, <&rgmii_rgmii_bus>, <&gmac1_rstn_l>;
 	status = "okay";
 };
 
@@ -242,14 +242,13 @@ hym8563: rtc@51 {
 };
 
 &mdio1 {
+	reset-delay-us = <20000>;
+	reset-gpios = <&gpio4 RK_PC2 GPIO_ACTIVE_LOW>;
+	reset-post-delay-us = <100000>;
+
 	rgmii_phy: ethernet-phy@1 {
 		compatible = "ethernet-phy-ieee802.3-c22";
 		reg = <0x1>;
-		pinctrl-names = "default";
-		pinctrl-0 = <&gmac1_rstn_l>;
-		reset-assert-us = <20000>;
-		reset-deassert-us = <100000>;
-		reset-gpios = <&gpio4 RK_PC2 GPIO_ACTIVE_LOW>;
 	};
 };
 

-- 
2.55.0

