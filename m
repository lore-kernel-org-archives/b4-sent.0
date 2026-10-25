From: Igor Velkov <iav@iav.lv>
Date: Sun, 25 Oct 2026 22:55:51 +0000
Subject: [PATCH] arm64: dts: rockchip: Describe the Ethernet PHY on ROCK Pi
 4
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-rockpi4-gmac-phy-v1-1-69ce4d677189@iav.lv>
X-B4-Tracking: v=1; b=H4sIAPaI3moC/x3MSwqAMAwA0atI1gZs/XsVcSExrUHU0oIo0rtbX
 L7FzAuBvXCAIXvB8yVBziNB5RnQOh+WUZZk0IVuVKFr9CdtTiq0+0zo1gdVZ1RJPZWtIUiZ82z
 k/pfjFOMHydgcumIAAAA=
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Pragnesh Patel <Pragnesh_Patel@mentor.com>, 
 Akash Gajjar <Akash_Gajjar@mentor.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2295; i=iav@iav.lv;
 h=from:subject:message-id; bh=ysO0nvScc///4x6g3QSeXnmC72DmKboxgyT6JKfyNes=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFn3Or7P1jZ6PnH/hIjcQx9E9L/axL654Hc84v6UypqD7
 h8ei5+/21HKwiDGxSArpsgy4ZDGrYwlV//6e5g/gJnDygQyhIGLUwAm4t3GyPD1UHKXP8+0xPwD
 z0Pfan3c2f+D/c9+nn9h7D5J4idOb1Zl+O9rLfT124GNCRlpRw+fmrKwPNPjypr+te7r7p0VShX
 TZ+YBAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ROCK Pi 4 GMAC node has no mdio subnode and no phy-handle, so stmmac
scans the whole MDIO bus. The RTL8211E answers at its strapped address 1
and at the Realtek broadcast address 0, so two phy_devices are created
for one chip, and the netdev attaches to the one at address 0.

On system suspend mdio_bus_phy_suspend() leaves the attached PHY to the
MAC (mac_managed_pm) but suspends the unattached one, which writes
BMCR_PDOWN into the same chip. With s2idle and a MAC Wake-on-LAN magic
packet, 17 of 40 cycles did not wake.

Describe the PHY at address 1 and point phy-handle at it, so only one
phy_device is created.

Tested on ROCK Pi 4A (RTL8211E), s2idle: one PHY on the bus; 40 of 40
cycles woke on a magic packet sent 15 s into sleep, and 35 of 35 more
woke from the expected source with magic packets sent after 5 s to
20 min, RTC alarms, and the two alternating. Later board revisions use
an RTL8211F; their schematics strap it to address 1 as well.

Fixes: 1b5715c602fd ("arm64: dts: rockchip: add ROCK Pi 4 DTS support")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
The deprecated snps,reset-* properties stay in the MAC node; moving the
reset to the PHY node is a separate change.
---
 arch/arm64/boot/dts/rockchip/rk3399-rock-pi-4.dtsi | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-rock-pi-4.dtsi b/arch/arm64/boot/dts/rockchip/rk3399-rock-pi-4.dtsi
index a8ab043e4062..52de4a79e2f4 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-rock-pi-4.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3399-rock-pi-4.dtsi
@@ -202,6 +202,7 @@ &gmac {
 	clock_in_out = "input";
 	phy-supply = <&vcc3v3_lan>;
 	phy-mode = "rgmii";
+	phy-handle = <&rgmii_phy>;
 	pinctrl-names = "default";
 	pinctrl-0 = <&rgmii_pins>;
 	snps,reset-gpio = <&gpio3 RK_PB7 GPIO_ACTIVE_LOW>;
@@ -210,6 +211,16 @@ &gmac {
 	tx_delay = <0x28>;
 	rx_delay = <0x11>;
 	status = "okay";
+
+	mdio {
+		compatible = "snps,dwmac-mdio";
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		rgmii_phy: ethernet-phy@1 {
+			reg = <1>;
+		};
+	};
 };
 
 &gpu {

---
base-commit: d2abcbb905b0e4b2e06b257fa1e5bcf4faa6dbda
change-id: 20261025-rockpi4-gmac-phy-18f13c9c37fc

Best regards,
-- 
Igor Velkov <iav@iav.lv>

