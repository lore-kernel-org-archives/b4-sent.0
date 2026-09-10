From: Ricardo Pardini <ricardo@pardini.net>
Date: Thu, 10 Sep 2026 22:07:55 +0200
Subject: [PATCH v5 5/7] arm64: dts: rockchip: describe PCIe RTL8125
 Ethernet on NanoPi R5S
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260910-rk3588-dts-rtl-eth-describe-dt-alias-v5-5-c1b9e5f10cd6@pardini.net>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1905; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=d/VG2/chohE7PySQEsZ1Vo0STaN5v4pNoZsUTpZ3M1g=;
 b=owEBiQF2/pANAwAIATteP+Oex+3pAcsmYgBqow4kCugUP6LbCtGv7c4s7FXQL+f7aE/8PYW7I
 E480QLNJCKJAU8EAAEIADkWIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCaqMOJBsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQO14/457H7emkLQf+KulPfWTXTsdcSqcM9zVk/ei8U+8OWfF
 AuHnpb6xyjHrTVzhYS7+yYYGaCBe1zStZnnpXVrBS4uAL9qIIOFhHubnjrnT0pbSdVTfOjCT+/O
 0VDl9eRdzW4NTgH48xgZu7Rj4UgcxkDUdtbq/cXVS9V7k3CTKwzRnUUZ3X4YyzDfUm7sMrrJIo4
 BmOLR41o1gV24d7Ys1mzRY/3A6s/Xs/iNkjjYDpRI/UElaufCYs/3AzlM6wYd79jDnavqqbdcxt
 dWY4FcaWTtwFiTZFLiqymZrUa2YqlBCiY9XCGKbdBurcK8MNNj/IsgGjEMwF/Vle2Qt8iiVrL5L
 GsXhGoJpixQ==
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FriendlyElec NanoPi R5S (rk3568) carries two on-board Realtek
RTL8125 NICs behind pcie2x1 and pcie3x1, alongside the existing gmac0
RGMII PHY.

Describe the fixed function nodes and attach ethernet1/ethernet2
aliases (ethernet0 stays mapped to gmac0), so that U-Boot's
fdt_fixup_ethernet() can inject mac-address properties from its
eth1addr/eth2addr env, for stable MACs across boots that both U-Boot
and the kernel agree on.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 arch/arm64/boot/dts/rockchip/rk3568-nanopi-r5s.dts | 30 ++++++++++++++++++++++
 1 file changed, 30 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3568-nanopi-r5s.dts b/arch/arm64/boot/dts/rockchip/rk3568-nanopi-r5s.dts
index 90ce6f0e1dcff..9ed11663c31c9 100644
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
+		bus-range = <0x00 0x0f>;
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
+		bus-range = <0x10 0x1f>;
+
+		rtl_eth2: ethernet@0,0 {
+			compatible = "pci10ec,8125";
+			reg = <0x110000 0 0 0 0>;
+		};
+	};
 };
 
 &pcie3x2 {

-- 
2.55.0

