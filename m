From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Sun, 15 Nov 2026 23:29:36 +0100
Subject: [PATCH 1/7] arm64: dts: amlogic: t7: Add ranges to periphs pinctrl
 node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-fix-amlogic-dt-warnings-v1-1-94cbd67a32ea@aliel.fr>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1247;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=8C9vs4EiUCOX/M/ReYqYBqsGbRJMK4l65oqDaqs3hj4=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9Yvo+TKBd5Trrkoms/NmDrPhu2C6aP6kCePFEVEU/r3p
 +x2c53eUcrCIMbFICumyNI/1/LEu8tHz3zdo54CM4eVCWQIAxenAEwkS4fhn8Lew7/3NBy8/f2l
 8bZJKrN2yLH9ca+Zs8lA/fy3RacCL9Yy/E+8n/k7yejnqe5Pa95zlavPc/ogtDZ6uXsDQ9B5HpO
 tc/gA
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Building the amlogic DTBs with W=1 reports the following warnings
for the periphs pinctrl node:

  amlogic-t7.dtsi:317.34-615.6: Warning (unit_address_vs_reg):
  /soc/bus@fe000000/pinctrl@4000: node has a unit name, but no reg
  or ranges property
  amlogic-t7.dtsi:317.34-615.6: Warning (simple_bus_reg):
  /soc/bus@fe000000/pinctrl@4000: missing or empty reg/ranges property

The pinctrl node has no reg property of its own, and its empty
"ranges;" does not describe which address space is translated to the
children.

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
index 52e106d931db..aacdd0db1ca2 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
@@ -318,7 +318,7 @@ periphs_pinctrl: pinctrl@4000 {
 				compatible = "amlogic,t7-periphs-pinctrl";
 				#address-cells = <2>;
 				#size-cells = <2>;
-				ranges;
+				ranges = <0x0 0x4000 0x0 0x4000 0x0 0x2e0>;
 
 				gpio: bank@4000 {
 					reg = <0x0 0x4000 0x0 0x0064>,

-- 
2.43.0

