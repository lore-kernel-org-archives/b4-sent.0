From: Joachim Eastwood <joachim.eastwood@gmail.com>
Date: Wed, 18 Nov 2026 22:45:29 +0100
Subject: [PATCH 2/4] drm/bridge: synopsys: dw-hdmi-qp: Attach the next
 bridge in the chain
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-dw-hdmi-qp-bridge_attach-v1-2-e370920bc7f3@gmail.com>
References: <20261118-dw-hdmi-qp-bridge_attach-v1-0-e370920bc7f3@gmail.com>
In-Reply-To: <20261118-dw-hdmi-qp-bridge_attach-v1-0-e370920bc7f3@gmail.com>
To: Sandy Huang <hjc@rock-chips.com>, 
 =?utf-8?q?Heiko_St=C3=BCbner?= <heiko@sntech.de>, 
 Andy Yan <andyshrk@163.com>, Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Luca Ceresoli <luca.ceresoli@bootlin.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Alexey Charkov <alchark@gmail.com>, 
 Cristian Ciocaltea <cristian.ciocaltea@collabora.com>, 
 Nicolas Frattaroli <nicolas.frattaroli@collabora.com>
Cc: dri-devel@lists.freedesktop.org, linux-rockchip@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795038370; l=2517;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=1lj8+1BKN4Nmy9uS7g9V3h/v7ntQIcakt96ADfZAy+E=;
 b=qq32ej2OwuLI/6OrZU8KxRARx2vkpz9KS9rNSkIXUhwn2XNIS7+VOH1ZX6Rl+Vc7M/OvdOdHH
 E5qFVxvmA1HCsi5jMmSESIPXKvWfeo2N8U7fvzw7LjmNPZ7lQWSvd9k
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement the drm_bridge_funcs attach function so dw-hdmi-qp will attach
to the next bridge in the chain. This will allow the properties on the
next bridge be used. In the case of hdmi-connector this will make
properties like ddc-i2c-bus and hpd-gpios can override the on-chip
functions in dw-hdmi-qp.

Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
 drivers/gpu/drm/bridge/synopsys/dw-hdmi-qp.c | 30 ++++++++++++++++++++++++++++
 1 file changed, 30 insertions(+)

diff --git a/drivers/gpu/drm/bridge/synopsys/dw-hdmi-qp.c b/drivers/gpu/drm/bridge/synopsys/dw-hdmi-qp.c
index eed249aca1e23..200229e5d9afc 100644
--- a/drivers/gpu/drm/bridge/synopsys/dw-hdmi-qp.c
+++ b/drivers/gpu/drm/bridge/synopsys/dw-hdmi-qp.c
@@ -16,6 +16,7 @@
 #include <linux/module.h>
 #include <linux/mutex.h>
 #include <linux/of.h>
+#include <linux/of_graph.h>
 
 #include <drm/bridge/dw_hdmi_qp.h>
 #include <drm/display/drm_hdmi_helper.h>
@@ -39,6 +40,9 @@
 #define DDC_CI_ADDR		0x37
 #define DDC_SEGMENT_ADDR	0x30
 
+/* OF graph port carrying the output towards the HDMI connector */
+#define DW_HDMI_QP_OUTPUT_PORT	1
+
 struct dw_hdmi_qp_i2c {
 	struct i2c_adapter	adap;
 
@@ -1024,7 +1028,33 @@ static void dw_hdmi_qp_bridge_hpd_disable(struct drm_bridge *bridge)
 		hdmi->phy.ops->disable_hpd(hdmi, hdmi->phy.data);
 }
 
+static int dw_hdmi_qp_bridge_attach(struct drm_bridge *bridge,
+				    struct drm_encoder *encoder,
+				    enum drm_bridge_attach_flags flags)
+{
+	struct dw_hdmi_qp *hdmi = bridge->driver_private;
+	struct device_node *remote __free(device_node) =
+		of_graph_get_remote_node(hdmi->dev->of_node,
+					 DW_HDMI_QP_OUTPUT_PORT, -1);
+
+	/*
+	 * The HDMI connector node is optional. When present, chain its bridge
+	 * so that properties such as ddc-i2c-bus, hpd-gpios and supplies are
+	 * honoured by the DRM bridge connector.
+	 */
+	if (!remote)
+		return 0;
+
+	struct drm_bridge *next_bridge __free(drm_bridge_put) =
+		of_drm_find_and_get_bridge(remote);
+	if (!next_bridge)
+		return -EPROBE_DEFER;
+
+	return drm_bridge_attach(encoder, next_bridge, bridge, flags);
+}
+
 static const struct drm_bridge_funcs dw_hdmi_qp_bridge_funcs = {
+	.attach = dw_hdmi_qp_bridge_attach,
 	.atomic_get_output_bus_fmts = drm_atomic_helper_bridge_get_hdmi_output_bus_fmts,
 	.atomic_get_input_bus_fmts = drm_atomic_helper_bridge_propagate_bus_fmt,
 	.atomic_duplicate_state = drm_atomic_helper_bridge_duplicate_state,

-- 
2.56.0

