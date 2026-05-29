From: Ricardo Pardini <ricardo@pardini.net>
Date: Fri, 29 May 2026 17:31:24 +0200
Subject: [PATCH v2 1/2] arm64: dts: rockchip: describe PCIe Ethernet
 controllers on NanoPC-T6
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260529-rk3588-dts-rtl-eth-describe-dt-alias-v2-1-49700248143f@pardini.net>
References: <20260529-rk3588-dts-rtl-eth-describe-dt-alias-v2-0-49700248143f@pardini.net>
In-Reply-To: <20260529-rk3588-dts-rtl-eth-describe-dt-alias-v2-0-49700248143f@pardini.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Sebastian Reichel <sebastian.reichel@collabora.com>, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1935; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=2PbNzuIjWPVmiNZE+VGSo9E5JFZNjeHgejELWlx8zA0=;
 b=owEBiQF2/pANAwAIATteP+Oex+3pAcsmYgBqGbFSPJENa/7M0hIsX8QZTVDKL5ybziDJ32Mcv
 0CUdDRXgfOJAU8EAAEIADkWIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCahmxUhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQO14/457H7enxQwf/f4efDbsFjixVgO0r+qirfD7qwBnLeRi
 +T+sYVCzBeLicYRWVses2atOVpWutNM6EPMYL9DcBsdrMuZkCRm7a2HVTQJ0Q1eqRP/qBi9RRvi
 pfqn6tfaduxxSvKMl1JI0/SGeYLTET2pQXF/aeQLjjl8Kr7ve6a0KDRo8l+loFH0BNWzQGcQleY
 oSL9DCAyMYAsTjatOIX6lhslGtVSToxmfezDpvQ9N8Ss+KF57Chv2zeAVuwQn61dlqj1KQXqsGA
 qKsdlfK1W2omSV0sY9Xa5mBakuqRl7zkPIT0BF9K98avb3nAXiTg461fGtw3X7DNMVLOqHrlWrg
 JEMpmisjdDA==
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FriendlyElec NanoPC-T6 carries two on-board Realtek RTL8125BG
(r8169 family, PCI 10ec:8125) NICs, each behind its own RK3588 PCIe2x1
controller (pcie2x1l0 and pcie2x1l2). Both host bridges were already
enabled by the board DT, but the Ethernet function nodes themselves
were not described, leaving the kernel without DT handles on the two
NICs.

Describe the fixed PCI function nodes and attach ethernet0/ethernet1
aliases to them.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi | 30 ++++++++++++++++++++++
 1 file changed, 30 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi
index 84b6b53f016ab..04c4479f08170 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi
@@ -20,6 +20,8 @@ / {
 	compatible = "friendlyarm,nanopc-t6", "rockchip,rk3588";
 
 	aliases {
+		ethernet0 = &rtl_eth0;
+		ethernet1 = &rtl_eth1;
 		mmc0 = &sdhci;
 		mmc1 = &sdmmc;
 	};
@@ -635,6 +637,20 @@ &pcie2x1l0 {
 	pinctrl-names = "default";
 	pinctrl-0 = <&pcie2_0_rst>;
 	status = "okay";
+
+	pcie@0,0 {
+		reg = <0x200000 0 0 0 0>;
+		#address-cells = <3>;
+		#size-cells = <2>;
+		ranges;
+		device_type = "pci";
+		bus-range = <0x20 0x2f>;
+
+		rtl_eth0: ethernet@0,0 {
+			compatible = "pci10ec,8125";
+			reg = <0x210000 0 0 0 0>;
+		};
+	};
 };
 
 &pcie2x1l1 {
@@ -651,6 +667,20 @@ &pcie2x1l2 {
 	pinctrl-names = "default";
 	pinctrl-0 = <&pcie2_2_rst>;
 	status = "okay";
+
+	pcie@0,0 {
+		reg = <0x400000 0 0 0 0>;
+		#address-cells = <3>;
+		#size-cells = <2>;
+		ranges;
+		device_type = "pci";
+		bus-range = <0x40 0x4f>;
+
+		rtl_eth1: ethernet@0,0 {
+			compatible = "pci10ec,8125";
+			reg = <0x410000 0 0 0 0>;
+		};
+	};
 };
 
 &pcie30phy {

-- 
2.54.0

