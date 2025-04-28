From: Janne Grunau <j@jannau.net>
Date: Mon, 28 Apr 2025 13:37:14 +0200
Subject: [PATCH v2 2/4] drm: adp: Handle drm_crtc_vblank_get() errors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250428-drm_adp_fixes-v2-2-912e081e55d8@jannau.net>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3657; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=S2S57facW1xFgxZeuc4im1/AAPnKrPNAP85dlm5EOsE=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhgz+jBKLEEnFrc5nVGY0XzVb8iFGrLP6FONys+cTfUI1j
 t/d4MvVUcrCIMbFICumyJKk/bKDYXWNYkztgzCYOaxMIEMYuDgFYCKT4hgZtl79uHPPGwNtCdkp
 8X+at+85pVB08jvnYaOucxu1f3z+KMjIcH5hu4PdB9EW19NrVl80jL1mlMry7g2rd3xZUarc/cV
 7mQE=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

drm_crtc_vblank_get() may fail when it's called before
drm_crtc_vblank_on() on a resetted CRTC. This occurs in
drm_crtc_helper_funcs' atomic_flush() calls after
drm_atomic_helper_crtc_reset() for example directly after probe.
Send the vblank event directly in such cases.
Avoids following warning in the subsequent drm_crtc_vblank_put() call
from the vblank irq handler as below:

adp 228200000.display-pipe: [drm] drm_WARN_ON(atomic_read(&vblank->refcount) == 0)
WARNING: CPU: 5 PID: 1206 at drivers/gpu/drm/drm_vblank.c:1247 drm_vblank_put+0x158/0x170
Modules linked in: uinput nft_fib_inet nft_fib_ipv4 nft_fib_ipv6 nft_fib nft_reject_inet nf_reject_ipv6 nft_reject nft_ct nft_chain_nat nf_nat videodev drm_dma_helper mc apple_soc_cpufreq drm_display_helper leds_pwm phram
CPU: 5 UID: 0 PID: 1206 Comm: systemctl Not tainted 6.14.2-asahi+ #asahi-dev
Hardware name: Apple MacBook Pro (13-inch, M2, 2022) (DT)
pstate: 614000c5 (nZCv daIF +PAN -UAO -TCO +DIT -SSBS BTYPE=--)
pc : drm_vblank_put+0x158/0x170
lr : drm_vblank_put+0x158/0x170
sp : ffffc00082aa7e70
x29: ffffc00082aa7e70 x28: ffff80003419e000 x27: ffff80003419e000
x26: 0000000000000001 x25: 0000000000012400 x24: 0000000000000066
x23: ffff800033fc8800 x22: 0000000000000000 x21: ffff800029688e70
x20: ffff800029688000 x19: ffff800029688000 x18: 0000000000000000
x17: ffffc0015c868000 x16: 0000000000000020 x15: 0000000000000004
x14: 0000000000000000 x13: 0000000000000001 x12: ffffc000825b3a90
x11: ffffc00082960e88 x10: ffffc00081b0ec88 x9 : ffffc0008017d0ec
x8 : 000000000002ffe8 x7 : fefefefefefefefe x6 : ffffc00081bbec88
x5 : ffff8001de237548 x4 : 0000000000000000 x3 : ffffc0015c868000
x2 : 0000000000000000 x1 : 0000000000000000 x0 : ffff80003419e000
Call trace:
 drm_vblank_put+0x158/0x170 (P)
 drm_crtc_vblank_put+0x24/0x38
 adp_fe_irq+0xd8/0xe8 [adpdrm]
 __handle_irq_event_percpu+0x94/0x318
 handle_irq_event+0x54/0xd0
 handle_fasteoi_irq+0xa8/0x240
 handle_irq_desc+0x3c/0x68
 generic_handle_domain_irq+0x24/0x40

Signed-off-by: Janne Grunau <j@jannau.net>

------------------------ >8 ------------------------
Changes in v2:
- clear `crtc->state->event` only if non-NULL
- use a temporary variable to clear `crtc->state->event` before sending
  it

Modifying `crtc->state->event` here is fine as crtc->mutex is locked by
the non-async atomic commit. In retrospect this looks so obvious that it
doesn't warrant a comment in the file.
---
 drivers/gpu/drm/adp/adp_drv.c | 16 +++++++++++-----
 1 file changed, 11 insertions(+), 5 deletions(-)

diff --git a/drivers/gpu/drm/adp/adp_drv.c b/drivers/gpu/drm/adp/adp_drv.c
index 157298a8ff42b95275411dd4a7a0c70780fd86fd..bdf27ee742ea01759b5d571a21b527687ffcada7 100644
--- a/drivers/gpu/drm/adp/adp_drv.c
+++ b/drivers/gpu/drm/adp/adp_drv.c
@@ -331,13 +331,19 @@ static void adp_crtc_atomic_flush(struct drm_crtc *crtc,
 	}
 	writel(ADBE_FIFO_SYNC | frame_num, adp->be + ADBE_FIFO);
 	//FIXME: use adbe flush interrupt
-	spin_lock_irqsave(&crtc->dev->event_lock, flags);
 	if (crtc->state->event) {
-		drm_crtc_vblank_get(crtc);
-		adp->event = crtc->state->event;
+		struct drm_pending_vblank_event *event = crtc->state->event;
+
+		crtc->state->event = NULL;
+		spin_lock_irqsave(&crtc->dev->event_lock, flags);
+
+		if (drm_crtc_vblank_get(crtc) != 0)
+			drm_crtc_send_vblank_event(crtc, event);
+		else
+			adp->event = event;
+
+		spin_unlock_irqrestore(&crtc->dev->event_lock, flags);
 	}
-	crtc->state->event = NULL;
-	spin_unlock_irqrestore(&crtc->dev->event_lock, flags);
 }
 
 static const struct drm_crtc_funcs adp_crtc_funcs = {

-- 
2.49.0

