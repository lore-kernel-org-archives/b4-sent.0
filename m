From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Sun, 15 Nov 2026 23:29:42 +0100
Subject: [PATCH 7/7] arm64: dts: amlogic: s4: Add ranges to periphs pinctrl
 node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-fix-amlogic-dt-warnings-v1-7-94cbd67a32ea@aliel.fr>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1092;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=nP0f/fVYX53MqrUgOulbTSDvdQTy7E12SUoVJKP75i4=;
 b=kA0DAAoWKo0VA3vnMSIByyZiAGr6MmujoGLPbGR+bM44AFsm7XzZ9IeDH00NoszHjeuR2WzUN
 Yh1BAAWCgAdFiEEj505yO7Txcz1vCdkKo0VA3vnMSIFAmr6MmsACgkQKo0VA3vnMSIzZAEA2ahq
 lVPO8afaYdsMfkVliu59cZ9V6ojK/X5rI8G/O70A/A7cFo/zf8BlNzxcqAx58WmtK4JD1fyzw1N
 Zwq+jrmMI
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Building the amlogic DTBs with W=1 reports the following warnings
for the periphs pinctrl node:

  meson-s4.dtsi:162.34-622.6: Warning (unit_address_vs_reg):
  /soc/bus@fe000000/pinctrl@4000: node has a unit name, but no reg
  or ranges property
  meson-s4.dtsi:162.34-622.6: Warning (simple_bus_reg):
  /soc/bus@fe000000/pinctrl@4000: missing or empty reg/ranges property

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 arch/arm64/boot/dts/amlogic/meson-s4.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/amlogic/meson-s4.dtsi b/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
index 2a6fbd530836..a0b47c505ab5 100644
--- a/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
+++ b/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
@@ -163,7 +163,7 @@ periphs_pinctrl: pinctrl@4000 {
 				compatible = "amlogic,meson-s4-periphs-pinctrl";
 				#address-cells = <2>;
 				#size-cells = <2>;
-				ranges;
+				ranges = <0x0 0x4000 0x0 0x4000 0x0 0x2e0>;
 
 				gpio: bank@4000 {
 					reg = <0x0 0x4000 0x0 0x004c>,

-- 
2.43.0

