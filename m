From: Ricardo Pardini <ricardo@pardini.net>
Date: Mon, 09 Nov 2026 13:32:17 +0100
Subject: [PATCH v6 2/6] arm64: dts: rockchip: describe PCIe RTL8125
 Ethernet on ROCK 5 family
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-rk3588-dts-rtl-eth-describe-dt-alias-v6-2-91f1efefba0b@pardini.net>
References: <20261109-rk3588-dts-rtl-eth-describe-dt-alias-v6-0-91f1efefba0b@pardini.net>
In-Reply-To: <20261109-rk3588-dts-rtl-eth-describe-dt-alias-v6-0-91f1efefba0b@pardini.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Sebastian Reichel <sebastian.reichel@collabora.com>, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2524; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=5FUQR0rfH+5npztwgihS2KzQbqIydyXcLzR1mZxE4zY=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBq8b1Rqz7/SAbQQrbe2CSUO+hzIC8QLvggk98+u
 ViJ9qqcmPCJATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCavG9UQAKCRA7Xj/jnsft
 6akgCACPf5E8p9CxpNI6k7h61C2X8pqJyIjbMbEgil14qH4Y6PD4y+iOQ10b0ZXhptGKo1hMiH5
 B4zpkjSDnl7FXeg5KC47PJkceMtW1py9xJVtvGLFLn8TIt9XuRLpn+sFZlPRln4GcRfMYJFHaTN
 rI9Uc3K/mPRqtXYNyGGp73dWRLscyYr3+vcB70l1MT0UVRNwEHwGahCVwkVAjxMGw2eXN4aN99o
 dRRr6D00wYnQj0anuovVoRLfsywaLaeghrDeRwbMTpw6RbTydFL01bAQlcx28s+cXaNOuORvZNE
 e15Orv1Kiyc3VDuNagGttKp2MjNfO7hbfRtoM31rHN4ZCfcr
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Radxa ROCK 5B, 5B+ and 5T carry an on-board Realtek RTL8125 NIC
behind pcie2x1l2; the ROCK 5T has a second one behind pcie2x1l1.

Describe the PCI function nodes and attach ethernet0 (and, on the
ROCK 5T, ethernet1) aliases, so that U-Boot's fdt_fixup_ethernet() can
fill in their MAC addresses from its ethaddr/eth1addr environment.

The shared NIC goes in rk3588-rock-5b-5bp-5t.dtsi, the ROCK 5T's second
NIC in rk3588-rock-5t.dts.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 .../arm64/boot/dts/rockchip/rk3588-rock-5b-5bp-5t.dtsi | 15 +++++++++++++++
 arch/arm64/boot/dts/rockchip/rk3588-rock-5t.dts        | 18 ++++++++++++++++++
 2 files changed, 33 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-rock-5b-5bp-5t.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-rock-5b-5bp-5t.dtsi
index b8d90936fc20..e8a3eb33e402 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-rock-5b-5bp-5t.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-rock-5b-5bp-5t.dtsi
@@ -10,6 +10,7 @@
 
 / {
 	aliases {
+		ethernet0 = &rtl_eth0;
 		mmc0 = &sdhci;
 		mmc1 = &sdmmc;
 		mmc2 = &sdio;
@@ -488,6 +489,20 @@ &pcie2x1l2 {
 	reset-gpios = <&gpio3 RK_PB0 GPIO_ACTIVE_HIGH>;
 	vpcie3v3-supply = <&vcc3v3_pcie2x1l2>;
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
 
 &pcie30phy {
diff --git a/arch/arm64/boot/dts/rockchip/rk3588-rock-5t.dts b/arch/arm64/boot/dts/rockchip/rk3588-rock-5t.dts
index 425036146b6d..b1a3e4b2165f 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-rock-5t.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3588-rock-5t.dts
@@ -8,6 +8,10 @@ / {
 	model = "Radxa ROCK 5T";
 	compatible = "radxa,rock-5t", "rockchip,rk3588";
 
+	aliases {
+		ethernet1 = &rtl_eth1;
+	};
+
 	analog-sound {
 		compatible = "audio-graph-card";
 		label = "rk3588-es8316";
@@ -76,6 +80,20 @@ &pcie2x1l1 {
 	reset-gpios = <&gpio4 RK_PA2 GPIO_ACTIVE_HIGH>;
 	vpcie3v3-supply = <&vcc3v3_pcie2x1l1>;
 	status = "okay";
+
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
 };
 
 &pcie30phy {

-- 
2.47.3

