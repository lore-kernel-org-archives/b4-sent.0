From: Ricardo Pardini <ricardo@pardini.net>
Date: Thu, 10 Sep 2026 22:07:52 +0200
Subject: [PATCH v5 2/7] arm64: dts: rockchip: describe PCIe RTL8125
 Ethernet on NanoPC-T6
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260910-rk3588-dts-rtl-eth-describe-dt-alias-v5-2-c1b9e5f10cd6@pardini.net>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1920; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=i4GeIrJloVMIhPqbv8MMmvK6rUkQxMcuRPKHm4uxbIo=;
 b=owGbwMvMwMFoHWf/eN7xty8ZT6slMWQt5lO5ZsyY6XfpwNOtGY8b3r97ESAekVrkf1n+oa+df
 nfqdM/znYz+LAyMHAyWYoosaySUeb6tf3XqjkfHZJhBrEwgU6RFGhiAgIWBLzcxr9RIx0jPVNtQ
 z9BIx0DHmIGLUwCm2iuB/X9Gv4pQKa9F9ddaK/7/iqrdta7LQhiP/p+/qtJ8+e5Jx3TqHGK3Rl3
 d79c99TlbyU3eWFOGB3u/Ji/PN3q6bHn26nLpdTPuKTDUWYX5TQlkjnmzNrO7Rnjjkz/pRu1dGp
 rfw6Luv3/DXm4j/qfhevGWA1tSmb+wNkbdyhWfJTZZoM5YvMko0ebcpmxl07NufQKs3w++fPBmw
 eJDe+vlGtk4VoUqrF8tuWJFusGixAc8Ncb5kXM+XX1wyMfc490qvulWj/zv24WzX482/3yydplk
 0uJHwnrNqe+SNp1avG1dgG7jwvyrR89wRxc2P9Zkd174OyysSCxAOSopM6YpIdh15SZ/DvVjyf3
 XrOqqAQ==
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FriendlyElec NanoPC-T6 carries two on-board Realtek RTL8125 NICs
behind pcie2x1l0 and pcie2x1l2.

Describe the fixed function nodes and attach ethernet0/ethernet1
aliases, so that U-Boot's fdt_fixup_ethernet() can fill in the MAC
from its ethaddr/eth1addr env. The on-NIC EEPROMs on this board are
not pre-programmed with a unique MAC, so this gives a stable MAC
across boots that both U-Boot and the kernel agree on.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi | 30 ++++++++++++++++++++++
 1 file changed, 30 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi
index cfdb5c13f8606..550358a756618 100644
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
@@ -644,6 +646,20 @@ &pcie2x1l0 {
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
+		bus-range = <0x21 0x2f>;
+
+		rtl_eth0: ethernet@0,0 {
+			compatible = "pci10ec,8125";
+			reg = <0x210000 0 0 0 0>;
+		};
+	};
 };
 
 &pcie2x1l1 {
@@ -660,6 +676,20 @@ &pcie2x1l2 {
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
2.55.0

