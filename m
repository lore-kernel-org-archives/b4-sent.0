From: Ricardo Pardini <ricardo@pardini.net>
Date: Mon, 25 May 2026 12:12:12 +0200
Subject: [PATCH] arm64: dts: rockchip: describe PCIe Ethernet controllers
 on NanoPC-T6
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260525-rk3588-dts-rtl-eth-describe-dt-alias-v1-1-a6fcda563ac7@pardini.net>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXNSw7CMAxF0a1UHmMpCQ2N2ApikI+hhqogO6BKV
 fdOgOF5g/tWUBImhWO3gtCblR9zg911kMc4Xwm5NIMz7mC861Huex8ClqoodUKqIxbSLJyojRg
 njorZUrFhSEP2BlrqKXTh5XdzOv+tr3SjXL9t2LYPxz+gY4gAAAA=
X-Change-ID: 20260524-rk3588-dts-rtl-eth-describe-dt-alias-c1ed187b7c50
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Sebastian Reichel <sebastian.reichel@collabora.com>, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3532; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=ATDxgV+aVRYA1qwVl5QQNVkoTUqIMI+aNMm96MahMCc=;
 b=owEBiQF2/pANAwAIATteP+Oex+3pAcsmYgBqFCB9KNIKy16b9ZOZvEfenPlRdjMemK/hkmuEK
 v7F67/+EWSJAU8EAAEIADkWIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCahQgfRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQO14/457H7ekCeAgAhETNghtgglmhDGNt9QFfL3n73Tw10Gc
 FzHh8hLZmz5mFgbpWN31ixqkFdOtvj6xz4ba3rSh/T0zezG3EObvlNMtmyPe9YfaDtOtSndYlMZ
 4mKo83ioOZWwzJJMxuXdWWxe6siI7IWEQ7Zz0861Tf1qDaGyeDMj45dKMZq5bFhpsg8n619HJNd
 IVF7Mhc9uWFnTmE3V0xxaVl2sOc60rjztOgkT8EgUH9gEhk9ygegkxGOPs+jDIUDvYo+frdpe5c
 UVuwbJ6ax1BCseH9JqPOpLh38agQGmxWxXQBXlNAtVA2GEz8yfLj/qLIlfgjz89zkNa9C6f9q+F
 u96ZM+5/MSg==
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FriendlyElec NanoPC-T6 carries two on-board Realtek RTL8125BG
(r8169 family, PCI 10ec:8125) NICs, each behind its own RK3588 PCIe2x1
controller (pcie2x1l1 and pcie2x1l2). Both host bridges were already
enabled by the board DT, but the Ethernet function nodes themselves
were not described, leaving the kernel without DT handles on the two
NICs.

Describe the fixed PCI function nodes and attach ethernet0/ethernet1
aliases to them.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
This describes the two on-board Realtek RTL8125BG PCIe Ethernet
controllers on the FriendlyElec NanoPC-T6 (RK3588) board and aliases
them to ethernet0/ethernet1.

Many Rockchip boards have on-board RTL8125 PCIe NICs, wired to
pcie2x1l1 and pcie2x1l2. The controllers were already enabled in the
board DT, but the Ethernet function nodes themselves are not
described, so the kernel (and u-boot) has no DT handle on the NICs.

Adding the function nodes lets us:
- expose stable ethernet0/ethernet1 aliases for the two NICs, the
  same way other rk3588 boards alias their GMAC interfaces; and
- let U-Boot's fdt_fixup_ethernet() patch mac-address properties in
  at boot time from its ethaddr/eth1addr environment - useful on
  boards (like this one) whose on-NIC EEPROM is not pre-programmed
  with a unique MAC. The kernel and U-Boot then agree on the MAC,
  which matters for network-boot setups.

Checkpatch warnings:
-  WARNING: DT compatible string "pci10ec,8125" appears un-documented
-  WARNING: DT compatible string vendor "pci10ec" appears un-documented
Both are expected. "pciVVVV,DDDD" is the Open Firmware PCI Bus
Binding spelling, where VVVV/DDDD are the PCI vendor and device IDs
allocated by the PCI-SIG (10ec = Realtek, 8125 = RTL8125). It is not a
DT vendor prefix.

If this is seen as a good thing, it would apply very similarly to
the Radxa Rock 5 series and others.
---
 arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi | 30 ++++++++++++++++++++++
 1 file changed, 30 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi
index 84b6b53f016ab..5d28c74847c58 100644
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
@@ -643,6 +645,20 @@ &pcie2x1l1 {
 	pinctrl-names = "default";
 	pinctrl-0 = <&pcie2_1_rst>;
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
 
 &pcie2x1l2 {
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

---
base-commit: e7ae89a0c97ce2b68b0983cd01eda67cf373517d
change-id: 20260524-rk3588-dts-rtl-eth-describe-dt-alias-c1ed187b7c50

Best regards,
--  
Ricardo Pardini <ricardo@pardini.net>

