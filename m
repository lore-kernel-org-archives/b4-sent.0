From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Sun, 11 Oct 2026 21:31:40 +0300
Subject: [PATCH v2 1/2] arm64: dts: meson-gxbb-odroidc2: read the Ethernet
 MAC address from eFuse
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-odroidc2-dts-v2-1-a3a4a752f2ab@gmail.com>
References: <20261011-odroidc2-dts-v2-0-a3a4a752f2ab@gmail.com>
In-Reply-To: <20261011-odroidc2-dts-v2-0-a3a4a752f2ab@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791743499; l=1642;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=PsqvKgTZVmwNJ/75hqMs5lzb8aAfYpplhUuYDuvqmXQ=;
 b=gqt5Pn5RDRBctoPQT0FhhHkMrtLZS+rS8WrpKx8CGMCHl/WC44eGIvR3VU++jAeOdW0x/OiO6
 8Ycvr/c7rGFAeDjY/tYKXbv/t7HctodE4HL9+Mtg11QzpF0JfGbz0R9
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The vendor programs a unique factory MAC address into the SoC eFuse at
offset 0x34, where meson-gx.dtsi already describes the eth_mac nvmem
cell.  Reference the cell from the Ethernet controller so the kernel
picks up the factory address itself instead of depending on the
bootloader to populate local-mac-address, or falling back to a random
one when it does not.

The cell is 16 bytes long in meson-gx.dtsi, while
of_get_mac_address_nvmem() only accepts a cell of exactly ETH_ALEN
bytes, so narrow it to the 6 bytes of the address for this board.

Tested on an ODROID-C2 with the bootloader's MAC fixup out of the way
(ethernet0 alias removed from the DTB): with the 16-byte cell the
driver falls back to a random address, with the 6-byte cell eth0 comes
up with the factory address from the eFuse.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts b/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts
index 5943bc810..3b74528ef 100644
--- a/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts
+++ b/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts
@@ -223,6 +223,10 @@ &cec_AO {
 	hdmi-phandle = <&hdmi_tx>;
 };
 
+&eth_mac {
+	reg = <0x34 0x6>;
+};
+
 &ethmac {
 	status = "okay";
 	pinctrl-0 = <&eth_rgmii_pins>;
@@ -230,6 +234,9 @@ &ethmac {
 	phy-handle = <&eth_phy0>;
 	phy-mode = "rgmii";
 
+	nvmem-cells = <&eth_mac>;
+	nvmem-cell-names = "mac-address";
+
 	amlogic,tx-delay-ns = <2>;
 
 	mdio {

-- 
2.53.0

