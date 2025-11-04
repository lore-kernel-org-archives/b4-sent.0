From: David Heidelberg <david@ixit.cz>
Date: Tue, 04 Nov 2025 23:16:14 +0100
Subject: [PATCH 06/12] drm/panel: sofef00: Introduce page macro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251104-sofef00-rebuild-v1-6-dfcfa17eb176@ixit.cz>
References: <20251104-sofef00-rebuild-v1-0-dfcfa17eb176@ixit.cz>
In-Reply-To: <20251104-sofef00-rebuild-v1-0-dfcfa17eb176@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2024; i=david@ixit.cz;
 h=from:subject:message-id; bh=KFWwy/+TPv3o+Pr2om1zoaTzQ1nmZjY1fcOyZY+O5S8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpCnssKl2JvbVAIAyvYQM8vZGahsnkSpWb0WPDy
 bQmljI0h2mJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaQp7LAAKCRBgAj/E00kg
 cq75EACDoWk8cQdRNuWiIq4qRV4qTj5eVnUk0PlrGaMWjvlDvDF2A5RHr/DOSLn79g5posLE15Q
 AobRHXayu/Mdr+dk4z2BYsekvbPY9FIc1b2UoZuvZqeIgRnM71uJF0b1MHcxkA/Hu7a9Rqa8zkS
 Ej/96tBjjiDUnOfivFei4Wm5B648h7juKTT+S2qYzvWP/iJr7Tm665JD6Zjbfdgqzz8O0R7x9KQ
 FUG6T4Xm5ZIoeudOB1Pb3KuRnzgdc8JW9Ccr4BIKxgG66vdj+bjXXaAylml6rtZHAfsrJ10MAu2
 lfPXUbkWvRAS+RLEYMrr4JJmTpAoBvept3BNSmtB2e5a2P4F+KPXTxaV6DWhdoF6dE0gUqXH9Jb
 qSFVmvHuIUlrrGrHVf1gsVp7AmxRKypKV/BzvRgXhpjVBV9o2pixpun8ACQq3tXQYwJ/7RaGR4f
 WHobmCOZnSly5ORn37GUGjNzMUwCh5wAJYfH5j4PC12RHkkCfh7F03/W9FnUI2E/PUC9oBSvyf7
 CCi01iViD6zDbn+ADIvIRhS+P1uFGNwbth3D+TLVYE6llaVT0eVXDNtiBrJNoSwyOOUlwLU4pH9
 sDTapc+kudSIRPhuowQW1NNfF4LLqvN4z92tGZUSb0YGpqfqB14XDJM5jubZMGGAmBfg+Q8UO7E
 /xpx+xeQ9NWv2XA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introducing the macro make the code a bit clearer.

Looking at other Samsung drivers, I assume it's lvl2, thou due to not
available documentation it's only educated guess.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-sofef00.c | 15 ++++++++++-----
 1 file changed, 10 insertions(+), 5 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-samsung-sofef00.c b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
index a3651f0060bde..97122ec8872a1 100644
--- a/drivers/gpu/drm/panel/panel-samsung-sofef00.c
+++ b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
@@ -36,6 +36,11 @@ struct sofef00_panel *to_sofef00_panel(struct drm_panel *panel)
 	return container_of(panel, struct sofef00_panel, panel);
 }
 
+#define sofef00_test_key_on_lvl2(ctx) \
+	mipi_dsi_dcs_write_seq_multi(ctx, 0xf0, 0x5a, 0x5a)
+#define sofef00_test_key_off_lvl2(ctx) \
+	mipi_dsi_dcs_write_seq_multi(ctx, 0xf0, 0xa5, 0xa5)
+
 static void sofef00_panel_reset(struct sofef00_panel *ctx)
 {
 	gpiod_set_value_cansleep(ctx->reset_gpio, 0);
@@ -56,15 +61,15 @@ static int sofef00_panel_on(struct sofef00_panel *ctx)
 	mipi_dsi_dcs_exit_sleep_mode_multi(&dsi_ctx);
 	mipi_dsi_usleep_range(&dsi_ctx, 10000, 11000);
 
-	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xf0, 0x5a, 0x5a);
-
+	sofef00_test_key_on_lvl2(&dsi_ctx);
 	mipi_dsi_dcs_set_tear_on_multi(&dsi_ctx, MIPI_DSI_DCS_TEAR_MODE_VBLANK);
+	sofef00_test_key_off_lvl2(&dsi_ctx);
 
-	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xf0, 0xa5, 0xa5);
-	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xf0, 0x5a, 0x5a);
+	sofef00_test_key_on_lvl2(&dsi_ctx);
 	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xb0, 0x07);
 	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xb6, 0x12);
-	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xf0, 0xa5, 0xa5);
+	sofef00_test_key_off_lvl2(&dsi_ctx);
+
 	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, MIPI_DCS_WRITE_CONTROL_DISPLAY, 0x20);
 	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, MIPI_DCS_WRITE_POWER_SAVE, 0x00);
 

-- 
2.51.0

