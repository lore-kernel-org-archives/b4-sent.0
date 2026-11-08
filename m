From: DelaySystem <DelaySystem@tubot.lat>
Date: Sat, 07 Nov 2026 21:21:47 -0800
Subject: [PATCH RFC 2/2] staging: media: tegra-video: uninterruptible
 syncpt wait for tegra20
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-batch1-b1-host1x-wait-v1-2-8c8198adf600@tubot.lat>
References: <20261107-batch1-b1-host1x-wait-v1-0-8c8198adf600@tubot.lat>
In-Reply-To: <20261107-batch1-b1-host1x-wait-v1-0-8c8198adf600@tubot.lat>
To: mperttunen@nvidia.com, thierry.reding@kernel.org
Cc: DelaySystem <DelaySystem@tubot.lat>, dri-devel@lists.freedesktop.org, 
 luca.ceresoli@bootlin.com, gregkh@linuxfoundation.org, mchehab@kernel.org, 
 linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 clamor95@gmail.com, jonathanh@nvidia.com, linux-tegra@vger.kernel.org, 
 skomatineni@nvidia.com, linux-media@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3090; i=DelaySystem@tubot.lat;
 h=from:subject:message-id; bh=7uslf2XS4oy14/GfacExPmou0Ikg+kCKP6aBJT8Gwy0=;
 b=owGbwMvMwCH2SNl4+SzWXm/G02pJDFkf2F5ZZzAysWlkRNotNl89g+nGy8TPGo7er+YqdjzIv
 +Oh+VCoo5SFQYyDQVZMkUVMhud9/X2dOGurOSdg5rAygQxh4OIUgIm0XGb4X/4spIKP18/ewqGm
 3nj26Vd2WyQ+d7CuiAg46yLsGbbCl+F/pXpCn+AUJ89QoWsRWSrfDBzd10m9j3WaZuyYVPFogxw
 3AA==
X-Developer-Key: i=DelaySystem@tubot.lat; a=openpgp;
 fpr=161C0CEF7FDF2C5E3B3A9CC8E22333A79A058D4B
X-Endpoint-Received: by B4 Relay for DelaySystem@tubot.lat/default with auth_id=1447
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Tegra20 capture path runs in a kernel thread and retries
host1x_syncpt_wait() in a do/while loop to survive the -ERESTARTSYS
its unconditionally interruptible wait returns spuriously at high
resolutions and framerates.

Now that host1x provides host1x_syncpt_wait_uninterruptible(), use it
for both the frame-start and MW-ACK waits and drop the retry loops,
fulfilling the TODO above the frame-start wait.  Timeouts still fail
the capture as before; only the spurious signal failures go away.

Signed-off-by: DelaySystem <DelaySystem@tubot.lat>
---
 drivers/staging/media/tegra-video/tegra20.c | 37 ++++++++---------------------
 1 file changed, 10 insertions(+), 27 deletions(-)

diff --git a/drivers/staging/media/tegra-video/tegra20.c b/drivers/staging/media/tegra-video/tegra20.c
index cdadff98eae7..e618d1722841 100644
--- a/drivers/staging/media/tegra-video/tegra20.c
+++ b/drivers/staging/media/tegra-video/tegra20.c
@@ -589,28 +589,14 @@ static int tegra20_channel_capture_frame(struct tegra_vi_channel *chan,
 				  CSI_PP_START_MARKER_FRAME_MAX(0xf) |
 				  CSI_PP_SINGLE_SHOT | CSI_PP_ENABLE);
 
-		/*
-		 * ERESTARTSYS workaround for syncpoints is used because host1x_syncpt_wait
-		 * is unconditionally interruptible. This is not an issue with single shots
-		 * or low resolution capture, but -ERESTARTSYS occurs quite often with high
-		 * resolution or high framerate captures and if not addressed here will
-		 * cause capture to fail entirely.
-		 *
-		 * TODO: once uninterruptible version of host1x_syncpt_wait is available,
-		 * host1x_syncpt_wait should be swapped and ERESTARTSYS workaround can be
-		 * removed.
-		 */
-
 		val = host1x_syncpt_read(chan->frame_start_sp[0]);
-		do {
-			err = host1x_syncpt_wait(chan->frame_start_sp[0],
-						 val + 1, TEGRA_VI_SYNCPT_WAIT_TIMEOUT, NULL);
-		} while (err == -ERESTARTSYS);
-
+		err = host1x_syncpt_wait_uninterruptible(chan->frame_start_sp[0],
+							 val + 1,
+							 TEGRA_VI_SYNCPT_WAIT_TIMEOUT,
+							 NULL);
 		if (err) {
-			if (err != -ERESTARTSYS)
-				dev_err_ratelimited(&chan->video.dev,
-						    "frame start syncpt timeout: %d\n", err);
+			dev_err_ratelimited(&chan->video.dev,
+					    "frame start syncpt timeout: %d\n", err);
 
 			tegra20_csi_write(csi_chan, TEGRA_CSI_PIXEL_STREAM_PP_COMMAND(port),
 					  CSI_PP_START_MARKER_FRAME_MAX(0xf) | CSI_PP_RESET);
@@ -625,14 +611,11 @@ static int tegra20_channel_capture_frame(struct tegra_vi_channel *chan,
 	}
 
 	val = host1x_syncpt_read(chan->mw_ack_sp[0]);
-	do {
-		err = host1x_syncpt_wait(chan->mw_ack_sp[0], val + 1,
-					 TEGRA_VI_SYNCPT_WAIT_TIMEOUT, NULL);
-	} while (err == -ERESTARTSYS);
-
+	err = host1x_syncpt_wait_uninterruptible(chan->mw_ack_sp[0], val + 1,
+						 TEGRA_VI_SYNCPT_WAIT_TIMEOUT,
+						 NULL);
 	if (err) {
-		if (err != -ERESTARTSYS)
-			dev_err_ratelimited(&chan->video.dev, "mw ack syncpt timeout: %d\n", err);
+		dev_err_ratelimited(&chan->video.dev, "mw ack syncpt timeout: %d\n", err);
 		goto exit;
 	}
 

-- 
2.34.1

