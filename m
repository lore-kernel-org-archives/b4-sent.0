From: David Heidelberg <david@ixit.cz>
Date: Mon, 08 Dec 2025 10:41:57 +0100
Subject: [PATCH v6 4/8] drm/panel: sw43408: Add enable/disable and reset
 functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251208-pixel-3-v6-4-e9e559d6f412@ixit.cz>
References: <20251208-pixel-3-v6-0-e9e559d6f412@ixit.cz>
In-Reply-To: <20251208-pixel-3-v6-0-e9e559d6f412@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sumit Semwal <sumit.semwal@linaro.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Dmitry Baryshkov <lumag@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Petr Hodina <phodina@protonmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=4042; i=david@ixit.cz;
 h=from:subject:message-id; bh=qN5N+wyRlTAEEdBXkU0m8ndfuHhWL8oA++gF/EwODJc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpNp1/kkA3vvylZ+8cMHHZS2NThYES8yN3zqhuu
 ZuGxQ1j43iJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaTadfwAKCRBgAj/E00kg
 cv2cEACcHz4ocz4NqY/iG7yqNqtCuDpD3sIbfDmQeg4v/KR47l1LCftkzCjBo2HRf0Cq007b3rI
 LMoS1Bt5KQSTOGRJd055fcnU6rQXXNCeUnpwmWCMj07jdYixE51FK+yWJPVrXtw6Vjxc5L4KHd6
 U6id8ZVqDV1Bw1gSUQHCxOrsDIHxOdd8nybmJoabW1OQ60COPaXl0oRFINuU329SQgi0YcxFT7b
 YU3Tk+OgHwDom3A0Y2UY4QoU+E3iEd+fQAWtu3P8fmZYgWxQHI19B9pESXxYfUsKXjazGa/Ickh
 7vTh3RBEJlWKUc3LElxj0HElotJNqXJOkJ/KMO5mYexuJ0HDQXO5c1OHsY2/OXnEHvdq1qHgyWW
 c5E6kdxRt8KWAitNDpCO61Zuw2arVBX+Ry4dKp8pfHVwmZIX/R8J51RQT9o0MZr1pUKsa7HdgGH
 gF5W4i91xXknicDH7t7PGm2dbZ4uWswCSxxx19ihFSljJuN99VPyuB30bVsvYgQvjLMcjCfWmcW
 LM2AneVYvPweUGkv7FjUkDPXEiLRdB7EANuxOTNb2O2a7zGfMvLy11d/IxvUvMoG5jJP0PA1Kfj
 YKI5i6nr3NsB8phXKGgTYkUBIxC0Bc504PGTFIhPMplrrHjokyN+95tIsF/jyTC99dp5yxNN5VO
 /d73rhnGet2Wdlw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce enable(), disable() and reset() functions.

The enable() and disable() callbacks keep the symmetry in the commands
sent to the panel and also make a clearer distinction between panel
initialization and configuration.

Splitting reset() from prepare() follows clean coding practices and lets
us potentially make reset optional in the future for flicker-less
takeover from a bootloader or framebuffer driver where the panel is
already configured.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-lg-sw43408.c | 47 ++++++++++++++++++++++++--------
 1 file changed, 35 insertions(+), 12 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-lg-sw43408.c b/drivers/gpu/drm/panel/panel-lg-sw43408.c
index dcca7873acf8e..dad6b967b92c2 100644
--- a/drivers/gpu/drm/panel/panel-lg-sw43408.c
+++ b/drivers/gpu/drm/panel/panel-lg-sw43408.c
@@ -38,11 +38,10 @@ static inline struct sw43408_panel *to_panel_info(struct drm_panel *panel)
 	return container_of(panel, struct sw43408_panel, base);
 }
 
-static int sw43408_unprepare(struct drm_panel *panel)
+static int sw43408_disable(struct drm_panel *panel)
 {
 	struct sw43408_panel *sw43408 = to_panel_info(panel);
 	struct mipi_dsi_multi_context ctx = { .dsi = sw43408->link };
-	int ret;
 
 	mipi_dsi_dcs_set_display_off_multi(&ctx);
 
@@ -50,18 +49,25 @@ static int sw43408_unprepare(struct drm_panel *panel)
 
 	mipi_dsi_msleep(&ctx, 100);
 
+	return ctx.accum_err;
+}
+
+static int sw43408_unprepare(struct drm_panel *panel)
+{
+	struct sw43408_panel *sw43408 = to_panel_info(panel);
+	int ret;
+
 	gpiod_set_value(sw43408->reset_gpio, 1);
 
 	ret = regulator_bulk_disable(ARRAY_SIZE(sw43408->supplies), sw43408->supplies);
 
-	return ret ? : ctx.accum_err;
+	return ret;
 }
 
 static int sw43408_program(struct drm_panel *panel)
 {
 	struct sw43408_panel *sw43408 = to_panel_info(panel);
 	struct mipi_dsi_multi_context ctx = { .dsi = sw43408->link };
-	struct drm_dsc_picture_parameter_set pps;
 
 	mipi_dsi_dcs_write_seq_multi(&ctx, MIPI_DCS_SET_GAMMA_CURVE, 0x02);
 
@@ -97,6 +103,15 @@ static int sw43408_program(struct drm_panel *panel)
 	mipi_dsi_dcs_write_seq_multi(&ctx, 0x55, 0x04, 0x61, 0xdb, 0x04, 0x70, 0xdb);
 	mipi_dsi_dcs_write_seq_multi(&ctx, 0xb0, 0xca);
 
+	return ctx.accum_err;
+}
+
+static int sw43408_enable(struct drm_panel *panel)
+{
+	struct sw43408_panel *sw43408 = to_panel_info(panel);
+	struct mipi_dsi_multi_context ctx = { .dsi = sw43408->link };
+	struct drm_dsc_picture_parameter_set pps;
+
 	mipi_dsi_dcs_set_display_on_multi(&ctx);
 
 	mipi_dsi_msleep(&ctx, 50);
@@ -116,18 +131,12 @@ static int sw43408_program(struct drm_panel *panel)
 	 */
 	mipi_dsi_compression_mode_ext_multi(&ctx, true,
 					    MIPI_DSI_COMPRESSION_DSC, 1);
+
 	return ctx.accum_err;
 }
 
-static int sw43408_prepare(struct drm_panel *panel)
+static void sw43408_reset(struct sw43408_panel *ctx)
 {
-	struct sw43408_panel *ctx = to_panel_info(panel);
-	int ret;
-
-	ret = regulator_bulk_enable(ARRAY_SIZE(ctx->supplies), ctx->supplies);
-	if (ret < 0)
-		return ret;
-
 	usleep_range(5000, 6000);
 
 	gpiod_set_value(ctx->reset_gpio, 0);
@@ -136,6 +145,18 @@ static int sw43408_prepare(struct drm_panel *panel)
 	usleep_range(1000, 2000);
 	gpiod_set_value(ctx->reset_gpio, 0);
 	usleep_range(9000, 10000);
+}
+
+static int sw43408_prepare(struct drm_panel *panel)
+{
+	struct sw43408_panel *ctx = to_panel_info(panel);
+	int ret;
+
+	ret = regulator_bulk_enable(ARRAY_SIZE(ctx->supplies), ctx->supplies);
+	if (ret < 0)
+		return ret;
+
+	sw43408_reset(ctx);
 
 	ret = sw43408_program(panel);
 	if (ret)
@@ -208,6 +229,8 @@ static int sw43408_backlight_init(struct sw43408_panel *ctx)
 }
 
 static const struct drm_panel_funcs sw43408_funcs = {
+	.disable = sw43408_disable,
+	.enable = sw43408_enable,
 	.unprepare = sw43408_unprepare,
 	.prepare = sw43408_prepare,
 	.get_modes = sw43408_get_modes,

-- 
2.51.0

