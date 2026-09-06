From: David Heidelberg <david@ixit.cz>
Date: Sun, 06 Sep 2026 15:19:02 +0200
Subject: [PATCH 1/3] drm/panel: ebbg-ft8719: Set prepare_prev_first
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-ebbg-ft8719-fixups-v1-1-4e846510cad1@ixit.cz>
References: <20260906-ebbg-ft8719-fixups-v1-0-4e846510cad1@ixit.cz>
In-Reply-To: <20260906-ebbg-ft8719-fixups-v1-0-4e846510cad1@ixit.cz>
To: Joel Selvaraj <jo@jsfamily.in>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sam Ravnborg <sam@ravnborg.org>, Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 Linus Walleij <linusw@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Casey Connolly <casey.connolly@linaro.org>, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1210; i=david@ixit.cz;
 h=from:subject:message-id; bh=MdKS4MaN+wl5Cm+tdhGjh1Y6pdj5edF/ffF4+200w9w=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqnWhPI76LaG4om4ZpsbFRORTnkEMFZ4suxTmK5
 QUqeYXA9JSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCap1oTwAKCRBgAj/E00kg
 cga2EADLwprPfozo4mnQ3SHTqkt5yXwlnKlXeLiAuz3rs7kylKD/ov9rwC4F9et4v1qo5i9d5Vo
 bQ86yjgrFQhjW10D/8T5tgK/r037RdK2WMNtlj4j8yqIYOzepyZ5DSyo1tXTYSf7rtdgoXfS363
 PsuDFzL6GSfairKq8AbzjgyCRuZg1N4/ankH9+1vYBP5Z14fAmo4jnEJgktYWK7gK4DQWb9zvOb
 U5XjoyVpfjO7pXsHgwV9ejQ/t3Pz5dZspJCtDSLywJl+v0qNUnPwDOJv7pdsKLyuJm6VZyGDFjV
 Cgr1U1jO2rB72t59pCQQU+0uRux/GafvV/IL5orsNLxrf/2Pi8gjYcRWWG52FzWzjiSh2CLCbg7
 bzGIxDGxHJVsfXXgC+WgXnrqb7EmIbcppOCvXggTSJ8fDPC1a6AHol5SxyZThGXTIhDTWND7rrw
 S8oX2llUvvtPMXR5nG3vtd2y+BByn4E0Xg13NG3lsO5xtRHGxN3EeFx5QnnB6Tkr/0tpf+SjwBI
 GznskK6hFt3ABwr49l/yFzFtJdYCp0a7YIQ4J/XEPwxqvCB9z9RQUgrQkf7u+8NdsPfQmeXyTXV
 m02TQhR89R6SPmvkhfKwgHHUipoRuiiisBxmoth875tFgRXhCPswQPB2WFIbVfhbvzlEJmyKRti
 WeFbOiq9oK3gZpw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

This corrects the host initialisation sequence so that we can send
DSI/DCS commands in prepare().

Cc: stable@vger.kernel.org
Fixes: b00de0e237da ("drm/panel: introduce ebbg,ft8719 panel")
Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-ebbg-ft8719.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/gpu/drm/panel/panel-ebbg-ft8719.c b/drivers/gpu/drm/panel/panel-ebbg-ft8719.c
index fb9f9f42be4f2..1ab09c50a6306 100644
--- a/drivers/gpu/drm/panel/panel-ebbg-ft8719.c
+++ b/drivers/gpu/drm/panel/panel-ebbg-ft8719.c
@@ -193,16 +193,18 @@ static int ebbg_ft8719_probe(struct mipi_dsi_device *dsi)
 	ctx->dsi = dsi;
 	mipi_dsi_set_drvdata(dsi, ctx);
 
 	dsi->lanes = 4;
 	dsi->format = MIPI_DSI_FMT_RGB888;
 	dsi->mode_flags = MIPI_DSI_MODE_VIDEO | MIPI_DSI_MODE_VIDEO_BURST |
 			  MIPI_DSI_CLOCK_NON_CONTINUOUS;
 
+	ctx->panel.prepare_prev_first = true;
+
 	ret = drm_panel_of_backlight(&ctx->panel);
 	if (ret)
 		return dev_err_probe(dev, ret, "Failed to get backlight\n");
 
 	drm_panel_add(&ctx->panel);
 
 	ret = mipi_dsi_attach(dsi);
 	if (ret < 0) {

-- 
2.55.0

