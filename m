From: Ricardo Pardini <ricardo@pardini.net>
Date: Thu, 10 Sep 2026 22:07:54 +0200
Subject: [PATCH v5 4/7] arm64: dts: rockchip: describe PCIe RTL8125
 Ethernet on CM3588-NAS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260910-rk3588-dts-rtl-eth-describe-dt-alias-v5-4-c1b9e5f10cd6@pardini.net>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1709; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=6aWGqDcRch0v/DplqTK15TLUKtWXFJaV5tLvgpIwOHw=;
 b=owEBiQF2/pANAwAIATteP+Oex+3pAcsmYgBqow4kAR15pUoqF3xi9F3Vxau8FW177GaOAb8zv
 VSbYj0m77CJAU8EAAEIADkWIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCaqMOJBsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQO14/457H7emW2Qf9ECGLK+iE4GdKQosucYn4phX5l51nFBA
 bIosr3xNCE+YOUAmo5Kh0dpvoZnw3mmaMH/+kSdfsLK1aMHWTgI9u/+B5Td8Y3onC/7+ZK4kJ4N
 nz/CXisUAG2EzqJAjx1NB33n4oMlFnvn6aFZdCLA/iEMwKyNvq3u21TgeDeFIQwE9LR9XQjyOCL
 eWTspIHvOhYFiuQVc9vlJdcw8XJnZqgt+tyND0dOGRHNwVMLPp1CS7zLgQSUKqeim4M52uxtKzY
 jgNia/u27vVSBrSi93ubO5beyBl5eZArW41VAlpe46lF5uTu6Kusy5b/EgquKT0jEdiD4XzWcR/
 pNa7ekAQUxw==
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FriendlyElec CM3588-NAS carrier carries an on-board Realtek
RTL8125 NIC behind pcie2x1l2.

Describe the fixed function node and attach an ethernet0 alias in the
NAS carrier .dts (not the SoM dtsi, as the RTL8125 sits on the
carrier), so that U-Boot's fdt_fixup_ethernet() can inject a
mac-address from its ethaddr env, for a stable MAC across boots that
both U-Boot and the kernel agree on.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 .../dts/rockchip/rk3588-friendlyelec-cm3588-nas.dts | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-friendlyelec-cm3588-nas.dts b/arch/arm64/boot/dts/rockchip/rk3588-friendlyelec-cm3588-nas.dts
index f4c34da61c4df..96b3b245e0866 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-friendlyelec-cm3588-nas.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3588-friendlyelec-cm3588-nas.dts
@@ -20,6 +20,10 @@ / {
 	model = "FriendlyElec CM3588 NAS";
 	compatible = "friendlyarm,cm3588-nas", "friendlyarm,cm3588", "rockchip,rk3588";
 
+	aliases {
+		ethernet0 = &rtl_eth0;
+	};
+
 	adc_key_recovery: adc-key-recovery {
 		compatible = "adc-keys";
 		io-channels = <&saradc 1>;
@@ -512,6 +516,23 @@ &pcie2x1l1 {
 	status = "okay";
 };
 
+&pcie2x1l2 {
+	/* on-board RTL8125 2.5GbE NIC */
+	pcie@0,0 {
+		reg = <0x400000 0 0 0 0>;
+		#address-cells = <3>;
+		#size-cells = <2>;
+		ranges;
+		device_type = "pci";
+		bus-range = <0x40 0x4f>;
+
+		rtl_eth0: ethernet@0,0 {
+			compatible = "pci10ec,8125";
+			reg = <0x410000 0 0 0 0>;
+		};
+	};
+};
+
 &pcie30phy {
 	/*
 	* Data lane mapping <1 3 2 4> = x1x1 x1x1 (bifurcation of both ports)

-- 
2.55.0

