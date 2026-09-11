From: =?utf-8?q?Y=C4=B0=C4=9E=C4=B0TCAN_KAVAKLI?= <kavakliyigitcan@gmail.com>
Date: Fri, 11 Sep 2026 11:51:05 +0300
Subject: [PATCH RFC 08/10] drm/msm/dsi: make command and video mode
 configuration mutually exclusive
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260911-ginkgo-submission-final-v1-8-0e68e63a18d4@gmail.com>
References: <20260911-ginkgo-submission-final-v1-0-0e68e63a18d4@gmail.com>
In-Reply-To: <20260911-ginkgo-submission-final-v1-0-0e68e63a18d4@gmail.com>
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Helge Deller <deller@gmx.de>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Sumit Semwal <sumit.semwal@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fbdev@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, freedreno@lists.freedesktop.org, 
 =?utf-8?q?Y=C4=B0=C4=9E=C4=B0TCAN_KAVAKLI?= <kavakliyigitcan@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789116671; l=1765;
 i=kavakliyigitcan@gmail.com; s=20260911; h=from:subject:message-id;
 bh=Us+uRTzRjQ6VYzVCqSZeacYfhPldhSoALLrWybl6TfU=;
 b=PJ3ocNCyABkNjnqrQLKKE8IN0UZxDZIuONeU9q+5JR84OpiNeg9UQcKEQhp7AhlsGlsLCFhGj
 M9VD6VXm4RMCG/mkfHl+ViesebYjNHZ+5t10GnPFPnMJ7wxPj4YC+yf
X-Developer-Key: i=kavakliyigitcan@gmail.com; a=ed25519;
 pk=W2GaxVotULs2vAjRMMLheaDtMMYs4037zO1LVVfFtPI=
X-Endpoint-Received: by B4 Relay for kavakliyigitcan@gmail.com/20260911 with auth_id=1024
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In dsi_op_mode_config(), entering video mode sets DSI_CTRL_VID_MODE_EN
without clearing DSI_CTRL_CMD_MODE_EN, and entering command mode sets
DSI_CTRL_CMD_MODE_EN without clearing DSI_CTRL_VID_MODE_EN.

Ensure explicit mutual exclusion by clearing the opposing enable bit
when switching operational modes to prevent hardware bus collisions.

Signed-off-by: YİĞİTCAN KAVAKLI <kavakliyigitcan@gmail.com>
---
 drivers/gpu/drm/msm/dsi/dsi_host.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/msm/dsi/dsi_host.c b/drivers/gpu/drm/msm/dsi/dsi_host.c
index 7e4e3718b536c92dc555de213042857379499447..b9e2867d435a3ad8b6db6b57c440bbd827180b6e 100644
--- a/drivers/gpu/drm/msm/dsi/dsi_host.c
+++ b/drivers/gpu/drm/msm/dsi/dsi_host.c
@@ -1094,7 +1094,9 @@ static void dsi_timing_setup(struct msm_dsi_host *msm_host, bool is_bonded_dsi)
 		dsi_write(msm_host, REG_DSI_ACTIVE_HSYNC,
 			DSI_ACTIVE_HSYNC_START(hs_start) |
 			DSI_ACTIVE_HSYNC_END(hs_end));
-		dsi_write(msm_host, REG_DSI_ACTIVE_VSYNC_HPOS, 0);
+		dsi_write(msm_host, REG_DSI_ACTIVE_VSYNC_HPOS,
+			DSI_ACTIVE_VSYNC_HPOS_START(hs_start) |
+			DSI_ACTIVE_VSYNC_HPOS_END(vs_end));
 		dsi_write(msm_host, REG_DSI_ACTIVE_VSYNC_VPOS,
 			DSI_ACTIVE_VSYNC_VPOS_START(vs_start) |
 			DSI_ACTIVE_VSYNC_VPOS_END(vs_end));
@@ -1168,8 +1170,10 @@ static void dsi_op_mode_config(struct msm_dsi_host *msm_host,
 					DSI_IRQ_MASK_VIDEO_DONE, 0);
 	} else {
 		if (video_mode) {
+			dsi_ctrl &= ~DSI_CTRL_CMD_MODE_EN;
 			dsi_ctrl |= DSI_CTRL_VID_MODE_EN;
 		} else {		/* command mode */
+			dsi_ctrl &= ~DSI_CTRL_VID_MODE_EN;
 			dsi_ctrl |= DSI_CTRL_CMD_MODE_EN;
 			dsi_intr_ctrl(msm_host, DSI_IRQ_MASK_CMD_MDP_DONE, 1);
 		}

-- 
2.47.3

