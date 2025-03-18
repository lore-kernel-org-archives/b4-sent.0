From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Tue, 18 Mar 2025 16:32:10 +0800
Subject: [PATCH RESEND 2/3] drm/bridge: it6505: modify DP link training
 work
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250318-fix-link-training-v1-2-19266711142c@ite.com.tw>
References: <20250318-fix-link-training-v1-0-19266711142c@ite.com.tw>
In-Reply-To: <20250318-fix-link-training-v1-0-19266711142c@ite.com.tw>
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: Pet.Weng@ite.com.tw, Kenneth.Hung@ite.com.tw, treapking@chromium.org, 
 dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742286741; l=2681;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=llpaVHPsyMc2Qs3dtoETLe0MUHFLEKcOWtYQxLf0olo=;
 b=Nq9Cu/zN2QqLOmjzI7sVdCwUS49UGwJKAWpdxDlY+uVif3xPoNkBVNChSIDqb2xD/kYJQDNDu
 FP35pkdzHNfBEfx0TjlOAcbe7f5vyKx8dUi9/11VMsCuWWBMEcCt3Az
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DP link training work include auto training and after
auto training failed "auto_train_retry" times, it switch to
step training mode.

It will more efficiency that finish link auto training,
include retry, and step training in a work, rather than
re-schedule train work when each training fail.

it6505_dump() is remove from link trainig work, it takes too much
time to read all register area, and is not necessary.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/gpu/drm/bridge/ite-it6505.c | 35 ++++++++++++++++-------------------
 1 file changed, 16 insertions(+), 19 deletions(-)

diff --git a/drivers/gpu/drm/bridge/ite-it6505.c b/drivers/gpu/drm/bridge/ite-it6505.c
index dc1179c8338e27866f6adda4ef8fb2950336221b..11231a642bbe185c4f36bf5f2a0b115fa056213b 100644
--- a/drivers/gpu/drm/bridge/ite-it6505.c
+++ b/drivers/gpu/drm/bridge/ite-it6505.c
@@ -666,7 +666,7 @@ static int it6505_get_dpcd(struct it6505 *it6505, int offset, u8 *dpcd, int num)
 	return 0;
 }
 
-static void it6505_dump(struct it6505 *it6505)
+static void __maybe_unused it6505_dump(struct it6505 *it6505)
 {
 	unsigned int i, j;
 	u8 regs[16];
@@ -2472,7 +2472,7 @@ static void it6505_link_training_work(struct work_struct *work)
 {
 	struct it6505 *it6505 = container_of(work, struct it6505, link_works);
 	struct device *dev = it6505->dev;
-	int ret;
+	int ret, retry;
 
 	DRM_DEV_DEBUG_DRIVER(dev, "it6505->sink_count: %d",
 			     it6505->sink_count);
@@ -2480,26 +2480,23 @@ static void it6505_link_training_work(struct work_struct *work)
 	if (!it6505_get_sink_hpd_status(it6505))
 		return;
 
-	it6505_link_training_setup(it6505);
-	it6505_reset_hdcp(it6505);
-	it6505_aux_reset(it6505);
-
-	if (it6505->auto_train_retry < 1) {
-		it6505_link_step_train_process(it6505);
-		return;
-	}
+	retry = it6505->auto_train_retry;
+	do {
+		it6505_link_training_setup(it6505);
+		it6505_reset_hdcp(it6505);
+		it6505_aux_reset(it6505);
 
-	ret = it6505_link_start_auto_train(it6505);
-	DRM_DEV_DEBUG_DRIVER(dev, "auto train %s, auto_train_retry: %d",
+		ret = it6505_link_start_auto_train(it6505);
+		DRM_DEV_DEBUG_DRIVER(dev, "auto train %s, auto_train_retry: %d",
 			     ret ? "pass" : "failed", it6505->auto_train_retry);
+		if (ret) {
+			it6505_link_train_ok(it6505);
+			return;
+		}
+	} while (retry--);
 
-	if (ret) {
-		it6505->auto_train_retry = AUTO_TRAIN_RETRY;
-		it6505_link_train_ok(it6505);
-	} else {
-		it6505->auto_train_retry--;
-		it6505_dump(it6505);
-	}
+	/*After HW auto training fail, try link training step by step*/
+	it6505_link_step_train_process(it6505);
 
 }
 

-- 
2.34.1

