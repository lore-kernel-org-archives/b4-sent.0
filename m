From: Ricardo Pardini <ricardo@pardini.net>
Date: Mon, 09 Nov 2026 13:32:20 +0100
Subject: [PATCH v6 5/6] arm64: dts: rockchip: describe PCIe RTL8125
 Ethernet on NanoPi R6C
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-rk3588-dts-rtl-eth-describe-dt-alias-v6-5-91f1efefba0b@pardini.net>
References: <20261109-rk3588-dts-rtl-eth-describe-dt-alias-v6-0-91f1efefba0b@pardini.net>
In-Reply-To: <20261109-rk3588-dts-rtl-eth-describe-dt-alias-v6-0-91f1efefba0b@pardini.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Sebastian Reichel <sebastian.reichel@collabora.com>, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1480; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=6l7amNejMT6z9WZmcw/pfLmctMDWO9DfRwNlH72+y/A=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBq8b1SK64PYsE49HfauhMNNZc/Rxcke7TNSjqMa
 TII3ZbM58uJATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCavG9UgAKCRA7Xj/jnsft
 6cCKCACRRwgub/X++u8B6gmcSwy4+GoKdlmB7GLraOLHglCdCq5Pi3zLu0aGpkvold4AvL5Lb61
 7woCiP/8J1TBEOAVMiSD3bACaak4/TUy2S4rAEOVoacE2/Q/q2FJIiakZ8HALnO7gI/x1sJKSiZ
 XrDOsP/AECbPAGxp3uKQzJFRfnBmV+elopaBK085c0ttELmcttRUD1FAwBYl6MGRux/LFfhyq06
 oR1r7vZezWNEuluIRtSbi8S8+ZBwQc7NvBFxAStDplw0BNMWrR4VozASrdwFAXPZUHpede5v3wd
 OvsGfIyQLWiGwvT5bWehpl4NCMo0919cfvWpVblmUy5liRQQ
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FriendlyElec NanoPi R6C carries one on-board Realtek RTL8125 NIC
(the LAN port) behind pcie2x1l1.

Describe the PCI function node and attach an ethernet1 alias, so that
U-Boot's fdt_fixup_ethernet() can fill in its MAC address from its
eth1addr environment.

ethernet0 stays mapped to the on-SoC gmac1 (the WAN port). The node
goes in this .dts rather than the shared rk3588s-nanopi-r6.dtsi, since
on the R6C the dtsi's second RTL8125-capable lane is empty compared to
the R6S.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6c.dts | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6c.dts b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6c.dts
index ccc5e4627517..48d87f7923db 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6c.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6c.dts
@@ -7,8 +7,28 @@
 / {
 	model = "FriendlyElec NanoPi R6C";
 	compatible = "friendlyarm,nanopi-r6c", "rockchip,rk3588s";
+
+	aliases {
+		ethernet1 = &rtl_eth1;
+	};
 };
 
 &lan2_led {
 	label = "user_led";
 };
+
+&pcie2x1l1 {
+	pcie@0,0 {
+		reg = <0x300000 0 0 0 0>;
+		#address-cells = <3>;
+		#size-cells = <2>;
+		ranges;
+		device_type = "pci";
+		bus-range = <0x31 0x3f>;
+
+		rtl_eth1: ethernet@0,0 {
+			compatible = "pci10ec,8125";
+			reg = <0x310000 0 0 0 0>;
+		};
+	};
+};

-- 
2.47.3

