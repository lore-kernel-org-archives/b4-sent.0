From: Alberto Ruiz <aruiz@redhat.com>
Date: Fri, 12 Jun 2026 18:17:19 +0100
Subject: [PATCH 4/4] drm/solomon: use ssd130x_run_cmd_seq() in
 ssd133x_init()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260612-ssd-batchcmd-v1-4-c61e5f7c24bc@redhat.com>
References: <20260612-ssd-batchcmd-v1-0-c61e5f7c24bc@redhat.com>
In-Reply-To: <20260612-ssd-batchcmd-v1-0-c61e5f7c24bc@redhat.com>
To: Javier Martinez Canillas <javierm@redhat.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Alberto Ruiz <aruiz@redhat.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781284654; l=4685;
 i=aruiz@redhat.com; s=20260612; h=from:subject:message-id;
 bh=XfwToVbg4j9ZN1qC9nbgANqi/pUtXOP7mQCa6nqKdJ8=;
 b=XJwJcfnF8igU2BhfRkW7j1SNOE4GoJWnP3S847JBzU00U4jDL4G4BN9GhUO+AIWiF61iRA5bj
 hw3sv5/E1leAbLZxHh1xTx2wBoOUELkgEvDjgM85y7KLahc/CBnTCsd
X-Developer-Key: i=aruiz@redhat.com; a=ed25519;
 pk=d1doFQwve1B/jU9nG5oPl1W5d+t+iFrjkkwk/hD97Ow=
X-Endpoint-Received: by B4 Relay for aruiz@redhat.com/20260612 with auth_id=818
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace individual ssd130x_write_cmd() calls and per-command error
checks with a flat command array dispatched through ssd130x_run_cmd_seq().

Signed-off-by: Alberto Ruiz <aruiz@redhat.com>
---
 drivers/gpu/drm/solomon/ssd130x.c | 136 +++++++++-----------------------------
 1 file changed, 30 insertions(+), 106 deletions(-)

diff --git a/drivers/gpu/drm/solomon/ssd130x.c b/drivers/gpu/drm/solomon/ssd130x.c
index a9914365ad27..9466b7353886 100644
--- a/drivers/gpu/drm/solomon/ssd130x.c
+++ b/drivers/gpu/drm/solomon/ssd130x.c
@@ -583,113 +583,37 @@ static int ssd132x_init(struct ssd130x_device *ssd130x)
 
 static int ssd133x_init(struct ssd130x_device *ssd130x)
 {
-	int ret;
-
-	/* Set color A contrast */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD133X_CONTRAST_A, 0x91);
-	if (ret < 0)
-		return ret;
-
-	/* Set color B contrast */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD133X_CONTRAST_B, 0x50);
-	if (ret < 0)
-		return ret;
-
-	/* Set color C contrast */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD133X_CONTRAST_C, 0x7d);
-	if (ret < 0)
-		return ret;
-
-	/* Set master current */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD133X_SET_MASTER_CURRENT, 0x06);
-	if (ret < 0)
-		return ret;
-
-	/* Set column start and end */
-	ret = ssd130x_write_cmd(ssd130x, 3, SSD133X_SET_COL_RANGE, 0x00, ssd130x->width - 1);
-	if (ret < 0)
-		return ret;
-
-	/* Set row start and end */
-	ret = ssd130x_write_cmd(ssd130x, 3, SSD133X_SET_ROW_RANGE, 0x00, ssd130x->height - 1);
-	if (ret < 0)
-		return ret;
-
-	/*
-	 * Horizontal Address Increment
-	 * Normal order SA,SB,SC (e.g. RGB)
-	 * COM Split Odd Even
-	 * 256 color format
-	 */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD13XX_SET_SEG_REMAP, 0x20);
-	if (ret < 0)
-		return ret;
-
-	/* Set display start and offset */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD133X_SET_DISPLAY_START, 0x00);
-	if (ret < 0)
-		return ret;
-
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD133X_SET_DISPLAY_OFFSET, 0x00);
-	if (ret < 0)
-		return ret;
-
-	/* Set display mode normal */
-	ret = ssd130x_write_cmd(ssd130x, 1, SSD133X_SET_DISPLAY_NORMAL);
-	if (ret < 0)
-		return ret;
-
-	/* Set multiplex ratio value */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD13XX_SET_MULTIPLEX_RATIO, ssd130x->height - 1);
-	if (ret < 0)
-		return ret;
-
-	/* Set master configuration */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD133X_SET_MASTER_CONFIG, 0x8e);
-	if (ret < 0)
-		return ret;
-
-	/* Set power mode */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD133X_POWER_SAVE_MODE, 0x0b);
-	if (ret < 0)
-		return ret;
-
-	/* Set Phase 1 and 2 period */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD133X_PHASES_PERIOD, 0x31);
-	if (ret < 0)
-		return ret;
-
-	/* Set clock divider */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD133X_SET_CLOCK_FREQ, 0xf0);
-	if (ret < 0)
-		return ret;
-
-	/* Set pre-charge A */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD132X_SET_PRECHARGE_A, 0x64);
-	if (ret < 0)
-		return ret;
-
-	/* Set pre-charge B */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD132X_SET_PRECHARGE_B, 0x78);
-	if (ret < 0)
-		return ret;
-
-	/* Set pre-charge C */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD132X_SET_PRECHARGE_C, 0x64);
-	if (ret < 0)
-		return ret;
-
-	/* Set pre-charge level */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD133X_SET_PRECHARGE_VOLTAGE, 0x3a);
-	if (ret < 0)
-		return ret;
-
-	/* Set VCOMH voltage */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD133X_SET_VCOMH_VOLTAGE, 0x3e);
-	if (ret < 0)
-		return ret;
+	const u8 cmds[] = {
+		2, SSD133X_CONTRAST_A, 0x91,
+		2, SSD133X_CONTRAST_B, 0x50,
+		2, SSD133X_CONTRAST_C, 0x7d,
+		2, SSD133X_SET_MASTER_CURRENT, 0x06,
+		3, SSD133X_SET_COL_RANGE, 0x00, ssd130x->width - 1,
+		3, SSD133X_SET_ROW_RANGE, 0x00, ssd130x->height - 1,
+		/*
+		 * Horizontal Address Increment
+		 * Normal order SA,SB,SC (e.g. RGB)
+		 * COM Split Odd Even
+		 * 256 color format
+		 */
+		2, SSD13XX_SET_SEG_REMAP, 0x20,
+		2, SSD133X_SET_DISPLAY_START, 0x00,
+		2, SSD133X_SET_DISPLAY_OFFSET, 0x00,
+		1, SSD133X_SET_DISPLAY_NORMAL,
+		2, SSD13XX_SET_MULTIPLEX_RATIO, ssd130x->height - 1,
+		2, SSD133X_SET_MASTER_CONFIG, 0x8e,
+		2, SSD133X_POWER_SAVE_MODE, 0x0b,
+		2, SSD133X_PHASES_PERIOD, 0x31,
+		2, SSD133X_SET_CLOCK_FREQ, 0xf0,
+		2, SSD132X_SET_PRECHARGE_A, 0x64,
+		2, SSD132X_SET_PRECHARGE_B, 0x78,
+		2, SSD132X_SET_PRECHARGE_C, 0x64,
+		2, SSD133X_SET_PRECHARGE_VOLTAGE, 0x3a,
+		2, SSD133X_SET_VCOMH_VOLTAGE, 0x3e,
+		0,
+	};
 
-	return 0;
+	return ssd130x_run_cmd_seq(ssd130x, cmds);
 }
 
 static int ssd130x_update_rect(struct ssd130x_device *ssd130x,

-- 
2.53.0

