From: Alberto Ruiz <aruiz@redhat.com>
Date: Fri, 12 Jun 2026 18:17:18 +0100
Subject: [PATCH 3/4] drm/solomon: use ssd130x_run_cmd_seq() in
 ssd132x_init()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260612-ssd-batchcmd-v1-3-c61e5f7c24bc@redhat.com>
References: <20260612-ssd-batchcmd-v1-0-c61e5f7c24bc@redhat.com>
In-Reply-To: <20260612-ssd-batchcmd-v1-0-c61e5f7c24bc@redhat.com>
To: Javier Martinez Canillas <javierm@redhat.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Alberto Ruiz <aruiz@redhat.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781284654; l=4164;
 i=aruiz@redhat.com; s=20260612; h=from:subject:message-id;
 bh=ZxVXIKcONNxgJZO+E12kfo8TLu8zbFtcaxkY6PeGK/0=;
 b=Rgp07uO1vB8/K6eVI0Dy6qTinRPB49rkb668M2Vdk6yJwDqe1/QOoMyo1D0d9Ozw52J7H7GmW
 7kyiW9863txD+O8P7jAtIrhHdD2GQ5rjVvyGdGSqB8PELvQy/D+EFvO
X-Developer-Key: i=aruiz@redhat.com; a=ed25519;
 pk=d1doFQwve1B/jU9nG5oPl1W5d+t+iFrjkkwk/hD97Ow=
X-Endpoint-Received: by B4 Relay for aruiz@redhat.com/20260612 with auth_id=818
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace individual ssd130x_write_cmd() calls and per-command error
checks with a flat command array dispatched through ssd130x_run_cmd_seq().

Signed-off-by: Alberto Ruiz <aruiz@redhat.com>
---
 drivers/gpu/drm/solomon/ssd130x.c | 112 +++++++++-----------------------------
 1 file changed, 27 insertions(+), 85 deletions(-)

diff --git a/drivers/gpu/drm/solomon/ssd130x.c b/drivers/gpu/drm/solomon/ssd130x.c
index ec6bf9f6c7c8..a9914365ad27 100644
--- a/drivers/gpu/drm/solomon/ssd130x.c
+++ b/drivers/gpu/drm/solomon/ssd130x.c
@@ -551,92 +551,34 @@ static int ssd130x_init(struct ssd130x_device *ssd130x)
 
 static int ssd132x_init(struct ssd130x_device *ssd130x)
 {
-	int ret;
-
-	/* Set initial contrast */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD13XX_CONTRAST, 0x80);
-	if (ret < 0)
-		return ret;
-
-	/* Set column start and end */
-	ret = ssd130x_write_cmd(ssd130x, 3, SSD132X_SET_COL_RANGE, 0x00,
-				ssd130x->width / SSD132X_SEGMENT_WIDTH - 1);
-	if (ret < 0)
-		return ret;
-
-	/* Set row start and end */
-	ret = ssd130x_write_cmd(ssd130x, 3, SSD132X_SET_ROW_RANGE, 0x00, ssd130x->height - 1);
-	if (ret < 0)
-		return ret;
-	/*
-	 * Horizontal Address Increment
-	 * Re-map for Column Address, Nibble and COM
-	 * COM Split Odd Even
-	 */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD13XX_SET_SEG_REMAP, 0x53);
-	if (ret < 0)
-		return ret;
-
-	/* Set display start and offset */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD132X_SET_DISPLAY_START, 0x00);
-	if (ret < 0)
-		return ret;
-
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD132X_SET_DISPLAY_OFFSET, 0x00);
-	if (ret < 0)
-		return ret;
-
-	/* Set display mode normal */
-	ret = ssd130x_write_cmd(ssd130x, 1, SSD132X_SET_DISPLAY_NORMAL);
-	if (ret < 0)
-		return ret;
-
-	/* Set multiplex ratio value */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD13XX_SET_MULTIPLEX_RATIO, ssd130x->height - 1);
-	if (ret < 0)
-		return ret;
-
-	/* Set phase length */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD132X_SET_PHASE_LENGTH, 0x55);
-	if (ret < 0)
-		return ret;
-
-	/* Select default linear gray scale table */
-	ret = ssd130x_write_cmd(ssd130x, 1, SSD132X_SELECT_DEFAULT_TABLE);
-	if (ret < 0)
-		return ret;
-
-	/* Set clock frequency */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD132X_SET_CLOCK_FREQ, 0x01);
-	if (ret < 0)
-		return ret;
-
-	/* Enable internal VDD regulator */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD132X_SET_FUNCTION_SELECT_A, 0x1);
-	if (ret < 0)
-		return ret;
-
-	/* Set pre-charge period */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD132X_SET_PRECHARGE_PERIOD, 0x01);
-	if (ret < 0)
-		return ret;
-
-	/* Set pre-charge voltage */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD132X_SET_PRECHARGE_VOLTAGE, 0x08);
-	if (ret < 0)
-		return ret;
-
-	/* Set VCOMH voltage */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD130X_SET_VCOMH_VOLTAGE, 0x07);
-	if (ret < 0)
-		return ret;
-
-	/* Enable second pre-charge and internal VSL */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD132X_SET_FUNCTION_SELECT_B, 0x62);
-	if (ret < 0)
-		return ret;
+	const u8 cmds[] = {
+		2, SSD13XX_CONTRAST, 0x80,
+		3, SSD132X_SET_COL_RANGE, 0x00,
+					ssd130x->width / SSD132X_SEGMENT_WIDTH - 1,
+		3, SSD132X_SET_ROW_RANGE, 0x00, ssd130x->height - 1,
+		/*
+		 * Horizontal Address Increment
+		 * Re-map for Column Address, Nibble and COM
+		 * COM Split Odd Even
+		 */
+		2, SSD13XX_SET_SEG_REMAP, 0x53,
+		2, SSD132X_SET_DISPLAY_START, 0x00,
+		2, SSD132X_SET_DISPLAY_OFFSET, 0x00,
+		1, SSD132X_SET_DISPLAY_NORMAL,
+		2, SSD13XX_SET_MULTIPLEX_RATIO, ssd130x->height - 1,
+		2, SSD132X_SET_PHASE_LENGTH, 0x55,
+		1, SSD132X_SELECT_DEFAULT_TABLE,
+		2, SSD132X_SET_CLOCK_FREQ, 0x01,
+		2, SSD132X_SET_FUNCTION_SELECT_A, 0x1,
+		2, SSD132X_SET_PRECHARGE_PERIOD, 0x01,
+		2, SSD132X_SET_PRECHARGE_VOLTAGE, 0x08,
+		2, SSD130X_SET_VCOMH_VOLTAGE, 0x07,
+		/* Enable second pre-charge and internal VSL */
+		2, SSD132X_SET_FUNCTION_SELECT_B, 0x62,
+		0,
+	};
 
-	return 0;
+	return ssd130x_run_cmd_seq(ssd130x, cmds);
 }
 
 static int ssd133x_init(struct ssd130x_device *ssd130x)

-- 
2.53.0

