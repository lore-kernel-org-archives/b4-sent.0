From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Mon, 09 Mar 2026 17:47:39 +0800
Subject: [PATCH RESEND] drm/bridge: it6505: disable HDCP retry when KSV
 list timeout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260309-disable-hdcp-auto-retry-v1-1-591a1d75a3a6@ite.com.tw>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773049659; l=1553;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=rCW3jddM8TQgyxZZEpHfDk8/Yn8r6UZLGkwB+J85M8A=;
 b=hTiNcbyw5vGsK42HIOpO38f6dTT8V3VldbcsXm+A0NycewASP4KkonH6md1vRsVg0EaOga/3Q
 pu5bVBYQ1WUCLkpwY1YsonU7Jl3/m8F2iNVAfDpbYP8MX+tIcwZhpE+
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some DP to HDMI converters fail to report KSV list within the 6-second
HDCP window, causing the IT6505 to repeatedly restart authentication.
This results in continuous flickering on the connected HDMI monitor.

Disable automatic HDCP retry when KSV list timeout. This breaks the
re-auth loop and significantly improves stability/user experience with
problematic converters.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/gpu/drm/bridge/ite-it6505.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/bridge/ite-it6505.c b/drivers/gpu/drm/bridge/ite-it6505.c
index a094803ba7aa4e12165fcde432d4e6417fbf3676..1c1e6b78fadbf29da00a68e26671ce5b54ee1557 100644
--- a/drivers/gpu/drm/bridge/ite-it6505.c
+++ b/drivers/gpu/drm/bridge/ite-it6505.c
@@ -2238,7 +2238,7 @@ static void it6505_hdcp_wait_ksv_list(struct work_struct *work)
 		return;
 
 timeout:
-	it6505_start_hdcp(it6505);
+	it6505_stop_hdcp(it6505);
 }
 
 static void it6505_hdcp_work(struct work_struct *work)
@@ -2596,7 +2596,7 @@ static void it6505_irq_hdcp_fail(struct it6505 *it6505)
 	DRM_DEV_DEBUG_DRIVER(dev, "hdcp fail interrupt");
 	it6505->hdcp_status = HDCP_AUTH_IDLE;
 	it6505_show_hdcp_info(it6505);
-	it6505_start_hdcp(it6505);
+	it6505_stop_hdcp(it6505);
 }
 
 static void it6505_irq_aux_cmd_fail(struct it6505 *it6505)

---
base-commit: 38feb171b3f92d77e8061fafb5ddfffc2c13b672
change-id: 20260112-disable-hdcp-auto-retry-6a8d00f6ba29

Best regards,
-- 
Hermes Wu <Hermes.wu@ite.com.tw>

