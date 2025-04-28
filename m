From: Janne Grunau <j@jannau.net>
Date: Mon, 28 Apr 2025 13:37:13 +0200
Subject: [PATCH v2 1/4] drm: adp: Use spin_lock_irqsave for drm device
 event_lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250428-drm_adp_fixes-v2-1-912e081e55d8@jannau.net>
References: <20250428-drm_adp_fixes-v2-0-912e081e55d8@jannau.net>
In-Reply-To: <20250428-drm_adp_fixes-v2-0-912e081e55d8@jannau.net>
To: Sasha Finkelstein <fnkl.kernel@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Neal Gompa <neal@gompa.dev>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Dmitry Baryshkov <lumag@kernel.org>, Janne Grunau <j@jannau.net>
Cc: dri-devel@lists.freedesktop.org, asahi@lists.linux.dev, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1587; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=f9CWUT6BHio9yznivZy0rXZk6w93Ok71Ww97RIoMSA0=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhgz+jBKf1WUvsgS3G96a4Dr19KNNkSLcNuwLY056+2/re
 OLwe5lWRykLgxgXg6yYIkuS9ssOhtU1ijG1D8Jg5rAygQxh4OIUgIkkOjIytG9MuGCsvi6n+Rnj
 wSX77bdYVN7dUS1Rvrzn3bmljV5lGxj+52UX7A5N1wrZ4j3p9cWrB7dY9aV1da5pT3v6p9ZU82Y
 eAwA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The lock is used in the interrupt handler so use spin_lock_irqsave to
disable interrupts and avoid deadlocks with the irq handler.

Fixes: 332122eba628 ("drm: adp: Add Apple Display Pipe driver")
Reviewed-by: Alyssa Rosenzweig <alyssa@rosenzweig.io>
Signed-off-by: Janne Grunau <j@jannau.net>
---
 drivers/gpu/drm/adp/adp_drv.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/adp/adp_drv.c b/drivers/gpu/drm/adp/adp_drv.c
index c98c647f981d5383149647126762a5cdec8f4e4b..157298a8ff42b95275411dd4a7a0c70780fd86fd 100644
--- a/drivers/gpu/drm/adp/adp_drv.c
+++ b/drivers/gpu/drm/adp/adp_drv.c
@@ -310,6 +310,7 @@ static void adp_crtc_atomic_flush(struct drm_crtc *crtc,
 				  struct drm_atomic_state *state)
 {
 	u32 frame_num = 1;
+	unsigned long flags;
 	struct adp_drv_private *adp = crtc_to_adp(crtc);
 	struct drm_crtc_state *new_state = drm_atomic_get_new_crtc_state(state, crtc);
 	u64 new_size = ALIGN(new_state->mode.hdisplay *
@@ -330,13 +331,13 @@ static void adp_crtc_atomic_flush(struct drm_crtc *crtc,
 	}
 	writel(ADBE_FIFO_SYNC | frame_num, adp->be + ADBE_FIFO);
 	//FIXME: use adbe flush interrupt
-	spin_lock_irq(&crtc->dev->event_lock);
+	spin_lock_irqsave(&crtc->dev->event_lock, flags);
 	if (crtc->state->event) {
 		drm_crtc_vblank_get(crtc);
 		adp->event = crtc->state->event;
 	}
 	crtc->state->event = NULL;
-	spin_unlock_irq(&crtc->dev->event_lock);
+	spin_unlock_irqrestore(&crtc->dev->event_lock, flags);
 }
 
 static const struct drm_crtc_funcs adp_crtc_funcs = {

-- 
2.49.0

