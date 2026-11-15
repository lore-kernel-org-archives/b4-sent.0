From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Sun, 15 Nov 2026 23:29:38 +0100
Subject: [PATCH 3/7] arm64: dts: amlogic: axg: Add ranges to periphs
 pinctrl node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-fix-amlogic-dt-warnings-v1-3-94cbd67a32ea@aliel.fr>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1603;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=t3oox1TjzpL1ctm6S+5Ku7TzDmvGbGuVy9dMZYSp6B4=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9Yvo9RuaxaGU1OPHnxSk9zGLPtc4/4xXUeuEBPNCeGOe
 2xMby/vKGVhEONikBVTZOmfa3ni3eWjZ77uUU+BmcPKBDKEgYtTACZy9zXDP5PlYj9CXxlM9ctY
 n3T17frIsFN3ms5vMHvW3TubgbNSuIDhf/qOHJ6Szru3N04UcvbYrNreemFpS3e+8QyXnnN/tx+
 bxAYA
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

  meson-axg.dtsi:360.33-1262.6: Warning (unit_address_vs_reg):
  /soc/bus@ff634000/pinctrl@480: node has a unit name, but no reg
  or ranges property
  meson-axg.dtsi:1609.30-1716.6: Warning (unit_address_vs_reg):
  /soc/bus@ff800000/pinctrl@14: node has a unit name, but no reg
  or ranges property
  meson-axg.dtsi:360.33-1262.6: Warning (simple_bus_reg):
  /soc/bus@ff634000/pinctrl@480: missing or empty reg/ranges property
  meson-axg.dtsi:1609.30-1716.6: Warning (simple_bus_reg):
  /soc/bus@ff800000/pinctrl@14: missing or empty reg/ranges property

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 arch/arm64/boot/dts/amlogic/meson-axg.dtsi | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/amlogic/meson-axg.dtsi b/arch/arm64/boot/dts/amlogic/meson-axg.dtsi
index 5b8ef98f6d03..dc932629c92c 100644
--- a/arch/arm64/boot/dts/amlogic/meson-axg.dtsi
+++ b/arch/arm64/boot/dts/amlogic/meson-axg.dtsi
@@ -361,7 +361,8 @@ pinctrl_periphs: pinctrl@480 {
 				compatible = "amlogic,meson-axg-periphs-pinctrl";
 				#address-cells = <2>;
 				#size-cells = <2>;
-				ranges;
+				ranges = <0x0 0x480 0x0 0x480 0x0 0xb4>,
+					 <0x0 0x430 0x0 0x430 0x0 0x3c>;
 
 				gpio: bank@480 {
 					reg = <0x0 0x00480 0x0 0x40>,
@@ -1610,7 +1611,7 @@ pinctrl_aobus: pinctrl@14 {
 				compatible = "amlogic,meson-axg-aobus-pinctrl";
 				#address-cells = <2>;
 				#size-cells = <2>;
-				ranges;
+				ranges = <0x0 0x14 0x0 0x14 0x0 0x1c>;
 
 				gpio_ao: bank@14 {
 					reg = <0x0 0x00014 0x0 0x8>,

-- 
2.43.0

