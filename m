From: "Jason-JH.Lin" <jason-jh.lin@mediatek.com>
Date: Thu, 24 Oct 2024 18:30:01 +0800
Subject: [PATCH] Revert "drm/mipi-dsi: Set the fwnode for mipi_dsi_device"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241024-fixup-5-15-v1-1-62f21a32b5a5@mediatek.com>
X-B4-Tracking: v=1; b=H4sIAKghGmcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDINZNy6woLdA11TU01TVNS0kxs0hJTDU3MFcCaigoSgXKgg2Ljq2tBQC
 +m6XyXAAAAA==
To: stable@vger.kernel.org, Saravana Kannan <saravanak@google.com>
Cc: Greg KH <gregkh@linuxfoundation.org>, 
 Seiya Wang <seiya.wang@mediatek.com>, 
 "Jason-JH.Lin" <jason-jh.lin@mediatek.com>, 
 Singo Chang <singo.chang@mediatek.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729765825; l=1663;
 i=jason-jh.lin@mediatek.com; s=20240718; h=from:subject:message-id;
 bh=8ojWfopcwKup0laonpHcvKr5CiOjB346s5EoLYHs1DY=;
 b=78uPs8dIh0Y+kRKnDp4pFGRm7Ym3IYjRmcCb95SheqtFTJPlTaHxCLprxsjIhwqKTCqScWfkS
 t6Y7S6WBIDCBAG+IQvNJTBKsdWcPY7F3f4aRlquRgVQ1bMvKXxW9tNJ
X-Developer-Key: i=jason-jh.lin@mediatek.com; a=ed25519;
 pk=7Hn+BnFBlPrluT5ks5tKVWb3f7O/bMBs6qEemVJwqOo=
X-Endpoint-Received: by B4 Relay for jason-jh.lin@mediatek.com/20240718 with auth_id=187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This reverts commit ac88a1f41f93499df6f50fd18ea835e6ff4f3200.

Reason for revert:
1. The commit [1] does not land on linux-5.15, so this patch does not
fix anything.

2. Since the fw_device improvements series [2] does not land on
linux-5.15, using device_set_fwnode() causes the panel to flash during
bootup.

Incorrect link management may lead to incorrect device initialization,
affecting firmware node links and consumer relationships.
The fwnode setting of panel to the DSI device would cause a DSI
initialization error without series[2], so this patch was reverted to
avoid using the incomplete fw_devlink functionality.

[1] commit 3fb16866b51d ("driver core: fw_devlink: Make cycle detection more robust")
[2] Link: https://lore.kernel.org/all/20230207014207.1678715-1-saravanak@google.com

Cc: stable@vger.kernel.org # 5.15.169
Signed-off-by: Jason-JH.Lin <jason-jh.lin@mediatek.com>
---
 drivers/gpu/drm/drm_mipi_dsi.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/drm_mipi_dsi.c b/drivers/gpu/drm/drm_mipi_dsi.c
index 24606b632009..468a3a7cb6a5 100644
--- a/drivers/gpu/drm/drm_mipi_dsi.c
+++ b/drivers/gpu/drm/drm_mipi_dsi.c
@@ -221,7 +221,7 @@ mipi_dsi_device_register_full(struct mipi_dsi_host *host,
 		return dsi;
 	}
 
-	device_set_node(&dsi->dev, of_fwnode_handle(info->node));
+	dsi->dev.of_node = info->node;
 	dsi->channel = info->channel;
 	strlcpy(dsi->name, info->type, sizeof(dsi->name));
 

---
base-commit: 74cdd62cb4706515b454ce5bacb73b566c1d1bcf
change-id: 20241024-fixup-5-15-5fdd68dae707

Best regards,
-- 
Jason-JH.Lin <jason-jh.lin@mediatek.com>

