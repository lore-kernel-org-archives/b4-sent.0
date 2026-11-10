From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:15:00 +0000
Subject: [PATCH] drm/panthor: Do not change the GPU clock rate while
 suspended
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-panthor-suspend-clk-v1-1-53457050e51e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBG4auQWTtJhwgLr2JcQPsjo6Y0HSAmh
 LtTdPkt3tvIkBVGt2qjjFVNp1ggl4r82MUnWEMx1a5uRcRx6uI8TpltsYQY2H/eLBKa1l0HND2
 olClj0O/ven/8bUv/gp/PFe37AdSOyWx3AAAA
X-Change-ID: 20261110-panthor-suspend-clk-11d5604fe5be
To: Boris Brezillon <boris.brezillon@collabora.com>, 
 Steven Price <steven.price@arm.com>, Liviu Dudau <liviu.dudau@arm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Heiko Stuebner <heiko@sntech.de>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Jonas Karlman <jonas@kwiboo.se>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294899; l=5357;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=5go781LIcqxZXcS2fgUKEcRmZbGKWGhE55YnHaY3k5E=;
 b=sWRK/xNMMI8xbnZDMbozJG0VgEE8K+dtXH8cCcg14tTn5zwqv8mxRZjPzpKtbbHeqenDlJfM8
 gr0hTA/AC6NBSGHJyQncQxQBZNCzvdDvdueMUOmBbsYasltnVlaC1mH
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From the start of panthor_device_suspend() until panthor_device_resume()
has enabled the clocks again, the GPU clocks are off or about to be, and
the GPU power domain may be down. devfreq can still call ->target() in
that window: a write to min_freq or max_freq in sysfs, a thermal cooling
state change or a PM QoS request all end up in update_devfreq() whatever
the device state.

With the RK3588 GPU core clock switched to the firmware-managed
SCMI_CLK_GPU (needed to reach the PVTPLL rates of the upper OPPs), such
a call is fatal. To set a PVTPLL rate TF-A programs registers in the GPU
GRF, which sit in the GPU power domain, and with the domain off that
access ends in an asynchronous SError and a kernel panic, for example
after

  echo 1000000000 > /sys/class/devfreq/fb000000.gpu/min_freq

while the GPU is runtime suspended.

Only apply a rate to the hardware while the device is resuming or
active, plus the suspend frequency that devfreq_suspend_device() applies
from the suspend path while the GPU is still powered. Other requests are
still accepted and recorded by devfreq, which applies them on resume or
at the next governor update.

The RFC this is based on (Jonas Karlman's panthor SCMI clock change,
carried in Armbian's linux-rockchip pull request 380) checked the
runtime PM status instead. That
status is still RPM_SUSPENDING after panthor_devfreq_suspend() has run,
which leaves a window where the rate can be raised again right before
the power domain goes down. The devfreq suspend count cannot be used
either: panthor's first runtime resume calls devfreq_resume_device()
without a matching suspend, so the count is -1 while the GPU is active
and 0 while it is suspended.

Suggested-by: Jonas Karlman <jonas@kwiboo.se>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested on an Orange Pi 5 (RK3588S) with the GPU core clock switched to
SCMI_CLK_GPU and a 200 MHz opp-suspend (the configuration from the RFC,
not yet in mainline): writing min_freq while the GPU was runtime
suspended no longer ends in an SError, the request takes effect at the
next job (1 GHz measured), max_freq likewise; 200 suspend/resume cycles
with short GPU jobs and a 3 minute sustained load ran without faults.
With the mainline device tree (CRU clock, no suspend OPP) the SError is
not reachable and the guard only skips rate changes while the GPU is
powered down.

This patch was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit message, and I reviewed and tested it
as described above.
---
 drivers/gpu/drm/panthor/panthor_devfreq.c | 42 ++++++++++++++++++++++++++++---
 1 file changed, 39 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/panthor/panthor_devfreq.c b/drivers/gpu/drm/panthor/panthor_devfreq.c
index 2249b41ca4af..cab86e9c9d46 100644
--- a/drivers/gpu/drm/panthor/panthor_devfreq.c
+++ b/drivers/gpu/drm/panthor/panthor_devfreq.c
@@ -60,20 +60,56 @@ static void panthor_devfreq_update_utilization(struct panthor_devfreq *pdevfreq)
 	pdevfreq->time_last_update = now;
 }
 
+/*
+ * Whether a new rate can be applied to the hardware now.
+ *
+ * From the start of panthor_device_suspend() until panthor_device_resume()
+ * has enabled the clocks again, the GPU clocks are about to be disabled
+ * or are off, and the GPU power domain may be down. devfreq can still
+ * call ->target() in that window: sysfs
+ * min_freq/max_freq writes, thermal cooling and PM QoS requests all end
+ * up in update_devfreq() whatever the device state.
+ *
+ * Changing the rate then is pointless, and harmful where the core clock
+ * is managed by firmware: on RK3588, setting SCMI_CLK_GPU to a PVTPLL
+ * rate with the GPU power domain off makes TF-A access the powered-down
+ * GPU GRF, which ends in an asynchronous SError. So while the device is
+ * suspending only the suspend frequency, applied by
+ * devfreq_suspend_device(), reaches the hardware, and nothing does
+ * while it is suspended. devfreq records the other requests: they are
+ * applied on resume or at the next governor update.
+ */
+static bool panthor_devfreq_can_set_rate(struct panthor_device *ptdev,
+					 unsigned long freq)
+{
+	struct devfreq *devfreq = ptdev->devfreq ? ptdev->devfreq->devfreq : NULL;
+
+	switch (atomic_read(&ptdev->pm.state)) {
+	case PANTHOR_DEVICE_PM_STATE_SUSPENDED:
+		return false;
+	case PANTHOR_DEVICE_PM_STATE_SUSPENDING:
+		return devfreq && devfreq->suspend_freq &&
+		       freq == devfreq->suspend_freq;
+	default:
+		return true;
+	}
+}
+
 static int panthor_devfreq_target(struct device *dev, unsigned long *freq,
 				  u32 flags)
 {
+	struct panthor_device *ptdev = dev_get_drvdata(dev);
 	struct dev_pm_opp *opp;
-	int err;
 
 	opp = devfreq_recommended_opp(dev, freq, flags);
 	if (IS_ERR(opp))
 		return PTR_ERR(opp);
 	dev_pm_opp_put(opp);
 
-	err = dev_pm_opp_set_rate(dev, *freq);
+	if (!panthor_devfreq_can_set_rate(ptdev, *freq))
+		return 0;
 
-	return err;
+	return dev_pm_opp_set_rate(dev, *freq);
 }
 
 static void panthor_devfreq_reset(struct panthor_devfreq *pdevfreq)

---
base-commit: 8deaade4a5a4ff635df91e246e42139ab2b33f6d
change-id: 20261110-panthor-suspend-clk-11d5604fe5be

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

