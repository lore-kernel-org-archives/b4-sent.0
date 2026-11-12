From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:10:39 +0000
Subject: [PATCH v2] drm/panthor: Suspend devfreq until the GPU is first
 resumed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-panthor-suspend-clk-v2-1-62e1b168052d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32OS47CMBBErxJ5jUfdSZyMWXGPEQu70yYeyAfbi
 QYh7o5D9rN86qp6/RSRg+cojsVTBF599NOYoTwUgnozXlj6LrMooWwQEeRsxtRPQcYlzjx2km5
 XidipBmrHyrLIzTmw83+f1Z/zznGxv0xpm9oSvY9pCo+PdsUt979hRYlSVbVqQQEr5NNlMP72R
 dMgzq9dEfi+5P/T7hXWRJb5Pvh0LMiCaSoHpBv+ZrIaUGtmqzVRaVpHzrRQdXUee70BaxZKHhQ
 BAAA=
X-Change-ID: 20261110-panthor-suspend-clk-11d5604fe5be
To: Boris Brezillon <boris.brezillon@collabora.com>, 
 Steven Price <steven.price@arm.com>, Liviu Dudau <liviu.dudau@arm.com>, 
 Akash Goel <akash.goel@arm.com>, Karunika Choo <karunika.choo@arm.com>, 
 Lukas Zapolskas <lukas.zapolskas@arm.com>, 
 Chris Diamand <chris.diamand@arm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Heiko Stuebner <heiko@sntech.de>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Jonas Karlman <jonas@kwiboo.se>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794471038; l=6121;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=uiwyQooI2QqdHVVbIj2tbEKcTWRM+G3FzfbhcKof+kg=;
 b=wivOOwJ/7GTvbZBbl834segCag1oFnqKSy2+v8GXNHok6K8gnpd49EQDjqRZ2Ifr4AEJT7Xg3
 pSZ8BrJXh9wBSgatVc/kYmttND3QH/F7PLPS1qxGYtybmlz9/HqCGC5
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panthor_devfreq_init() adds the devfreq device while the GPU is still
suspended, and the first panthor_device_resume() then calls
devfreq_resume_device() without a matching devfreq_suspend_device(). The
devfreq suspend count stays off by one for the lifetime of the device:
-1 while the GPU is active, 0 while it is runtime suspended.

devfreq_suspend() and devfreq_resume() around a system suspend therefore
treat a runtime suspended GPU as an active one: devfreq_suspend()
applies the suspend OPP, if there is one, and devfreq_resume() restarts
the polling of the simple_ondemand governor, which then sets GPU rates
while the GPU is still runtime suspended, until its next runtime resume
and suspend. With the devfreq core keeping a suspended device's
frequency alone ("PM / devfreq: Do not change the frequency of a
suspended device"), the unbalanced devfreq_resume() also marks the
device resumed while the GPU is powered down.

Suspend devfreq right after adding it, as msm_devfreq_init() does, so
that the devfreq suspend and resume calls pair up.

Fixes: fac9b22df4b1 ("drm/panthor: Add the devfreq logical block")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
v1 kept devfreq from changing the GPU clock rate while the GPU is
suspended by filtering the calls in panthor_devfreq_target(). As Boris
pointed out, that cannot be done race-free in the driver, so v2 moves it
to the devfreq core: "PM / devfreq: Do not change the frequency of a
suspended device" (linux-pm [1]) keeps devfreq from calling
->target() between devfreq_suspend_device() and devfreq_resume_device()
and applies the requests made in between on resume. The SError fix
needs that patch. What is left for panthor is this patch, which makes
panthor's devfreq suspend and resume calls pair up; it does not depend
on the devfreq patch to build or to be correct.

Tested on an Orange Pi 5 (RK3588S) running a v7.3-based kernel with
this patch and the devfreq patch, with the GPU core clock on the
firmware-managed SCMI_CLK_GPU and a 200 MHz opp-suspend (the
configuration of Jonas Karlman's RFC, not in mainline): min_freq,
max_freq, the userspace governor's set_freq and the devfreq cooling
state written while the GPU was runtime suspended, also right after a
suspend-to-idle cycle, no longer end in an SError and take effect on
the next GPU job; 200 runtime suspend/resume cycles with max_freq
toggling every ~35 ms and a 3 minute sustained load ran without an
SError, WARN or panthor fault.

This patch was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit message, and I reviewed it and tested
it as described above.

[1] https://lore.kernel.org/r/20261112-devfreq-suspend-sync-v1-1-af64603ef43e@gmail.com
---
Changes in v2:
- Dropped the check in panthor_devfreq_target() (Boris): neither
  pm.state nor devfreq::suspend_count can be read there without racing
  with devfreq_suspend_device() and devfreq_resume_device(), which only
  take devfreq->lock around the suspend and resume frequency changes.
  The devfreq core now tracks the suspended state under devfreq->lock
  and does not call ->target() while it is set, as Boris suggested.
- New patch: start with devfreq suspended. The first runtime resume
  called devfreq_resume_device() without a matching suspend, so the
  suspend count was -1 while the GPU was active and 0 while it was
  suspended (the reason v1 did not use it). Without this, the devfreq
  core change would not hold across a system suspend taken while the
  GPU is runtime suspended.
- Liviu, on returning 0 instead of -EINVAL: returning 0 was wrong, devfreq
  then records a rate the GPU does not run at (Boris). An error is
  better than 0, but -EINVAL reports a valid request as invalid (-EBUSY
  fits better), and either way nothing retries the request on resume:
  the userspace and performance governors never re-evaluate, and
  simple_ondemand only at its next poll. With the core change panthor
  never gets these calls, so there is nothing left to reject.
- Liviu, on disabling the clock when the power domain goes down: the
  clocks are already disabled in panthor_device_suspend() before the
  domain goes down, and the SError happens in that state. On RK3588 a
  rate change on the disabled SCMI clock still goes to TF-A, which
  programs the PVTPLL through the GPU GRF in the powered-down domain.
  So the rate change itself has to be held back while suspended.
- Liviu, on the comment length: the remaining comment is two lines.
- Sashiko's findings on v1 (a rate requested while suspended was lost
  without a suspend OPP or with a non-polling governor; the lockless
  state check could race with the clocks going off; Fixes: tag) are
  covered by the devfreq core change, which applies deferred requests on
  resume and keeps the state under devfreq->lock. Thanks to Sashiko for
  them. The new patch has Fixes: fac9b22df4b1, the commit Sashiko named:
  the unbalanced count is a mainline bug, independent of the SCMI clock.
- Link to v1: https://patch.msgid.link/20261110-panthor-suspend-clk-v1-1-53457050e51e@gmail.com
---
 drivers/gpu/drm/panthor/panthor_devfreq.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/gpu/drm/panthor/panthor_devfreq.c b/drivers/gpu/drm/panthor/panthor_devfreq.c
index 2249b41ca4af..45ae42dacdcb 100644
--- a/drivers/gpu/drm/panthor/panthor_devfreq.c
+++ b/drivers/gpu/drm/panthor/panthor_devfreq.c
@@ -256,6 +256,12 @@ int panthor_devfreq_init(struct panthor_device *ptdev)
 		return ret;
 	}
 
+	/*
+	 * The GPU stays suspended until the first panthor_device_resume(),
+	 * which resumes devfreq. Suspend devfreq to match.
+	 */
+	panthor_devfreq_suspend(ptdev);
+
 	cooling = devfreq_cooling_em_register(pdevfreq->devfreq, NULL);
 	if (IS_ERR(cooling))
 		DRM_DEV_INFO(dev, "Failed to register cooling device\n");

---
base-commit: cb0a63f0c96e8ecb90199eeb99cc2a7fcfa703d4
change-id: 20261110-panthor-suspend-clk-11d5604fe5be

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

