From: Janne Grunau <j@jannau.net>
Date: Wed, 16 Apr 2025 22:25:27 +0200
Subject: [PATCH 1/4] drm: adp: Use spin_lock_irqsave for drm device
 event_lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250416-drm_adp_fixes-v1-1-772699f13293@jannau.net>
References: <20250416-drm_adp_fixes-v1-0-772699f13293@jannau.net>
In-Reply-To: <20250416-drm_adp_fixes-v1-0-772699f13293@jannau.net>
To: Sasha Finkelstein <fnkl.kernel@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Neal Gompa <neal@gompa.dev>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Dmitry Baryshkov <lumag@kernel.org>
Cc: dri-devel@lists.freedesktop.org, asahi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1532; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=ly1cyHZpQncU8CCBgaANZV7W5N8jcPXVe2vzXSXplD4=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhgwGIftXfJ+f5ahOn5pQYii11/ncc6PfC/zfmSo27xaqk
 vm1slG6o5SFQYyLQVZMkSVJ+2UHw+oaxZjaB2Ewc1iZQIYwcHEKwEQ+KTH8z1uyXPrpRYdL+xaK
 XEh99Xi1kHLfJtvKDQbHXbd1ft3pfoeR4b2d+ed1ehucMjX/Lt3g+aIkWmnVvaORn66U8C16m5a
 ZzAwA
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The lock is used in the interrupt handler so use spin_lock_irqsave to
disable interrupts and avoid deadlocks with the irq handler.

Fixes: 332122eba628 ("drm: adp: Add Apple Display Pipe driver")
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

