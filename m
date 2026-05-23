From: Federico Amedeo Izzo <federico@izzo.pro>
Date: Sat, 23 May 2026 12:25:51 +0200
Subject: [PATCH v3 1/2] regulator: qcom-rpmh-regulator: fix regulator mode
 mismatch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260523-qcom-ufs-regulator-support-v3-1-1be2a80a2577@izzo.pro>
References: <20260523-qcom-ufs-regulator-support-v3-0-1be2a80a2577@izzo.pro>
In-Reply-To: <20260523-qcom-ufs-regulator-support-v3-0-1be2a80a2577@izzo.pro>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Casey Connolly <casey.connolly@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Federico Amedeo Izzo <federico@izzo.pro>, 
 Julien Stephan <jstephan@baylibre.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Peng Fan <peng.fan@nxp.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779531961; l=1222;
 i=federico@izzo.pro; s=20251017; h=from:subject:message-id;
 bh=mMP8o/Jp8TjuIhb6AjVw+YfOd0lr+gWRIANKnyT1Oz0=;
 b=gIZUkAKMz6ZTMy516CiaQPLAG9R8/I8NbK7GAp4I2EFiGHFRJpQYZbd3jJ+7UOwIrChwHOb95
 vaUchT4kDDFBGidPyXQuvl0lqIubHKER4VKycbreQF6DLDYPvscjE+G
X-Developer-Key: i=federico@izzo.pro; a=ed25519;
 pk=XfmNfpH48k8jLbId5NKrp0yoKoFb/uLjr97qIxBImBw=
X-Endpoint-Received: by B4 Relay for federico@izzo.pro/20251017 with auth_id=544
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix issue where regulator mode could not be set to the
"regulator-initial-mode" value from dts.

priv->mode was initialized to "regulator-initial-mode", but this could
differ from the actual regulator mode.
In this case rpmh_regulator_vrm_set_mode() would return early, thinking
that the mode is already correct.

Setting an invalid mode on probe solves the issue.

Signed-off-by: Federico Amedeo Izzo <federico@izzo.pro>
---
 drivers/power/regulator/qcom-rpmh-regulator.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/power/regulator/qcom-rpmh-regulator.c b/drivers/power/regulator/qcom-rpmh-regulator.c
index 4d65aae1690..06c3c14c46e 100644
--- a/drivers/power/regulator/qcom-rpmh-regulator.c
+++ b/drivers/power/regulator/qcom-rpmh-regulator.c
@@ -882,8 +882,7 @@ static int rpmh_regulator_probe(struct udevice *dev)
 	priv->hw_data = init_data->hw_data;
 	priv->enabled = -EINVAL;
 	priv->uv = -ENOTRECOVERABLE;
-	if (ofnode_read_u32(dev_ofnode(dev), "regulator-initial-mode", &priv->mode))
-		priv->mode = -EINVAL;
+	priv->mode = -EINVAL;
 
 	plat_data->mode = priv->hw_data->pmic_mode_map;
 	plat_data->mode_count = priv->hw_data->n_modes;

-- 
2.54.0

