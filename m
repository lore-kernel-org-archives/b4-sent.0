From: =?utf-8?q?Y=C4=B0=C4=9E=C4=B0TCAN_KAVAKLI?= <kavakliyigitcan@gmail.com>
Date: Fri, 11 Sep 2026 11:51:06 +0300
Subject: [PATCH RFC 09/10] drm/msm/dsi: separate host link enable from
 video stream enable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260911-ginkgo-submission-final-v1-9-0e68e63a18d4@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789116671; l=4404;
 i=kavakliyigitcan@gmail.com; s=20260911; h=from:subject:message-id;
 bh=V8nqA1aw4sLc5FPA3CMsuU6cEpTrAqNLa+vYEEKpC58=;
 b=Xgf0bzykBXhHaxOrLtuXKDxVfuAVHziW83ocSKAKZpSsd2068AHVSXqKBe+Olh/lzxrqVGPzv
 eJMuE07GXCkCuR070oxMTfkNJaNJCaUrsGpJoK9vi85cEDPhpsUfB0k
X-Developer-Key: i=kavakliyigitcan@gmail.com; a=ed25519;
 pk=W2GaxVotULs2vAjRMMLheaDtMMYs4037zO1LVVfFtPI=
X-Endpoint-Received: by B4 Relay for kavakliyigitcan@gmail.com/20260911 with auth_id=1024
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In video mode DSI displays, enabling the host previously engaged the
hardware video engine immediately during atomic_pre_enable. When panel
prepare routines transmit initial DCS sleep-out and setup commands,
concurrent active video transmission causes DMA timeouts (-110).

Keep the DSI host in command mode during atomic_pre_enable to permit
clean panel preparation, and start video streaming in atomic_enable
after the panel has completed initialization.

Signed-off-by: YİĞİTCAN KAVAKLI <kavakliyigitcan@gmail.com>
---
 drivers/gpu/drm/msm/dsi/dsi.h         |  1 +
 drivers/gpu/drm/msm/dsi/dsi_host.c    | 23 ++++++++++++-----------
 drivers/gpu/drm/msm/dsi/dsi_manager.c | 20 ++++++++++++++++++++
 3 files changed, 33 insertions(+), 11 deletions(-)

diff --git a/drivers/gpu/drm/msm/dsi/dsi.h b/drivers/gpu/drm/msm/dsi/dsi.h
index 93c028a122f3a59b1632da76472e0a3e781c6ae8..cfb2b51cae0a9227fbe88ecc5291ac1a9f82a5ce 100644
--- a/drivers/gpu/drm/msm/dsi/dsi.h
+++ b/drivers/gpu/drm/msm/dsi/dsi.h
@@ -69,6 +69,7 @@ int msm_dsi_host_cmd_rx(struct mipi_dsi_host *host,
 void msm_dsi_host_cmd_xfer_commit(struct mipi_dsi_host *host,
 					u32 dma_base, u32 len);
 int msm_dsi_host_enable(struct mipi_dsi_host *host);
+void msm_dsi_host_enable_video(struct mipi_dsi_host *host);
 int msm_dsi_host_disable(struct mipi_dsi_host *host);
 void msm_dsi_host_enable_irq(struct mipi_dsi_host *host);
 void msm_dsi_host_disable_irq(struct mipi_dsi_host *host);
diff --git a/drivers/gpu/drm/msm/dsi/dsi_host.c b/drivers/gpu/drm/msm/dsi/dsi_host.c
index b9e2867d435a3ad8b6db6b57c440bbd827180b6e..b2702f772ee195b2758433d98d0f071e3f55955e 100644
--- a/drivers/gpu/drm/msm/dsi/dsi_host.c
+++ b/drivers/gpu/drm/msm/dsi/dsi_host.c
@@ -2438,22 +2438,23 @@ int msm_dsi_host_enable(struct mipi_dsi_host *host)
 {
 	struct msm_dsi_host *msm_host = to_msm_dsi_host(host);
 
-	dsi_op_mode_config(msm_host,
-		!!(msm_host->mode_flags & MIPI_DSI_MODE_VIDEO), true);
-
-	/* TODO: clock should be turned off for command mode,
-	 * and only turned on before MDP START.
-	 * This part of code should be enabled once mdp driver support it.
-	 */
-	/* if (msm_panel->mode == MSM_DSI_CMD_MODE) {
-	 *	dsi_link_clk_disable(msm_host);
-	 *	pm_runtime_put(&msm_host->pdev->dev);
-	 * }
+	/* Keep DSI host in command mode (VID_MODE_EN = 0) during panel init
+	 * to allow clean DCS communication without premature video engine startup.
 	 */
+	dsi_op_mode_config(msm_host, false, true);
+
 	msm_host->enabled = true;
 	return 0;
 }
 
+void msm_dsi_host_enable_video(struct mipi_dsi_host *host)
+{
+	struct msm_dsi_host *msm_host = to_msm_dsi_host(host);
+
+	if (msm_host->mode_flags & MIPI_DSI_MODE_VIDEO)
+		dsi_op_mode_config(msm_host, true, true);
+}
+
 int msm_dsi_host_disable(struct mipi_dsi_host *host)
 {
 	struct msm_dsi_host *msm_host = to_msm_dsi_host(host);
diff --git a/drivers/gpu/drm/msm/dsi/dsi_manager.c b/drivers/gpu/drm/msm/dsi/dsi_manager.c
index 959daa88b1d022da5f552bb21ca7c04006524fa4..9e3f125ec4ea8e3fae50c8226e67b4106c01dc76 100644
--- a/drivers/gpu/drm/msm/dsi/dsi_manager.c
+++ b/drivers/gpu/drm/msm/dsi/dsi_manager.c
@@ -446,12 +446,32 @@ static int dsi_mgr_bridge_attach(struct drm_bridge *bridge,
 				 bridge, flags);
 }
 
+static void dsi_mgr_bridge_enable(struct drm_bridge *bridge,
+				  struct drm_atomic_commit *commit)
+{
+	int id = dsi_mgr_bridge_get_id(bridge);
+	struct msm_dsi *msm_dsi = dsi_mgr_get_dsi(id);
+	struct msm_dsi *msm_dsi1 = dsi_mgr_get_dsi(DSI_1);
+	struct mipi_dsi_host *host = msm_dsi->host;
+	bool is_bonded_dsi = IS_BONDED_DSI();
+
+	DBG("id=%d", id);
+
+	if (is_bonded_dsi && !IS_MASTER_DSI_LINK(id))
+		return;
+
+	msm_dsi_host_enable_video(host);
+	if (is_bonded_dsi && msm_dsi1)
+		msm_dsi_host_enable_video(msm_dsi1->host);
+}
+
 static const struct drm_bridge_funcs dsi_mgr_bridge_funcs = {
 	.atomic_create_state = drm_atomic_helper_bridge_create_state,
 	.atomic_destroy_state = drm_atomic_helper_bridge_destroy_state,
 	.atomic_duplicate_state = drm_atomic_helper_bridge_duplicate_state,
 	.attach = dsi_mgr_bridge_attach,
 	.atomic_pre_enable = dsi_mgr_bridge_pre_enable,
+	.atomic_enable = dsi_mgr_bridge_enable,
 	.atomic_post_disable = dsi_mgr_bridge_post_disable,
 	.mode_set = dsi_mgr_bridge_mode_set,
 	.mode_valid = dsi_mgr_bridge_mode_valid,

-- 
2.47.3

