From: Ricardo Pardini <ricardo@pardini.net>
Date: Mon, 09 Nov 2026 13:32:18 +0100
Subject: [PATCH v6 3/6] arm64: dts: rockchip: describe PCIe RTL8125
 Ethernet on CM3588
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-rk3588-dts-rtl-eth-describe-dt-alias-v6-3-91f1efefba0b@pardini.net>
References: <20261109-rk3588-dts-rtl-eth-describe-dt-alias-v6-0-91f1efefba0b@pardini.net>
In-Reply-To: <20261109-rk3588-dts-rtl-eth-describe-dt-alias-v6-0-91f1efefba0b@pardini.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Sebastian Reichel <sebastian.reichel@collabora.com>, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1464; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=w++noZywksCGrRRO7c3hF1elr/qmFxdKHWCq2dOL318=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBq8b1RbN0sIvNk4HfWMyphDIMDobu3+n+g4Ae1W
 yqozNRP7s+JATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCavG9UQAKCRA7Xj/jnsft
 6a8mCACVkbcWbUkpvUzkSoHR/3R3Jk5N0j8ID7eq+SIPZMvaQwgjDZJabc2IFw9CiFrSq3KXbax
 laJ3bG81DGrbfRRzpLNFZzxaOnlyzny8NQrxBdp6VILR0b2/QcX4fj27NCm885q9i3tEQypE1bO
 XWwT9RJrsxhcI6hX++Ev5vU1f+2d7hp7SYSMIRSEIkn54pKTq5tdeLtlh4psuzE2aMXClaDNAKX
 59AfyZ/4eb2ovQK6xxmepIxDm5nkGGhqLaW0rpg2ic8rDMuMtaKROHSLvqBjCwqMPD/n2drOdM7
 ThzbAedS36WOjcw882EUoBgbIrrOPhUcoVRUFbTNoO4eGCu0
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FriendlyElec CM3588 SoM carries one on-board Realtek RTL8125 NIC
behind pcie2x1l2.

Describe the PCI function node and attach an ethernet0 alias, so that
U-Boot's fdt_fixup_ethernet() can fill in its MAC address from its
ethaddr environment.

The node goes in the SoM dtsi, as the RTL8125 sits on the SoM, not on
the CM3588-NAS carrier.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 .../boot/dts/rockchip/rk3588-friendlyelec-cm3588.dtsi     | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-friendlyelec-cm3588.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-friendlyelec-cm3588.dtsi
index 49cf4b85c4e9..d6cff0f5dc86 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-friendlyelec-cm3588.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-friendlyelec-cm3588.dtsi
@@ -18,6 +18,7 @@ / {
 	compatible = "friendlyarm,cm3588", "rockchip,rk3588";
 
 	aliases {
+		ethernet0 = &rtl_eth0;
 		mmc0 = &sdhci;
 		mmc1 = &sdmmc;
 	};
@@ -257,6 +258,20 @@ &pcie2x1l2 {
 	reset-gpios = <&gpio4 RK_PA4 GPIO_ACTIVE_HIGH>;
 	vpcie3v3-supply = <&vcc_3v3_pcie20>;
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
+		rtl_eth0: ethernet@0,0 {
+			compatible = "pci10ec,8125";
+			reg = <0x410000 0 0 0 0>;
+		};
+	};
 };
 
 &pd_gpu {

-- 
2.47.3

