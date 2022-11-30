From: Noralf Trønnes <noralf@tronnes.org>
Date: Wed, 30 Nov 2022 20:26:50 +0100
Subject: [PATCH v2 2/6] drm/gud: Don't retry a failed framebuffer flush
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20221122-gud-shadow-plane-v2-2-435037990a83@tronnes.org>
References: <20221122-gud-shadow-plane-v2-0-435037990a83@tronnes.org>
In-Reply-To: <20221122-gud-shadow-plane-v2-0-435037990a83@tronnes.org>
To: Thomas Zimmermann <tzimmermann@suse.de>, Javier Martinez Canillas <javierm@redhat.com>,
 dri-devel@lists.freedesktop.org, Maxime Ripard <mripard@kernel.org>, stable@vger.kernel.org,
 Noralf Trønnes <noralf@tronnes.org>
X-Mailer: b4 0.11.0-dev-cc6f6
X-Developer-Signature: v=1; a=ed25519-sha256; t=1669836415; l=3429;
 i=noralf@tronnes.org; s=20221122; h=from:subject:message-id;
 bh=JgNUrup5eFPg7AS3RcWGGXUbXcgPsvtdWIu52mnjsLw=;
 b=w9GkJdswoEZIvAEFarkHPd4n6fskkYVBIOS83rlWtU2/XJpmAYZ+ubw6D+QXPd711JJ4XHvhSsD+
 2aFQNnTTCD7KqPPMjVoPBvaD1FJR3nSZN5A067xrRSv0+KMhgr6e
X-Developer-Key: i=noralf@tronnes.org; a=ed25519;
 pk=0o9is4iddvvlrY3yON5SVtAbgPnVs0LfQsjfqR2Hvz8=
X-Endpoint-Received: by B4 Submission Endpoint for noralf@tronnes.org/20221122 with auth_id=8
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

If a framebuffer flush fails the driver will do one retry by requeing the
worker. Currently the worker is used even for synchronous flushing, but a
later patch will inline it, so this needs to change. Thinking about how to
solve this I came to the conclusion that this retry mechanism was a fix
for a problem that was only in the mind of the developer (me) and not
something that solved a real problem.

So let's remove this for now and revisit later should it become necessary.
gud_add_damage() has now only one caller so it can be inlined.

Reviewed-by: Javier Martinez Canillas <javierm@redhat.com>
Reviewed-by: Thomas Zimmermann <tzimmermann@suse.de>
Signed-off-by: Noralf Trønnes <noralf@tronnes.org>
---
 drivers/gpu/drm/gud/gud_pipe.c | 48 +++++++-----------------------------------
 1 file changed, 8 insertions(+), 40 deletions(-)

diff --git a/drivers/gpu/drm/gud/gud_pipe.c b/drivers/gpu/drm/gud/gud_pipe.c
index 61f4abaf1811..ff1358815af5 100644
--- a/drivers/gpu/drm/gud/gud_pipe.c
+++ b/drivers/gpu/drm/gud/gud_pipe.c
@@ -333,37 +333,6 @@ void gud_clear_damage(struct gud_device *gdrm)
 	gdrm->damage.y2 = 0;
 }
 
-static void gud_add_damage(struct gud_device *gdrm, struct drm_rect *damage)
-{
-	gdrm->damage.x1 = min(gdrm->damage.x1, damage->x1);
-	gdrm->damage.y1 = min(gdrm->damage.y1, damage->y1);
-	gdrm->damage.x2 = max(gdrm->damage.x2, damage->x2);
-	gdrm->damage.y2 = max(gdrm->damage.y2, damage->y2);
-}
-
-static void gud_retry_failed_flush(struct gud_device *gdrm, struct drm_framebuffer *fb,
-				   struct drm_rect *damage)
-{
-	/*
-	 * pipe_update waits for the worker when the display mode is going to change.
-	 * This ensures that the width and height is still the same making it safe to
-	 * add back the damage.
-	 */
-
-	mutex_lock(&gdrm->damage_lock);
-	if (!gdrm->fb) {
-		drm_framebuffer_get(fb);
-		gdrm->fb = fb;
-	}
-	gud_add_damage(gdrm, damage);
-	mutex_unlock(&gdrm->damage_lock);
-
-	/* Retry only once to avoid a possible storm in case of continues errors. */
-	if (!gdrm->prev_flush_failed)
-		queue_work(system_long_wq, &gdrm->work);
-	gdrm->prev_flush_failed = true;
-}
-
 void gud_flush_work(struct work_struct *work)
 {
 	struct gud_device *gdrm = container_of(work, struct gud_device, work);
@@ -407,14 +376,10 @@ void gud_flush_work(struct work_struct *work)
 		ret = gud_flush_rect(gdrm, fb, format, &rect);
 		if (ret) {
 			if (ret != -ENODEV && ret != -ECONNRESET &&
-			    ret != -ESHUTDOWN && ret != -EPROTO) {
-				bool prev_flush_failed = gdrm->prev_flush_failed;
-
-				gud_retry_failed_flush(gdrm, fb, &damage);
-				if (!prev_flush_failed)
-					dev_err_ratelimited(fb->dev->dev,
-							    "Failed to flush framebuffer: error=%d\n", ret);
-			}
+			    ret != -ESHUTDOWN && ret != -EPROTO)
+				dev_err_ratelimited(fb->dev->dev,
+						    "Failed to flush framebuffer: error=%d\n", ret);
+			gdrm->prev_flush_failed = true;
 			break;
 		}
 
@@ -439,7 +404,10 @@ static void gud_fb_queue_damage(struct gud_device *gdrm, struct drm_framebuffer
 		gdrm->fb = fb;
 	}
 
-	gud_add_damage(gdrm, damage);
+	gdrm->damage.x1 = min(gdrm->damage.x1, damage->x1);
+	gdrm->damage.y1 = min(gdrm->damage.y1, damage->y1);
+	gdrm->damage.x2 = max(gdrm->damage.x2, damage->x2);
+	gdrm->damage.y2 = max(gdrm->damage.y2, damage->y2);
 
 	mutex_unlock(&gdrm->damage_lock);
 

-- 
2.34.1
