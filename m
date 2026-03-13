From: Michael Riesch <michael.riesch@collabora.com>
Date: Fri, 13 Mar 2026 16:53:29 +0100
Subject: [PATCH] arm64: dts: rockchip: enable vicap dvp on wolfvision pf5
 io expander
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260313-wv-io-expander-vicap-v1-1-11001fb3b744@collabora.com>
X-B4-Tracking: v=1; b=H4sIAPgytGkC/x2N0QrCMAwAf2Xk2cDWUQV/RXxI0+gCIyst1sHYv
 xt8vIPjDmhSVRrchwOqdG26mcN0GYAXsregZmcIY7iO8zTjt6NuKHshy1KxK1PBEGOSwJJvkcH
 TRE0wVTJePLbPurosVV66/1+P53n+AJmGMlJ7AAAA
To: Gerald Loacker <gerald.loacker@wolfvision.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Michael Riesch <michael.riesch@collabora.com>, 
 Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773417210; l=2200;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=AxZQMPkNnnwsrhXc1fCRiYhuc1Gbnk7fB2Vzh07TFp8=;
 b=uWjRu68zw60pg4cPIDcmL5g1Cl+/n8xiSkYermWSAGsa1U/hZf9rlWQhditBQT7OFRSZByQr7
 SwDO3yO+JgdCXu61Ekdyr/KFcG789qndRQSdTcDnERwYPo0k/KLE39Z
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Digital Video Port (DVP, the 16-bit variant) of the RK3568 VICAP
is broken out to the PF5 mainboard expansion header.
Enable it in the device tree overlay for the WolfVision PF5 IO
Expander board.

Signed-off-by: Michael Riesch <michael.riesch@wolfvision.net>
Reviewed-by: Gerald Loacker <gerald.loacker@wolfvision.net>
Tested-by: Gerald Loacker <gerald.loacker@wolfvision.net>
Reviewed-by: Bryan O'Donoghue <bryan.odonoghue@linaro.org>
Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
Habidere,

This patch was skipped when the RK3568 series was applied, as the
MEDIA_PCLK_SAMPLE_DUAL_EDGE definition was introduced in the very same
series.

With the definition mainline for two kernel releases now, it should be
safe to merge this device tree modification.

Thanks in advance!
---
 .../rockchip/rk3568-wolfvision-pf5-io-expander.dtso  | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3568-wolfvision-pf5-io-expander.dtso b/arch/arm64/boot/dts/rockchip/rk3568-wolfvision-pf5-io-expander.dtso
index 048933de2943..8cfce71dd318 100644
--- a/arch/arm64/boot/dts/rockchip/rk3568-wolfvision-pf5-io-expander.dtso
+++ b/arch/arm64/boot/dts/rockchip/rk3568-wolfvision-pf5-io-expander.dtso
@@ -11,6 +11,7 @@
 #include <dt-bindings/clock/rk3568-cru.h>
 #include <dt-bindings/gpio/gpio.h>
 #include <dt-bindings/interrupt-controller/irq.h>
+#include <dt-bindings/media/video-interfaces.h>
 #include <dt-bindings/pinctrl/rockchip.h>
 
 &{/} {
@@ -134,3 +135,22 @@ &usb2phy0_host {
 	phy-supply = <&usb_host_vbus>;
 	status = "okay";
 };
+
+&vicap {
+	pinctrl-names = "default";
+	pinctrl-0 = <&cif_clk &cif_dvp_clk &cif_dvp_bus16>;
+	status = "okay";
+};
+
+&vicap_dvp {
+	vicap_dvp_input: endpoint {
+		bus-type = <MEDIA_BUS_TYPE_BT656>;
+		bus-width = <16>;
+		pclk-sample = <MEDIA_PCLK_SAMPLE_DUAL_EDGE>;
+		rockchip,dvp-clk-delay = <10>;
+	};
+};
+
+&vicap_mmu {
+	status = "okay";
+};

---
base-commit: 1f318b96cc84d7c2ab792fcc0bfd42a7ca890681
change-id: 20260313-wv-io-expander-vicap-255be2ced75c

Best regards,
-- 
Michael Riesch <michael.riesch@collabora.com>

