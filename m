From: David Heidelberg <david@ixit.cz>
Date: Thu, 13 Nov 2025 18:57:39 +0100
Subject: [PATCH v2 05/12] drm/panel: sofef00: Split sending commands to the
 enable/disable functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251113-sofef00-rebuild-v2-5-e175053061ec@ixit.cz>
References: <20251113-sofef00-rebuild-v2-0-e175053061ec@ixit.cz>
In-Reply-To: <20251113-sofef00-rebuild-v2-0-e175053061ec@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jessica.zhang@oss.qualcomm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2045; i=david@ixit.cz;
 h=from:subject:message-id; bh=xfG4W9ai59WdRLt2V9HKjqKsc6sEspLbINOP0a9yxjE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpFhwUGXzAbG17sDfyaOHuZB00UB1Hm4CErEAIN
 6Z3Kq5G3CaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRYcFAAKCRBgAj/E00kg
 cld0D/0Rh7WmQyKsgOmdspslAxL2eWJFo56eMotujOSOk73SpZ7S3Z9tYFLnejQv2WnGFoLcoD9
 aFTQsUKg6P/aZ96VU2tbhFVzhRTWzc5ohiFZf+yWRa9H3asWK2Csee+jwLUPkKjWm164kvCponv
 Ro7+OfuQcYd9E1cNYLPJC5F0uVbLjE7zwFtCn42NqLu8iTvr4GhCNJfUv2lOfABCooriRpMqPCm
 AwoXBGG2wx285rsIP9PIIY/5ilqLzy3q1R15wjptriauqZO3Puotdo/ir9UvEYjmzY3AqwQqNXV
 Z7+DW93ThTEQUjEW8B+k1ZXZY88NJJvVH+7lmMyQLrBmjNWsFXh+vHVKpx/4hldVVqC1skrHMNV
 hWCNKDsu1IL8+jpSyndYVMXj4CkJYU2civuOharkx8QU2C5RmQ/W8PyPBevAlkscHu8ietJbQR5
 e+kKuuhD8WUjNMtV1gelO6Mcz+aEBbu3rIxxXHozfJpJJMgSYZGKdOHCYVdvel85iMu1odM75G/
 A6EYi+AYzaEG8wB4tEQME0IvmKhBwhnYNfsKkwNOVaEMjYw5uqVrTsMkLGg7SX6Z1W/HjG66KnQ
 UFGV6HT2yuId7jIuSBXbcQftn9NcaryiyxPgrKD5rkhc2Kl1LnvAxFgKqOeD9evFAZ5NvMbuoFv
 IP1ynH5dl5bhuVw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It's not possible to send DSI panel commands in the .unprepare. Move it
to .disable and do similar for prepare, where we move the display on to
the .enable.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-sofef00.c | 20 +++++++++++++++++++-
 1 file changed, 19 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panel/panel-samsung-sofef00.c b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
index 3097040e6bfa0..a3651f0060bde 100644
--- a/drivers/gpu/drm/panel/panel-samsung-sofef00.c
+++ b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
@@ -68,6 +68,14 @@ static int sofef00_panel_on(struct sofef00_panel *ctx)
 	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, MIPI_DCS_WRITE_CONTROL_DISPLAY, 0x20);
 	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, MIPI_DCS_WRITE_POWER_SAVE, 0x00);
 
+	return dsi_ctx.accum_err;
+}
+
+static int sofef00_enable(struct drm_panel *panel)
+{
+	struct sofef00_panel *ctx = to_sofef00_panel(panel);
+	struct mipi_dsi_multi_context dsi_ctx = { .dsi = ctx->dsi };
+
 	mipi_dsi_dcs_set_display_on_multi(&dsi_ctx);
 
 	return dsi_ctx.accum_err;
@@ -110,11 +118,19 @@ static int sofef00_panel_prepare(struct drm_panel *panel)
 	return 0;
 }
 
-static int sofef00_panel_unprepare(struct drm_panel *panel)
+static int sofef00_disable(struct drm_panel *panel)
 {
 	struct sofef00_panel *ctx = to_sofef00_panel(panel);
 
 	sofef00_panel_off(ctx);
+
+	return 0;
+}
+
+static int sofef00_panel_unprepare(struct drm_panel *panel)
+{
+	struct sofef00_panel *ctx = to_sofef00_panel(panel);
+
 	regulator_bulk_disable(ARRAY_SIZE(sofef00_supplies), ctx->supplies);
 
 	return 0;
@@ -154,6 +170,8 @@ static int sofef00_panel_get_modes(struct drm_panel *panel, struct drm_connector
 
 static const struct drm_panel_funcs sofef00_panel_panel_funcs = {
 	.prepare = sofef00_panel_prepare,
+	.enable = sofef00_enable,
+	.disable = sofef00_disable,
 	.unprepare = sofef00_panel_unprepare,
 	.get_modes = sofef00_panel_get_modes,
 };

-- 
2.51.0

