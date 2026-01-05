From: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
Date: Mon, 05 Jan 2026 21:24:41 +0100
Subject: [PATCH 2/5] drm/panel: mantix: Improve power on sequence timings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-mantix-halo-fixes-v1-2-1ebc9b195a34@puri.sm>
References: <20260105-mantix-halo-fixes-v1-0-1ebc9b195a34@puri.sm>
In-Reply-To: <20260105-mantix-halo-fixes-v1-0-1ebc9b195a34@puri.sm>
To: =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>, 
 Purism Kernel Team <kernel@puri.sm>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2841;
 i=sebastian.krzyszkowiak@puri.sm; h=from:subject:message-id;
 bh=+lx7oCnZsmz/hc+E2uLHt5Sr9SJYKGdqkUO7Y9TOBro=;
 b=owEBbQKS/ZANAwAKAejyNc8728P/AcsmYgBpXB4f/GmJrvlrjFV+kFaqlM8tsoozNtfq0l8re
 dXchf5Xx1eJAjMEAAEKAB0WIQQi3Z+uAGoRQ1g2YXzo8jXPO9vD/wUCaVweHwAKCRDo8jXPO9vD
 /8aLD/0XAsfH4wAd4HcK59CrMKyM3EmfoTOGwWMw6CA4VKIkQd52yS7TnCLTm/E/MvSZqsIXfIX
 QeckWjjUpwyHg3I43k/GF/OYYFfzYvvX5VZIeq7pEmWrWbSJnGT19QktMgk2fAB3h7IgrUzFx3u
 MwElljOjJdbesFzbKOWXxnKlZCg7uJ86otSt58uydb1d5T5ZicbyUXwSQdS1vR8Iz0rTIRjhp8e
 +14CBtT62UzXz/g/NcNjezve/U876rBgDeTXy3JttC1rhuIpyzkkw9NsdbEcrDdcKS4P/j8pQ1q
 nLlqei/TZP+hy+xqNwSJWW/K7dsBXcza/y9mTXMbA+LZcTokQoah7cEbznpCY/rb/82O6s9lySs
 iYtGXBT/PqK6kfkGkK7Xp0ORRe5ehke6AJZMqSAICYeBzk3nlcejCgtWrUJaSJMUQJxxTkr4fyt
 hj4hc3X75LvxRb9LUK1KL03SHF9iFMYLomH2RutZDA11ra1s1YJVQjjNqbUEVYtjjdrWKffjhZO
 F5lY+YZdaZ750pG9EsyfW/rPq/qgzlsX5c+ME4MKExoowkX86Si+zSLWEPATtlFH6qcz3v4CWpM
 35YiWv5YER+jwhUVXoZ0J487Ar4HQEdoNtLhbW/KXZTrxOjwHBpn+kuJdZ9LnEQlUcNcqLohX95
 ekitXjoGK3cReKQ==
X-Developer-Key: i=sebastian.krzyszkowiak@puri.sm; a=openpgp;
 fpr=22DD9FAE006A11435836617CE8F235CF3BDBC3FF
X-Endpoint-Received: by B4 Relay for sebastian.krzyszkowiak@puri.sm/default with auth_id=32
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

FP8006P datasheet mentions:

> It is necessary to wait 15msec after releasing RESX before sending
> commands. Also Sleep Out command cannot be sent for 120 msec.

This hasn't been respected by the driver so far, which could interfere
with the LCD init code sequence performed by the controller. In some cases
this leads to VCOM voltage being set to a wrong value, causing "halo"
effects, temporary burn-in around the edges of the screen and degraded
image contrast.

T3 and T4 are counted from when VDDI is enabled. There's no need to add
them when we've already waited more than that in T2 and T2d.

While FT8006P datasheet does not mention a delay between exiting sleep
mode and turning the display on, code provided by the vendor uses 120ms
there and it happens to be the same value as required in newer datasheets
for newer controllers from the same family, so it seems appropriate to
use it here as well.

Signed-off-by: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
---
 drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c | 13 +++++++------
 1 file changed, 7 insertions(+), 6 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c b/drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c
index fafd80f3e952..bb5489e4d7a9 100644
--- a/drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c
+++ b/drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c
@@ -58,11 +58,9 @@ static void mantix_init_sequence(struct mipi_dsi_multi_context *dsi_ctx)
 
 	mipi_dsi_generic_write_seq_multi(dsi_ctx, MANTIX_CMD_OTP_STOP_RELOAD_MIPI, 0x5a, 0x09);
 	mipi_dsi_generic_write_seq_multi(dsi_ctx, 0x80, 0x64, 0x00, 0x64, 0x00, 0x00);
-	mipi_dsi_msleep(dsi_ctx, 20);
 
 	mipi_dsi_generic_write_seq_multi(dsi_ctx, MANTIX_CMD_SPI_FINISH, 0xa5);
 	mipi_dsi_generic_write_seq_multi(dsi_ctx, MANTIX_CMD_OTP_STOP_RELOAD_MIPI, 0x00, 0x2f);
-	mipi_dsi_msleep(dsi_ctx, 20);
 }
 
 static int mantix_enable(struct drm_panel *panel)
@@ -75,8 +73,11 @@ static int mantix_enable(struct drm_panel *panel)
 	if (!dsi_ctx.accum_err)
 		dev_dbg(ctx->dev, "Panel init sequence done\n");
 
+	/* remainder to 120ms (7.3.1 Note 4) */
+	mipi_dsi_msleep(&dsi_ctx, 70);
+
 	mipi_dsi_dcs_exit_sleep_mode_multi(&dsi_ctx);
-	mipi_dsi_msleep(&dsi_ctx, 20);
+	mipi_dsi_msleep(&dsi_ctx, 120);
 
 	mipi_dsi_dcs_set_display_on_multi(&dsi_ctx);
 	mipi_dsi_usleep_range(&dsi_ctx, 10000, 12000);
@@ -147,10 +148,10 @@ static int mantix_prepare(struct drm_panel *panel)
 		return ret;
 	}
 
-	/* T3 + T4 + time for voltage to become stable: */
-	usleep_range(6000, 7000);
-	gpiod_set_value_cansleep(ctx->reset_gpio, 0);
+	usleep_range(100, 200);
 	gpiod_set_value_cansleep(ctx->tp_rstn_gpio, 0);
+	usleep_range(100, 200);
+	gpiod_set_value_cansleep(ctx->reset_gpio, 0);
 
 	/* T6 */
 	msleep(50);

-- 
2.52.0

