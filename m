From: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
Date: Mon, 05 Jan 2026 21:24:44 +0100
Subject: [PATCH 5/5] drm/panel: mantix: Don't turn on MIPI peripheral
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-mantix-halo-fixes-v1-5-1ebc9b195a34@puri.sm>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=750;
 i=sebastian.krzyszkowiak@puri.sm; h=from:subject:message-id;
 bh=wzX3EhJOQLlO3siwfFm5QsCfUWD8LUAgzLS3TEqb+Y0=;
 b=owEBbQKS/ZANAwAKAejyNc8728P/AcsmYgBpXB4fA4zf203rKJwuSpxRbHLhNyBMcGZElCcow
 ikVSWuREM6JAjMEAAEKAB0WIQQi3Z+uAGoRQ1g2YXzo8jXPO9vD/wUCaVweHwAKCRDo8jXPO9vD
 /6XQD/9YRWHVJHTuVsWdmpefFhuqrkdQ4Mal2qi/muZg0wXJqkQakGc7qMqEwWdsiqdgKTVAyaj
 T4gDxtULVY89EYuiHMRYT5Apk9mmPjm+P4114lOTV5Jr8XGXq8Rww4DijAoXDR5esbJbh6A+Cfl
 S9azg+ADcfhtfIzD+GOspjmgpXh0GTP20Ywhzucb6Eao65KbmE39A/Wvqo1QZAeX1BDhH6ErqSH
 dx33Ea7AoZ+es4qfpVmKtBw2aO8buKlzdKmH13UfTyO0kO7Q49WgeAKweuIcwvGZ+w+ga8QLkea
 VvuLLOQW+AJrdunHSAXuqrYjKCvCJa+ikPZpLE/qVJQJvYxSEAti09Gws/GwooftgBOImtAI/gz
 eVvW1AqfAexss1JiBsL60eyepD4u6W4rsegdKq9RZG5ZEJzpNmPKGUx8P+Rwz0xqORbirtk2Ves
 5uafx7i8Hdfkfr5XdAuRxTMfJcFXHA1FDNVMYE2wkoRmzgElx0U/kuLDZgSOzx5MgymTwGH+88W
 06lHpDwdKBobcjMcXPdGc9+rFqh9+7jpVKh6PIo0K8ylElkJFjk+4PMOyt6JcLH+IimHgeOh7/D
 yZlzhGY8A9JkQvTf2BVyLsmUTF2sagYt/n73ejLWlvAggj8K5ZqMTIz0V4ocz6/cKZhL9GsHMdg
 6Kz4zgVb/FdQV1g==
X-Developer-Key: i=sebastian.krzyszkowiak@puri.sm; a=openpgp;
 fpr=22DD9FAE006A11435836617CE8F235CF3BDBC3FF
X-Endpoint-Received: by B4 Relay for sebastian.krzyszkowiak@puri.sm/default with auth_id=32
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It's not necessary with these panels.

Signed-off-by: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
---
 drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c | 2 --
 1 file changed, 2 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c b/drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c
index 30e378faafcd..13352cb4ad77 100644
--- a/drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c
+++ b/drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c
@@ -80,8 +80,6 @@ static int mantix_enable(struct drm_panel *panel)
 	mipi_dsi_dcs_set_display_on_multi(&dsi_ctx);
 	mipi_dsi_usleep_range(&dsi_ctx, 10000, 12000);
 
-	mipi_dsi_turn_on_peripheral_multi(&dsi_ctx);
-
 	return dsi_ctx.accum_err;
 }
 

-- 
2.52.0

