From: Cody Kang <codykang.hk@gmail.com>
Date: Sat, 21 Nov 2026 15:40:55 +0800
Subject: [PATCH v3 16/17] riscv: dts: spacemit: k3-com260-ifx: enable the
 DisplayPort output
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-k3-display-v3-16-ec419e8e96b8@gmail.com>
References: <20261121-k3-display-v3-0-ec419e8e96b8@gmail.com>
In-Reply-To: <20261121-k3-display-v3-0-ec419e8e96b8@gmail.com>
To: David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Yixun Lan <dlan@kernel.org>, 
 Troy Mitchell <troy.mitchell@linux.spacemit.com>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Haylen Chu <heylenay@4d2.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Yao Zi <me@ziyao.cc>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 Guodong Xu <docular.xu@gmail.com>, Icenowy Zheng <uwu@icenowy.me>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Sarah Emery <sarah.emery@canonical.com>, 
 Ze Huang <ze.huang@oss.qualcomm.com>, Dmitry Baryshkov <lumag@kernel.org>
Cc: Cody Kang <codykang@vsit.ai>, dri-devel@lists.freedesktop.org, 
 linux-riscv@lists.infradead.org, devicetree@vger.kernel.org, 
 spacemit@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-phy@lists.infradead.org, linux-clk@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795246844; l=2262;
 i=codykang.hk@gmail.com; s=codykang; h=from:subject:message-id;
 bh=E78ySXuc7cskakorLvfTKi4q+Aj5tLnVas7172iViS8=;
 b=+l50UcVZTidzyMw5IfVtxsgruvr+qucZeTZdrIakHSuASGpLlWMuz53votn1rMk41mdq+AJcS
 Tip6sDvTE3vAA6fbTQP9FnGI+FyOl3lltKHH3tbERd4D25Yn9IX64lU
X-Developer-Key: i=codykang.hk@gmail.com; a=ed25519;
 pk=Osn6/cs9Su/mHHw4P19cmVc3v2FMQfiWahjsN0vEkuk=
X-Endpoint-Received: by B4 Relay for codykang.hk@gmail.com/codykang with auth_id=895
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Cody Kang <codykang@vsit.ai>

CoM260-IFX carries a single DisplayPort output. Enable the second DPU
and the DisplayPort controller it feeds.

Signed-off-by: Cody Kang <codykang@vsit.ai>

---
v3:
- describe the HPD pad at the 1.8 V it runs at
- commit message: reworded
v2:
- describe the DP receptacle (dp-connector) and link it to dp1 port@1
  (Rob Herring, on patch 03)
---
 arch/riscv/boot/dts/spacemit/k3-com260-ifx.dts | 27 ++++++++++++++++++++++++++
 arch/riscv/boot/dts/spacemit/k3-pinctrl.dtsi   | 11 +++++++++++
 2 files changed, 38 insertions(+)

diff --git a/arch/riscv/boot/dts/spacemit/k3-com260-ifx.dts b/arch/riscv/boot/dts/spacemit/k3-com260-ifx.dts
index fadcf28389be9..321715d455865 100644
--- a/arch/riscv/boot/dts/spacemit/k3-com260-ifx.dts
+++ b/arch/riscv/boot/dts/spacemit/k3-com260-ifx.dts
@@ -6,6 +6,7 @@
 #include <dt-bindings/phy/phy.h>
 
 #include "k3-com260.dtsi"
+#include "k3-display.dtsi"
 
 / {
 	model = "SpacemiT K3 CoM260 IFX";
@@ -20,6 +21,18 @@ chosen {
 		stdout-path = "serial0:115200n8";
 	};
 
+	connector {
+		compatible = "dp-connector";
+		label = "DP1";
+		type = "full-size";
+
+		port {
+			dp1_connector_in: endpoint {
+				remote-endpoint = <&dp1_out>;
+			};
+		};
+	};
+
 	reg_hub_5v: regulator-usb3-hub-5v {
 		compatible = "regulator-fixed";
 		regulator-name = "USB30_HUB";
@@ -129,3 +142,17 @@ &sdhci0 {
 	sd-uhs-sdr104;
 	status = "okay";
 };
+
+&dpu1_crtc0 {
+	status = "okay";
+};
+
+&dp1 {
+	pinctrl-names = "default";
+	pinctrl-0 = <&dp1_3_cfg>;
+	status = "okay";
+};
+
+&dp1_out {
+	remote-endpoint = <&dp1_connector_in>;
+};
diff --git a/arch/riscv/boot/dts/spacemit/k3-pinctrl.dtsi b/arch/riscv/boot/dts/spacemit/k3-pinctrl.dtsi
index a3188ca0ceb36..ea88ec95b9136 100644
--- a/arch/riscv/boot/dts/spacemit/k3-pinctrl.dtsi
+++ b/arch/riscv/boot/dts/spacemit/k3-pinctrl.dtsi
@@ -22,6 +22,17 @@ dp1-pins {
 		};
 	};
 
+	/omit-if-no-ref/
+	dp1_3_cfg: dp1-3-cfg {
+		dp1-pins {
+			pinmux = <K3_PADCONF(72, 4)>;	/* dp1 hpd */
+
+			bias-disable;
+			drive-strength = <25>;
+			power-source = <1800>;
+		};
+	};
+
 	gmac0_rgmii_0_cfg: gmac0-rgmii-0-cfg {
 		gmac0-rgmii-0-pins {
 			pinmux = <K3_PADCONF(0, 1)>,	/* gmac0_rxdv */

-- 
2.43.0

