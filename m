From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Mon, 04 Nov 2024 14:43:39 +0800
Subject: [PATCH v7 09/10] drm/bridge: it6505: fix HDCP CTS KSV list wait
 timer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241104-v7-upstream-v7-9-8b71fd0f1d2d@ite.com.tw>
References: <20241104-v7-upstream-v7-0-8b71fd0f1d2d@ite.com.tw>
In-Reply-To: <20241104-v7-upstream-v7-0-8b71fd0f1d2d@ite.com.tw>
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Hermes Wu <hermes.wu@ite.com.tw>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Pin-yen Lin <treapking@chromium.org>, 
 Kenneth Hung <Kenneth.Hung@ite.com.tw>, Pet Weng <Pet.Weng@ite.com.tw>, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730702658; l=1723;
 i=Hermes.wu@ite.com.tw; s=20241101; h=from:subject:message-id;
 bh=QISr17OTE/349oMqfbcRg7gIss3cy8H02akOrW/SuWA=;
 b=5wclQJlV2oEcIDMwHjjZwt9btEgTeYh3Wif+2xLf+6CvQ7lDDmauVYlsnjLgZZYm0BKKS2TCE
 Ihk/KJGMEB3DSfV5wXpAHcvnaPrhxIUgyONBl/+GJs0b07iKDglElcm
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=FOYYbsP2Nlw6mjB3rLFYSLmAiENzj4AWQly5XTcDuMM=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241101 with auth_id=268
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

HDCP must disabled encryption and restart authentication after
waiting KSV for 5s.
The original method uses a counter in a waitting loop that may
wait much longer than it is supposed to.
Use time_after() for KSV wait timeout.

Signed-off-by: Hermes Wu <hermes.wu@ite.com.tw>
---
 drivers/gpu/drm/bridge/ite-it6505.c | 20 ++++++++++----------
 1 file changed, 10 insertions(+), 10 deletions(-)

diff --git a/drivers/gpu/drm/bridge/ite-it6505.c b/drivers/gpu/drm/bridge/ite-it6505.c
index 2b8f208d1e17eebe3287ab0aa71180176dd0574e..83e2df618c97f8fe3e59789ffb810ce8639f96bb 100644
--- a/drivers/gpu/drm/bridge/ite-it6505.c
+++ b/drivers/gpu/drm/bridge/ite-it6505.c
@@ -2096,12 +2096,13 @@ static void it6505_hdcp_wait_ksv_list(struct work_struct *work)
 	struct it6505 *it6505 = container_of(work, struct it6505,
 					     hdcp_wait_ksv_list);
 	struct device *dev = it6505->dev;
-	unsigned int timeout = 5000;
-	u8 bstatus = 0;
+	u8 bstatus;
 	bool ksv_list_check;
+	/* 1B-04 wait ksv list for 5s */
+	unsigned long timeout = jiffies +
+				msecs_to_jiffies(5000) + 1;
 
-	timeout /= 20;
-	while (timeout > 0) {
+	for (;;) {
 		if (!it6505_get_sink_hpd_status(it6505))
 			return;
 
@@ -2110,13 +2111,12 @@ static void it6505_hdcp_wait_ksv_list(struct work_struct *work)
 		if (bstatus & DP_BSTATUS_READY)
 			break;
 
-		msleep(20);
-		timeout--;
-	}
+		if (time_after(jiffies, timeout)) {
+			DRM_DEV_DEBUG_DRIVER(dev, "KSV list wait timeout");
+			goto timeout;
+		}
 
-	if (timeout == 0) {
-		DRM_DEV_DEBUG_DRIVER(dev, "timeout and ksv list wait failed");
-		goto timeout;
+		msleep(20);
 	}
 
 	ksv_list_check = it6505_hdcp_part2_ksvlist_check(it6505);

-- 
2.34.1

