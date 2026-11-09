From: Ricardo Pardini <ricardo@pardini.net>
Date: Mon, 09 Nov 2026 13:32:16 +0100
Subject: [PATCH v6 1/6] arm64: dts: rockchip: describe PCIe RTL8125
 Ethernet on NanoPC-T6
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-rk3588-dts-rtl-eth-describe-dt-alias-v6-1-91f1efefba0b@pardini.net>
References: <20261109-rk3588-dts-rtl-eth-describe-dt-alias-v6-0-91f1efefba0b@pardini.net>
In-Reply-To: <20261109-rk3588-dts-rtl-eth-describe-dt-alias-v6-0-91f1efefba0b@pardini.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Sebastian Reichel <sebastian.reichel@collabora.com>, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1967; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=C8auy3c4isZ5XfXrCAmEL8F9N9P5Ye2UTKa9ViZULk4=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBq8b1R1mQNBqX9H00xyoLhCeSGvyRx4c7E3McBz
 Sujy0waKGWJATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCavG9UQAKCRA7Xj/jnsft
 6X0WB/9mVmK7vAE0Ed8SC14q/A6dWjN9RnozSKrufGdXyz9evMZqLZ0NPqJoK63wspfUJSOig7O
 LXhxdtKsLlMwYdf5qGSnmJ5CheTn4VxuMZwCBlsXNFLBQVUZS4vDytBzOqJfjMxpdTgw0426QMs
 3dWdvESPx3Lpne34k2HB/mVmUN/3Y4vuQAhtGtDLkyV5MRqvZ0lEwXbRGtLDF3q57kufDfXVPx4
 0l5KK1vdH64AplwFM4nXUsD6ePAHCk4PCFwg0a7VDLGTOk65pmtbUku56U9zzlsk4s55P4yWlq3
 jFaYVHV6DL5x1t+44mYOQe4QN7ev31fW7fIBGXq0elnvS/J4
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FriendlyElec NanoPC-T6 carries two on-board Realtek RTL8125 NICs
behind pcie2x1l0 and pcie2x1l2.

Describe the PCI function nodes and attach ethernet0/ethernet1
aliases, so that U-Boot's fdt_fixup_ethernet() can fill in their MAC
addresses from its ethaddr/eth1addr environment.

The labels follow the schematic and case markings: ETH1 (pcie2x1l2) is
rtl_eth1/ethernet0 and ETH2 (pcie2x1l0) is rtl_eth2/ethernet1.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi | 30 ++++++++++++++++++++++
 1 file changed, 30 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi
index 13be56af095b..18e427e94dcf 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi
@@ -20,6 +20,8 @@ / {
 	compatible = "friendlyarm,nanopc-t6", "rockchip,rk3588";
 
 	aliases {
+		ethernet0 = &rtl_eth1;
+		ethernet1 = &rtl_eth2;
 		mmc0 = &sdhci;
 		mmc1 = &sdmmc;
 	};
@@ -617,6 +619,20 @@ &pcie2x1l0 {
 	reset-gpios = <&gpio4 RK_PB3 GPIO_ACTIVE_HIGH>;
 	vpcie3v3-supply = <&vcc_3v3_s3>;
 	status = "okay";
+
+	pcie@0,0 {
+		reg = <0x200000 0 0 0 0>;
+		#address-cells = <3>;
+		#size-cells = <2>;
+		ranges;
+		device_type = "pci";
+		bus-range = <0x21 0x2f>;
+
+		rtl_eth2: ethernet@0,0 {
+			compatible = "pci10ec,8125";
+			reg = <0x210000 0 0 0 0>;
+		};
+	};
 };
 
 &pcie2x1l1 {
@@ -633,6 +649,20 @@ &pcie2x1l2 {
 	reset-gpios = <&gpio4 RK_PA4 GPIO_ACTIVE_HIGH>;
 	vpcie3v3-supply = <&vcc_3v3_s3>;
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

