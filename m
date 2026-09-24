From: David Heidelberg <david@ixit.cz>
Date: Thu, 24 Sep 2026 16:01:32 +0200
Subject: [PATCH v2 04/11] drm/panel: s6e3ha8: Introduce AMB577PX01 panel
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-crosshatch-panel-v2-4-08d5c7bf72fc@ixit.cz>
References: <20260924-crosshatch-panel-v2-0-08d5c7bf72fc@ixit.cz>
In-Reply-To: <20260924-crosshatch-panel-v2-0-08d5c7bf72fc@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Petr Vorel <petr.vorel@gmail.com>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1427; i=david@ixit.cz;
 h=from:subject:message-id; bh=I8au9RHlXJp0sQXsphkjbyxxUnhlBLGtjFxIrmaazt0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtS09Aj+5xy06Bf/ZdEsKwwYMBKVtqAAr7raY4
 nhNkZ++z5aJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarUtPQAKCRBgAj/E00kg
 ck99D/9e5+IE8uB8z3x+xQs5FrYOzurX9IZsv1qZOtlKE4cVukeXZ0rjtTsGLaUPgAjTfTj9802
 4f8RwZevpFtnZ4emf5+G6YJAGuSSMb7yqnzI/PtMoQ1fi98ppDp05CEtEE5v4fS5mpHxbhV7R0z
 +idByYtgNXSGxS7vl5JZNZvEmdvl1MzfAsPkt1BriLFryGHn0Cv1j5x+xTWibTsxc02sNlipa74
 FnhD07JXH6cSomAXxHHr0YlNTLNgXTCSL2sfaE+RszyekaV4fuX2crU7vpB44cOQURSkqnMh3F+
 te23YneQoeA/8ZqPoga38qAmkRztFdwcdwjQ9aPz0bcX0AGt5hIhlDBz6uYOxRI/C1Xd8glRZOI
 lpuouukszROvnGHNP2CJ1stuLyFlw/67I2SYIqYLSUrT5g9tdn2F+cf3FEnJYLbAKVYXUiACgBV
 sGW4NYVjwsp//GqDVTZZEqNl46lCECLOGq0rRQvgx68wqQPAau+nOMOOLryc3nY5GVkOKIJhODT
 t5USd5XlqvvVZG+wwpj0p10dBmxKkjKN5HQSq4//mhXS/hQkKQxcJqJo1Z34S1hSgnbvew7jWbA
 DiSSEPCexL37VPKq18niYFPpUBQKcDZDtfaiOl0VNd0GRPhVjxWVzhclvs9tg4IGvAmI1AWi9nV
 bj7ABNci0h14xww==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

S6E3HA8 is the DDIC, while the panel used on the Samsung Galaxy S9 is
the Samsung AMB577PX01. Match on the new panel compatible, and keep
the deprecated DDIC-only one working for existing devicetrees.

Assisted-by: LLM
Reviewed-by: Petr Vorel <petr.vorel@gmail.com>
Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c b/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
index 835121b322f4a..a0015ac0e2782 100644
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

