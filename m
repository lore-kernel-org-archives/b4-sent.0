From: Sven Peter <sven@svenpeter.dev>
Date: Sat, 22 Feb 2025 16:56:48 +0000
Subject: [PATCH 3/4] soc: apple: rtkit: Use high prio work queue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250222-apple-soc-misc-v1-3-1a3af494a48a@svenpeter.dev>
References: <20250222-apple-soc-misc-v1-0-1a3af494a48a@svenpeter.dev>
In-Reply-To: <20250222-apple-soc-misc-v1-0-1a3af494a48a@svenpeter.dev>
To: Alyssa Rosenzweig <alyssa@rosenzweig.io>, Janne Grunau <j@jannau.net>, 
 Sven Peter <sven@svenpeter.dev>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1148; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=OWy6VUyG9jq3qBr8MjUz+I6ziXX4V7f2D7Wm55EGjV0=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ/ouxs93H4hIZT5ne2ZQsWnBzGt3WbYyLkm8nxZQvHJJi
 4DX/Au3O0pZGMQ4GGTFFFm277c3ffLwjeDSTZfew8xhZQIZwsDFKQAT4U1k+O/RLcbryXjg/Orw
 veyqdwO/i2vNv+2wa53plXtfVQ0ObVdg+J+Zu85u58aTu2T9ZL9N+uusLjtTvX2O1EY591X+ItO
 5W1gA
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
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/soc/apple/rtkit.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/soc/apple/rtkit.c b/drivers/soc/apple/rtkit.c
index 35734ae8c9ce..b7f4654c3341 100644
--- a/drivers/soc/apple/rtkit.c
+++ b/drivers/soc/apple/rtkit.c
@@ -695,7 +695,7 @@ struct apple_rtkit *apple_rtkit_init(struct device *dev, void *cookie,
 	rtk->mbox->rx = apple_rtkit_rx;
 	rtk->mbox->cookie = rtk;
 
-	rtk->wq = alloc_ordered_workqueue("rtkit-%s", WQ_MEM_RECLAIM,
+	rtk->wq = alloc_ordered_workqueue("rtkit-%s", WQ_HIGHPRI | WQ_MEM_RECLAIM,
 					  dev_name(rtk->dev));
 	if (!rtk->wq) {
 		ret = -ENOMEM;

-- 
2.34.1

