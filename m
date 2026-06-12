From: Alberto Ruiz <aruiz@redhat.com>
Date: Fri, 12 Jun 2026 18:17:17 +0100
Subject: [PATCH 2/4] drm/solomon: use ssd130x_run_cmd_seq() in
 ssd130x_init()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260612-ssd-batchcmd-v1-2-c61e5f7c24bc@redhat.com>
References: <20260612-ssd-batchcmd-v1-0-c61e5f7c24bc@redhat.com>
In-Reply-To: <20260612-ssd-batchcmd-v1-0-c61e5f7c24bc@redhat.com>
To: Javier Martinez Canillas <javierm@redhat.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Alberto Ruiz <aruiz@redhat.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781284654; l=4004;
 i=aruiz@redhat.com; s=20260612; h=from:subject:message-id;
 bh=gZa0wjgl3jdxMz1F4mFULp9wZ5YC2K4Itt+tHw8cQB8=;
 b=4xf4ZS4zZF9j1RQPTE7/9TsSSnCcEr++yMoeLqj0kSRxPyBe72uFKs1tMd8rUr841ckP69dTF
 T4YqMwA5+gbDMfu0D1c3XHsWIJdNjtwblwzT3eYzTHkjCHHWk6W3ZKq
X-Developer-Key: i=aruiz@redhat.com; a=ed25519;
 pk=d1doFQwve1B/jU9nG5oPl1W5d+t+iFrjkkwk/hD97Ow=
X-Endpoint-Received: by B4 Relay for aruiz@redhat.com/20260612 with auth_id=818
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace individual ssd130x_write_cmd() calls and per-command error
checks with flat command arrays dispatched through ssd130x_run_cmd_seq().

Signed-off-by: Alberto Ruiz <aruiz@redhat.com>
---
 drivers/gpu/drm/solomon/ssd130x.c | 72 ++++++++++++++-------------------------
 1 file changed, 26 insertions(+), 46 deletions(-)

diff --git a/drivers/gpu/drm/solomon/ssd130x.c b/drivers/gpu/drm/solomon/ssd130x.c
index 46e2c277a9bf..ec6bf9f6c7c8 100644
--- a/drivers/gpu/drm/solomon/ssd130x.c
+++ b/drivers/gpu/drm/solomon/ssd130x.c
@@ -451,39 +451,25 @@ static int ssd130x_init(struct ssd130x_device *ssd130x)
 	bool scan_mode;
 	int ret;
 
-	/* Set initial contrast */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD13XX_CONTRAST, ssd130x->contrast);
-	if (ret < 0)
-		return ret;
-
-	/* Set segment re-map */
 	seg_remap = (SSD13XX_SET_SEG_REMAP |
-		     SSD13XX_SET_SEG_REMAP_SET(ssd130x->seg_remap));
-	ret = ssd130x_write_cmd(ssd130x, 1, seg_remap);
-	if (ret < 0)
-		return ret;
-
-	/* Set COM direction */
+		SSD13XX_SET_SEG_REMAP_SET(ssd130x->seg_remap));
 	com_invdir = (SSD130X_SET_COM_SCAN_DIR |
-		      SSD130X_SET_COM_SCAN_DIR_SET(ssd130x->com_invdir));
-	ret = ssd130x_write_cmd(ssd130x,  1, com_invdir);
-	if (ret < 0)
-		return ret;
-
-	/* Set multiplex ratio value */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD13XX_SET_MULTIPLEX_RATIO, ssd130x->height - 1);
-	if (ret < 0)
-		return ret;
-
-	/* set display offset value */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD130X_SET_DISPLAY_OFFSET, ssd130x->com_offset);
-	if (ret < 0)
-		return ret;
-
-	/* Set clock frequency */
+		SSD130X_SET_COM_SCAN_DIR_SET(ssd130x->com_invdir));
 	dclk = (SSD130X_SET_CLOCK_DIV_SET(ssd130x->dclk_div - 1) |
 		SSD130X_SET_CLOCK_FREQ_SET(ssd130x->dclk_frq));
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD130X_SET_CLOCK_FREQ, dclk);
+
+	const u8 *cmds = (const u8[]) {
+		2, SSD13XX_CONTRAST, ssd130x->contrast,
+		/* Set segment re-map */
+		1, seg_remap,
+		/* Set COM scan direction */
+		1, com_invdir,
+		2, SSD13XX_SET_MULTIPLEX_RATIO, ssd130x->height - 1,
+		2, SSD130X_SET_DISPLAY_OFFSET, ssd130x->com_offset,
+		2, SSD130X_SET_CLOCK_FREQ, dclk,
+		0,
+	};
+	ret = ssd130x_run_cmd_seq(ssd130x, cmds);
 	if (ret < 0)
 		return ret;
 
@@ -505,36 +491,30 @@ static int ssd130x_init(struct ssd130x_device *ssd130x)
 	/* Set precharge period in number of ticks from the internal clock */
 	precharge = (SSD130X_SET_PRECHARGE_PERIOD1_SET(ssd130x->prechargep1) |
 		     SSD130X_SET_PRECHARGE_PERIOD2_SET(ssd130x->prechargep2));
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD130X_SET_PRECHARGE_PERIOD, precharge);
-	if (ret < 0)
-		return ret;
 
-	/* Set COM pins configuration */
-	compins = BIT(1);
-	/*
+	/* Set COM pins configuration
+	 *
 	 * The COM scan mode field values are the inverse of the boolean DT
 	 * property "solomon,com-seq". The value 0b means scan from COM0 to
 	 * COM[N - 1] while 1b means scan from COM[N - 1] to COM0.
 	 */
 	scan_mode = !ssd130x->com_seq;
-	compins |= (SSD130X_SET_COM_PINS_CONFIG1_SET(scan_mode) |
+	compins = BIT(1) | (SSD130X_SET_COM_PINS_CONFIG1_SET(scan_mode) |
 		    SSD130X_SET_COM_PINS_CONFIG2_SET(ssd130x->com_lrremap));
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD130X_SET_COM_PINS_CONFIG, compins);
-	if (ret < 0)
-		return ret;
-
-	/* Set VCOMH */
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD130X_SET_VCOMH, ssd130x->vcomh);
-	if (ret < 0)
-		return ret;
 
 	/* Turn on the DC-DC Charge Pump */
 	chargepump = BIT(4);
-
 	if (ssd130x->device_info->need_chargepump)
 		chargepump |= BIT(2);
 
-	ret = ssd130x_write_cmd(ssd130x, 2, SSD130X_CHARGE_PUMP, chargepump);
+	cmds = (const u8[]) {
+		2, SSD130X_SET_PRECHARGE_PERIOD, precharge,
+		2, SSD130X_SET_COM_PINS_CONFIG, compins,
+		2, SSD130X_SET_VCOMH, ssd130x->vcomh,
+		2, SSD130X_CHARGE_PUMP, chargepump,
+		0
+	};
+	ret = ssd130x_run_cmd_seq(ssd130x, cmds);
 	if (ret < 0)
 		return ret;
 

-- 
2.53.0

