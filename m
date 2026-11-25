From: David Heidelberg <david@ixit.cz>
Date: Wed, 25 Nov 2026 19:12:47 +0100
Subject: [PATCH v4 3/9] drm/panel: s6e3ha8: Introduce AMB577PX01 panel
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-crosshatch-panel-v4-3-120adc58e737@ixit.cz>
References: <20261125-crosshatch-panel-v4-0-120adc58e737@ixit.cz>
In-Reply-To: <20261125-crosshatch-panel-v4-0-120adc58e737@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Petr Vorel <petr.vorel@gmail.com>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1409; i=david@ixit.cz;
 h=from:subject:message-id; bh=rCrRxpJWEkA+wgegtsEKS9XsmbU7TwkO+KtW1/Btotk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrByUeIgC46JvhQIPnYQYYYCamNwpmw3jNpsU3R
 MESU5BsDn+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawclHgAKCRBgAj/E00kg
 cplHD/wO5o+nxQl76HIHS0/qGCfgHjQrPeaFdECMubs4ag1CtwpMgHSWR7ELr/JdsGwtIB3h2nV
 vnY7GN6gfF9ffSawtLY+NlSHX0HeeiJM4Z/GhCvkpGeiqLpRGgFDCU8/r26lZGYaxCGLjdgtUJl
 fILya80imza0R0jxaCIjgnzx8uTB8f5c5AYScFav8rhqQSK8+NFeGiFNdRq/XDD8luXIoYDaJuq
 vtjRHt9s3/12rOFWw4rlSowGM1Ukgd726hprQ1W1Ev2njidSP6IrvyWNuJjPrNtqzIhbBU9kt5A
 lrdvUnlTjeqWMNLpjG1makuBH+qGEiOE3P/LKhboqFg5hyqJWCbSQ5RGfrIx7ZEa5/ZqWsokxIV
 54k4kAnQyU6/ZB5d+CD5TIl06/UW0OLtkL65HL3vP4IVZzVV/KQrgVODFvrg5r3FD18dH+5fB8y
 6Piy4tYQ0ujHlr6JUffGFGkoV6XOLsBP+qEdWi/ccD1MvXoKt4SITBTyKq5AZqzt5e4HIkQDoDO
 G8tzW3/O3LqxOqR0b+H8w0LMpo1Y/PzLg3XYz2f1afZ3F8zZ5CH/3PO6Ai/aiPSYfYoTNk2egq6
 b6sX/bKOGY6L0ZXET9+6P+G3bJdFqvpAmDgf33GgtrJPtq0my9GRg6gmXfC3kQd0unWKC0duTb6
 bu69lntBqDHdyug==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

S6E3HA8 is the DDIC, while the panel used on the Samsung Galaxy S9 is
the Samsung AMB577PX01. Match on the new panel compatible, and keep
the deprecated DDIC-only one working for existing devicetrees.

Reviewed-by: Petr Vorel <petr.vorel@gmail.com>
Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c b/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
index 078523df48860..45b1c522b0ccf 100644
--- a/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
+++ b/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
@@ -296,17 +296,18 @@ static int s6e3ha8_amb577px01_wqhd_probe(struct mipi_dsi_device *dsi)
 		dev_err(dev, "Failed to attach to DSI host: %d\n", ret);
 		return ret;
 	}
 
 	return 0;
 }
 
 static const struct of_device_id s6e3ha8_amb577px01_wqhd_of_match[] = {
-	{ .compatible = "samsung,s6e3ha8" },
+	{ .compatible = "samsung,s6e3ha8" }, /* deprecated */
+	{ .compatible = "samsung,s6e3ha8-amb577px01" },
 	{ /* sentinel */ }
 };
 MODULE_DEVICE_TABLE(of, s6e3ha8_amb577px01_wqhd_of_match);
 
 static struct mipi_dsi_driver s6e3ha8_amb577px01_wqhd_driver = {
 	.probe = s6e3ha8_amb577px01_wqhd_probe,
 	.driver = {
 		.name = "panel-s6e3ha8",

-- 
2.55.0

