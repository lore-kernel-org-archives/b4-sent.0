From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Sun, 15 Nov 2026 23:29:39 +0100
Subject: [PATCH 4/7] arm64: dts: amlogic: g12: Add ranges to periphs
 pinctrl node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-fix-amlogic-dt-warnings-v1-4-94cbd67a32ea@aliel.fr>
References: <20261115-fix-amlogic-dt-warnings-v1-0-94cbd67a32ea@aliel.fr>
In-Reply-To: <20261115-fix-amlogic-dt-warnings-v1-0-94cbd67a32ea@aliel.fr>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2669;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=t9HskvsPsw4IgT4qLZYW9JrAwDATbsMB7Lv8ZE1CwUo=;
 b=kA0DAAoWKo0VA3vnMSIByyZiAGr6MmejtwJnEQg19pSjQcrE9LORMtQgCVQ8eJJYKC/cgelkH
 4h1BAAWCgAdFiEEj505yO7Txcz1vCdkKo0VA3vnMSIFAmr6MmcACgkQKo0VA3vnMSLC3gEA9d0n
 NYxml+vTlIsJDpaiVZ28E7ZQUdmyMY6DixkeXt8BAPAbiw6WcN5G9J1pBnwxCVUagh8fWWTjj6L
 0FOhCnR8N
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Building the amlogic DTBs with W=1 reports the following warnings
for the periphs pinctrl node:

  meson-g12-common.dtsi:271.33-1554.7: Warning (unit_address_vs_reg):
  /soc/bus@ff600000/bus@34400/pinctrl@40: node has a unit name, but no
  reg or ranges property
  meson-g12-common.dtsi:1768.27-2040.6: Warning (unit_address_vs_reg):
  /soc/bus@ff800000/pinctrl@14: node has a unit name, but no reg
  or ranges property
  meson-g12-common.dtsi:271.33-1554.7: Warning (simple_bus_reg):
  /soc/bus@ff600000/bus@34400/pinctrl@40: missing or empty reg/ranges
  property
  meson-g12-common.dtsi:1768.27-2040.6: Warning (simple_bus_reg):
  /soc/bus@ff800000/pinctrl@14: missing or empty reg/ranges property
  meson-g12-common.dtsi:2239.23-2279.6: Warning
  (avoid_unnecessary_addr_size): /soc/bus@ffd00000/dsi@7000:
  unnecessary #address-cells/#size-cells without "ranges", "dma-ranges"
  or child "reg" or "ranges" property

The pinctrl node has no reg property of its own, and its empty
"ranges;" does not describe which address space is translated to the
children

  /soc/bus@ffd00000/dsi@7000: unnecessary #address-cells/#size-cells
  without "ranges", "dma-ranges" or child "reg" or "ranges" property

The DSI controller node has no child nodes with a reg property,
so #address-cells and #size-cells serve no purpose. Remove them.

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 arch/arm64/boot/dts/amlogic/meson-g12-common.dtsi | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/amlogic/meson-g12-common.dtsi b/arch/arm64/boot/dts/amlogic/meson-g12-common.dtsi
index 3135566df880..434df25f6247 100644
--- a/arch/arm64/boot/dts/amlogic/meson-g12-common.dtsi
+++ b/arch/arm64/boot/dts/amlogic/meson-g12-common.dtsi
@@ -272,7 +272,7 @@ periphs_pinctrl: pinctrl@40 {
 					compatible = "amlogic,meson-g12a-periphs-pinctrl";
 					#address-cells = <2>;
 					#size-cells = <2>;
-					ranges;
+					ranges = <0x0 0x40 0x0 0x40 0x0 0x31c>;
 
 					gpio: bank@40 {
 						reg = <0x0 0x40  0x0 0x4c>,
@@ -1769,7 +1769,7 @@ ao_pinctrl: pinctrl@14 {
 				compatible = "amlogic,meson-g12a-aobus-pinctrl";
 				#address-cells = <2>;
 				#size-cells = <2>;
-				ranges;
+				ranges = <0x0 0x14 0x0 0x14 0x0 0x24>;
 
 				gpio_ao: bank@14 {
 					reg = <0x0 0x14 0x0 0x8>,
@@ -2247,8 +2247,6 @@ mipi_dsi: dsi@7000 {
 				clock-names = "pclk", "bit", "px";
 				phys = <&mipi_dphy>;
 				phy-names = "dphy";
-				#address-cells = <1>;
-				#size-cells = <0>;
 				status = "disabled";
 
 				assigned-clocks = <&clkc CLKID_MIPI_DSI_PXCLK_SEL>,

-- 
2.43.0

