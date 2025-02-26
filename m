From: Sven Peter <sven@svenpeter.dev>
Date: Wed, 26 Feb 2025 19:00:05 +0000
Subject: [PATCH v2 3/4] soc: apple: rtkit: Use high prio work queue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250226-apple-soc-misc-v2-3-c3ec37f9021b@svenpeter.dev>
References: <20250226-apple-soc-misc-v2-0-c3ec37f9021b@svenpeter.dev>
In-Reply-To: <20250226-apple-soc-misc-v2-0-c3ec37f9021b@svenpeter.dev>
To: Alyssa Rosenzweig <alyssa@rosenzweig.io>, Janne Grunau <j@jannau.net>, 
 Sven Peter <sven@svenpeter.dev>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1203; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=iv/ffBDDwqiEAfuhFDw9qjf225eWoJ8zsBxA5fDCkeQ=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ/r+lL3ym1uNXD12Pz7lKsp732r7wsbyZdIKzy6Lftwfw
 eaf9uddRykLgxgHg6yYIsv2/famTx6+EVy66dJ7mDmsTCBDGLg4BWAiC7sY/vD822NWt4O9RlY2
 wcvXTDr+S7PNTd2k+712/2q0l3nUpjD8FT3rNT9ZiCOGR6NbYEdr/lO/0+uE3L93uGoteFP0XU2
 VEwA=
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Janne Grunau <j@jannau.net>

rtkit messages as communication with the DCP firmware for framebuffer
swaps or input events are time critical so use WQ_HIGHPRI to prevent
user space CPU load to increase latency.
With kwin_wayland 6's explicit sync mode user space load was able to
delay the IOMFB rtkit communication enough to miss vsync for surface
swaps. Minimal test scenario is constantly resizing a glxgears
Xwayland window.

Signed-off-by: Janne Grunau <j@jannau.net>
Reviewed-by: Alyssa Rosenzweig <alyssa@rosenzweig.io>
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/soc/apple/rtkit.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/soc/apple/rtkit.c b/drivers/soc/apple/rtkit.c
index 7e7b4f64ab17..4b78463dd5a1 100644
--- a/drivers/soc/apple/rtkit.c
+++ b/drivers/soc/apple/rtkit.c
@@ -696,7 +696,7 @@ struct apple_rtkit *apple_rtkit_init(struct device *dev, void *cookie,
 	rtk->mbox->rx = apple_rtkit_rx;
 	rtk->mbox->cookie = rtk;
 
-	rtk->wq = alloc_ordered_workqueue("rtkit-%s", WQ_MEM_RECLAIM,
+	rtk->wq = alloc_ordered_workqueue("rtkit-%s", WQ_HIGHPRI | WQ_MEM_RECLAIM,
 					  dev_name(rtk->dev));
 	if (!rtk->wq) {
 		ret = -ENOMEM;

-- 
2.34.1

