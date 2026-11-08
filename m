From: David Heidelberg <david@ixit.cz>
Date: Sun, 08 Nov 2026 12:32:24 +0000
Subject: [PATCH v3 03/10] drm/panel: s6e3ha8: Introduce AMB577PX01 panel
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-crosshatch-panel-v3-3-87dd4ec4f7cc@ixit.cz>
References: <20261108-crosshatch-panel-v3-0-87dd4ec4f7cc@ixit.cz>
In-Reply-To: <20261108-crosshatch-panel-v3-0-87dd4ec4f7cc@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Petr Vorel <petr.vorel@gmail.com>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1409; i=david@ixit.cz;
 h=from:subject:message-id; bh=rCrRxpJWEkA+wgegtsEKS9XsmbU7TwkO+KtW1/Btotk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq8GveDbF7QshoXouh/LyZSBTuq4NEIs+zOioKc
 LJAQQPVuPCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCavBr3gAKCRBgAj/E00kg
 cq8GEADNKdESp1A6wL4mOHYchMs/MZRUz7PXD1yIVwuMZsYRrlFfnW7Vtnty6KiZNb4fEm9RlB2
 3f02KyypqSH7ZVLgwYVO7FPNSHYo8tf0bj9mxXTTgsbEF7AbpmBxIkZLZUdM1WgRkUeftWCi9BS
 ScEZ7p8KQDV7NNtYR6FuBrs3LNM2vbdcvScqTK+yipvMrjSLOGklM0X2hDfMhe3qz8IXF7QtAGy
 H5eDcf2veq7alqn6wuraYVXKsqoOGgMOgGCCFAJPrKWv+yrSe1ZslWgfZug0423iImrM0QdxMeN
 RA49h7Zju9fZ0IdiY9W1viy+iMSnJK5ch1+L7zJsLaDjufovvK5aLxNEqOH6UT4/oA7WnIyl/Ve
 7P2WfzUwxOriP4bXvvJnxc6BtvzuThBpTR+bHD52v5ASgb07dKdfDxGw6oQZAV3uRRUMHdJtoxF
 gjq9tifNLJjqHQCv2ReAGppoJe/UdY5/kP6NOR+97u40p4MCMM7F5J5ZC/pYQnfyo+NSR1VYXw5
 hzYVpBUwYlSZkGjfInlrY0Bo0voduu3tpeAlbHUyxqH7F0c1C93SrKgi/5mCkv2Ik2+7HKZS9qb
 3ErvWkeGek9AG6bDcFoUZknsorek6orvP+7jTo+0lNvEz0LDHBEyKg505vUBh1vjBCzuZXIKzz2
 clY/HWsCfJN0Mkg==
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

