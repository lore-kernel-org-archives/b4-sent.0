From: Ricardo Pardini <ricardo@pardini.net>
Date: Mon, 09 Nov 2026 13:32:19 +0100
Subject: [PATCH v6 4/6] arm64: dts: rockchip: describe PCIe RTL8125
 Ethernet on NanoPi R5S
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-rk3588-dts-rtl-eth-describe-dt-alias-v6-4-91f1efefba0b@pardini.net>
References: <20261109-rk3588-dts-rtl-eth-describe-dt-alias-v6-0-91f1efefba0b@pardini.net>
In-Reply-To: <20261109-rk3588-dts-rtl-eth-describe-dt-alias-v6-0-91f1efefba0b@pardini.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Sebastian Reichel <sebastian.reichel@collabora.com>, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1988; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=9Qdpul39fnmAarjmMc25c0t/ABrJ0d7zNPsppxOnomA=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBq8b1S7P1PUZdxHS2z05B6fB1U5Ut+tiA2yKi97
 SsemaqOQCSJATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCavG9UgAKCRA7Xj/jnsft
 6XRPB/973BDOvDuQjjo4E+7kB3Rtk8TZCHbP9KLq0ooMDtoPhj/HuVOL/3B8/c3V8iBSZLnzjyh
 WBokNxOVmJt2WdYrPcDt/yCkULPlBTBffjHCdylVZodF4z1QhyciKsUqFkUdGLm5HkVaP0VI2p8
 tn93L7W4jrMGlZD09xTd0+OVFQBV9hwZh4g4X7KhZoVdyIAThNR5LN2QnmRZdDCI8q28J0oAqBs
 /Je2wNpo2zvlvSqY1m5dZC+v6YnkIkerhtLIP8lmQlnxDUpxDIWM7fgLzR8ESOV0e748igqhNId
 ds9tATm4dG2oA1vYugT69W5uUo9getW6K9ilsfqLZEGc1SQS
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FriendlyElec NanoPi R5S carries two on-board Realtek RTL8125
NICs behind pcie2x1 and pcie3x1.

Describe the PCI function nodes and attach ethernet1/ethernet2
aliases, so that U-Boot's fdt_fixup_ethernet() can fill in their MAC
addresses from its eth1addr/eth2addr environment.

ethernet0 stays mapped to the on-SoC gmac0.

Note that mainline U-Boot's rockchip_setup_macaddr() derives only
ethaddr and eth1addr from the CPU ID, so ethernet2 only gets a stable
MAC if eth2addr is set in the U-Boot environment.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 arch/arm64/boot/dts/rockchip/rk3568-nanopi-r5s.dts | 30 ++++++++++++++++++++++
 1 file changed, 30 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3568-nanopi-r5s.dts b/arch/arm64/boot/dts/rockchip/rk3568-nanopi-r5s.dts
index 90ce6f0e1dcf..e588ee7fadc5 100644
--- a/arch/arm64/boot/dts/rockchip/rk3568-nanopi-r5s.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3568-nanopi-r5s.dts
@@ -15,6 +15,8 @@ / {
 
 	aliases {
 		ethernet0 = &gmac0;
+		ethernet1 = &rtl_eth1;
+		ethernet2 = &rtl_eth2;
 	};
 
 	gpio-keys {
@@ -107,6 +109,20 @@ &pcie2x1 {
 	num-lanes = <1>;
 	reset-gpios = <&gpio0 RK_PB6 GPIO_ACTIVE_HIGH>;
 	status = "okay";
+
+	pcie@0,0 {
+		reg = <0x000000 0 0 0 0>;
+		#address-cells = <3>;
+		#size-cells = <2>;
+		ranges;
+		device_type = "pci";
+		bus-range = <0x01 0x0f>;
+
+		rtl_eth1: ethernet@0,0 {
+			compatible = "pci10ec,8125";
+			reg = <0x010000 0 0 0 0>;
+		};
+	};
 };
 
 &pcie30phy {
@@ -119,6 +135,20 @@ &pcie3x1 {
 	reset-gpios = <&gpio0 RK_PA0 GPIO_ACTIVE_HIGH>;
 	vpcie3v3-supply = <&vcc3v3_pcie>;
 	status = "okay";
+
+	pcie@0,0 {
+		reg = <0x100000 0 0 0 0>;
+		#address-cells = <3>;
+		#size-cells = <2>;
+		ranges;
+		device_type = "pci";
+		bus-range = <0x11 0x1f>;
+
+		rtl_eth2: ethernet@0,0 {
+			compatible = "pci10ec,8125";
+			reg = <0x110000 0 0 0 0>;
+		};
+	};
 };
 
 &pcie3x2 {

-- 
2.47.3

