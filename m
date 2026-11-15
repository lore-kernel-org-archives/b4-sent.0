From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Sun, 15 Nov 2026 23:29:37 +0100
Subject: [PATCH 2/7] arm64: dts: amlogic: a1: Add ranges to periphs pinctrl
 node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-fix-amlogic-dt-warnings-v1-2-94cbd67a32ea@aliel.fr>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1233;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=oskDA3lqc2OXkomXgBBue1EJY5c1W7W4Jw8yaVrxwc8=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9Yvo5RVdYkvJ4tUbw67vWqhh93cb+1r5UT47rxjZMpg2
 T1/5Yt3HaUsDGJcDLJiiiz9cy1PvLt89MzXPeopMHNYmUCGMHBxCsBEDM8xMrxjb5z2kPWilo1Y
 f3tE0mJ7l2mhck3stosrZJb+utc+k4Hhf+CBy0s3WEb9X5u3ONJ+r9ayk5c2egcd3n5p9rxkmzu
 SArwA
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Building the amlogic DTBs with W=1 reports the following warnings
for the periphs pinctrl node:

  meson-a1.dtsi:131.33-483.6: Warning (unit_address_vs_reg):
  /soc/bus@fe000000/pinctrl@400: node has a unit name, but no
  reg or ranges property
  meson-a1.dtsi:131.33-483.6: Warning (simple_bus_reg):
  /soc/bus@fe000000/pinctrl@400: missing or empty reg/ranges property

The pinctrl node has no reg property of its own, and its empty
"ranges;" does not describe which address space is translated to the
children.

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 arch/arm64/boot/dts/amlogic/meson-a1.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/amlogic/meson-a1.dtsi b/arch/arm64/boot/dts/amlogic/meson-a1.dtsi
index 6f6a6145cba1..f59495c1885a 100644
--- a/arch/arm64/boot/dts/amlogic/meson-a1.dtsi
+++ b/arch/arm64/boot/dts/amlogic/meson-a1.dtsi
@@ -132,7 +132,7 @@ periphs_pinctrl: pinctrl@400 {
 				compatible = "amlogic,meson-a1-periphs-pinctrl";
 				#address-cells = <2>;
 				#size-cells = <2>;
-				ranges;
+				ranges = <0x0 0x400 0x0 0x400 0x0 0x198>;
 
 				gpio: bank@400 {
 					reg = <0x0 0x0400 0x0 0x003c>,

-- 
2.43.0

