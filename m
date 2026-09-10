From: Ricardo Pardini <ricardo@pardini.net>
Date: Thu, 10 Sep 2026 22:07:57 +0200
Subject: [PATCH v5 7/7] arm64: dts: rockchip: describe PCIe RTL8125
 Ethernet on ROCK 5 ITX
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260910-rk3588-dts-rtl-eth-describe-dt-alias-v5-7-c1b9e5f10cd6@pardini.net>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1909; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=6JENscbgGnnWW/4PaIbc3X/OTv8wHFKHVCvXFVsCaGI=;
 b=owGbwMvMwMFoHWf/eN7xty8ZT6slMWQt5lM5Z/zure0WD5bAba2XA91+FL/82syq2fdTRU/S1
 OhlhOifTkZ/FgZGDgZLMUWWNRLKPN/Wvzp1x6NjMswgViaQKdIiDQxAwMLAl5uYV2qkY6Rnqm2o
 Z2ikY6BjzMDFKQBTnXaWg6GVjcWSZZrtF86duUf1exXWOm3Ze1yT98wrA/WzkXNr87relftXt9U
 tDJIucr7PmfsnZvlKW8elQk1/rrMXXjmTZnbuhoDaZtNzdx0UOh0shY2ML0yZGxFzpCHxXY1Ua3
 ifw5cmo87VT1vffprCfOZpc2eO4Iy8b9HznTOKN7IyhLZMauwwO7Qla5qW/8my3weNpNcZPD2z3
 2GeoGW5X7juh6YehrULPG8ZTDa1kBLuOTCtJXxphtXGK9sknP9eUtTz/6FxuHPqTQEudfHDiU8r
 Ln851t1dev2nxaJveZ86fy/ii47Ksunoepd23kwi+YW9b3C02s+m1QeyJprMPMD6cMfR1jM+0wy
 EWSI1AQ==
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Radxa ROCK 5 ITX carries two on-board Realtek RTL8125 NICs behind
pcie2x1l1 and pcie2x1l2.

Describe the fixed function nodes and attach ethernet0/ethernet1
aliases, so that U-Boot's fdt_fixup_ethernet() can inject mac-address
properties from its ethaddr/eth1addr env, for stable MACs across
boots that both U-Boot and the kernel agree on.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 arch/arm64/boot/dts/rockchip/rk3588-rock-5-itx.dts | 30 ++++++++++++++++++++++
 1 file changed, 30 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-rock-5-itx.dts b/arch/arm64/boot/dts/rockchip/rk3588-rock-5-itx.dts
index 6f25e088f3189..f1d6647c57bf9 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-rock-5-itx.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3588-rock-5-itx.dts
@@ -20,6 +20,8 @@ / {
 	compatible = "radxa,rock-5-itx", "rockchip,rk3588";
 
 	aliases {
+		ethernet0 = &rtl_eth0;
+		ethernet1 = &rtl_eth1;
 		mmc0 = &sdhci;
 		mmc1 = &sdmmc;
 		mmc2 = &sdio;
@@ -631,6 +633,20 @@ &pcie2x1l1 {
 	reset-gpios = <&gpio4 RK_PA2 GPIO_ACTIVE_HIGH>;
 	vpcie3v3-supply = <&vcc3v3_lan>;
 	status = "okay";
+
+	pcie@0,0 {
+		reg = <0x300000 0 0 0 0>;
+		#address-cells = <3>;
+		#size-cells = <2>;
+		ranges;
+		device_type = "pci";
+		bus-range = <0x30 0x3f>;
+
+		rtl_eth0: ethernet@0,0 {
+			compatible = "pci10ec,8125";
+			reg = <0x310000 0 0 0 0>;
+		};
+	};
 };
 
 /* RTL8125B_2 */
@@ -640,6 +656,20 @@ &pcie2x1l2 {
 	reset-gpios = <&gpio3 RK_PB0 GPIO_ACTIVE_HIGH>;
 	vpcie3v3-supply = <&vcc3v3_lan_phy2>;
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
2.55.0

