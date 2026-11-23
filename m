From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Mon, 23 Nov 2026 20:37:41 +0100
Subject: [PATCH v4 09/11] arm64: dts: amlogic: Add HDMI TX PHY node for G12
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-meson-drm-create-hdmitx-phy-v4-9-3fb94f5534ca@aliel.fr>
References: <20261123-meson-drm-create-hdmitx-phy-v4-0-3fb94f5534ca@aliel.fr>
In-Reply-To: <20261123-meson-drm-create-hdmitx-phy-v4-0-3fb94f5534ca@aliel.fr>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Vinod Koul <vkoul@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Ulf Hansson <ulfh@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-phy@lists.infradead.org, dri-devel@lists.freedesktop.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>, linux-pm@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1147;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=96ezTxgocDNVGkQVkrXP3m6ZHN0B1G+z/JYBO9mFeTE=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQzbLNOH42B+lxb/Ml9z/9Nlq4bZFganfZs1J25zL7pNqn
 JKqPqe7o5SFQYyLQVZMkaV/ruWJd5ePnvm6Rz0FZg4rE8gQBi5OAZjIIi+G/+kLXXdrsfHVHHHT
 V2M1DP65dcXNgGOVXd5fVKW9vyzNv83I0GD0jdWPtXiPT2i1iY1G7rqgjgsn22enJ5/YbJKSOHc
 9FwA=
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the HDMI TX PHY as a child of the HHI system controller, with
the amlogic,meson-g12a-hdmi-tx-phy compatible and reference
it from the HDMI TX node through "phys".

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 arch/arm64/boot/dts/amlogic/meson-g12-common.dtsi | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/meson-g12-common.dtsi b/arch/arm64/boot/dts/amlogic/meson-g12-common.dtsi
index 3135566df880..7f9eda4298e9 100644
--- a/arch/arm64/boot/dts/amlogic/meson-g12-common.dtsi
+++ b/arch/arm64/boot/dts/amlogic/meson-g12-common.dtsi
@@ -210,6 +210,7 @@ hdmi_tx: hdmi-tx@0 {
 					 <&clkc CLKID_HTX_PCLK>,
 					 <&clkc CLKID_VPU_INTR>;
 				clock-names = "isfr", "iahb", "venci";
+				phys = <&hdmi_tx_phy>;
 				#address-cells = <1>;
 				#size-cells = <0>;
 				#sound-dai-cells = <0>;
@@ -1683,6 +1684,11 @@ mipi_analog_dphy: phy {
 						#phy-cells = <0>;
 						status = "disabled";
 					};
+
+					hdmi_tx_phy: hdmi-phy {
+						compatible = "amlogic,meson-g12a-hdmi-tx-phy";
+						#phy-cells = <0>;
+					};
 				};
 			};
 

-- 
2.56.1

