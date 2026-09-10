From: Ricardo Pardini <ricardo@pardini.net>
Date: Thu, 10 Sep 2026 22:07:56 +0200
Subject: [PATCH v5 6/7] arm64: dts: rockchip: describe PCIe RTL8125
 Ethernet on NanoPi R6C
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260910-rk3588-dts-rtl-eth-describe-dt-alias-v5-6-c1b9e5f10cd6@pardini.net>
References: <20260910-rk3588-dts-rtl-eth-describe-dt-alias-v5-0-c1b9e5f10cd6@pardini.net>
In-Reply-To: <20260910-rk3588-dts-rtl-eth-describe-dt-alias-v5-0-c1b9e5f10cd6@pardini.net>
To: Heiner Kallweit <hkallweit1@gmail.com>, nic_swsd@realtek.com, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Sebastian Reichel <sebastian.reichel@collabora.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1602; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=MisAjbBWjrxNVve9XEAprLuxRBoFAEwbTkAxVvkz9Fo=;
 b=owGbwMvMwMFoHWf/eN7xty8ZT6slMWQt5lORqT659ajnQj3O2X/Ld2hH7/C3emXIetGu1prjx
 IGDDvOmdzL6szAwcjBYiimyrJFQ5vm2/tWpOx4dk2EGsTKBTJEWaWAAAhYGvtzEvFIjHSM9U21D
 PUMjHQMdYwYuTgGY6lt17P9M7ZgscsVF8lRstkz1Zxd5e4VVv7Lx19RAd9cjef8uTm9++6PDTUT
 ptMa0/P0CTSnbXAKCfc3L5m0vN/S+FeEnH/pin2V6n7L3gudM+ss87+t+nXC4oH+bXdrRv+n2ao
 ZNeUoGbE67GmculChuO8KR0/m9+LjF6u/+AWcdnEQqHvN8fK5jwmMm/fKZ1q7pPR0Xz1lzeV3Ym
 3JZyuaow2PtC1dTaif8LeJojvWYXBBdOKViSdHUSdNj0tdxCNhVKudMPbLT4YGK8bv/sfafoo8u
 Fw82NVtk69m4kzVx8pLLktUM9Wwpk1/9/e29jEEtKcswIs8r9LlCzivrX+tnzubn0zw1u2j5i7/
 tDmJPAA==
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FriendlyElec NanoPi R6C carries one on-board Realtek RTL8125 NIC
(the LAN port; WAN uses the on-SoC gmac1 RGMII PHY) behind pcie2x1l1.

Describe the fixed function node and attach an ethernet1 alias
(ethernet0 stays mapped to gmac1), so that U-Boot's fdt_fixup_ethernet()
can inject a mac-address from its eth1addr env, for a stable MAC
across boots that both U-Boot and the kernel agree on.

The function node is added in this .dts (not the shared
rk3588s-nanopi-r6.dtsi), since on the R6C the dtsi's second
RTL8125-capable lane is empty compared to the R6S.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6c.dts | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6c.dts b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6c.dts
index ccc5e46275176..b142df0b0e180 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6c.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6c.dts
@@ -7,8 +7,29 @@
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
+	/* on-board RTL8125 2.5GbE NIC */
+	pcie@0,0 {
+		reg = <0x300000 0 0 0 0>;
+		#address-cells = <3>;
+		#size-cells = <2>;
+		ranges;
+		device_type = "pci";
+		bus-range = <0x30 0x3f>;
+
+		rtl_eth1: ethernet@0,0 {
+			compatible = "pci10ec,8125";
+			reg = <0x310000 0 0 0 0>;
+		};
+	};
+};

-- 
2.55.0

