From: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
Date: Mon, 05 Jan 2026 21:24:40 +0100
Subject: [PATCH 1/5] drm/panel: mantix: Enable DSI LPM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-mantix-halo-fixes-v1-1-1ebc9b195a34@puri.sm>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=876;
 i=sebastian.krzyszkowiak@puri.sm; h=from:subject:message-id;
 bh=ranr7EXhYO2dHs5BA4aYCo8Op/vp1BIUidKU26E9D+M=;
 b=owEBbQKS/ZANAwAKAejyNc8728P/AcsmYgBpXB4fO3h3CtAiFssxXnaLfy8p9UQeh2skVa7wq
 Pw6PiGUgfSJAjMEAAEKAB0WIQQi3Z+uAGoRQ1g2YXzo8jXPO9vD/wUCaVweHwAKCRDo8jXPO9vD
 /36nD/9ZEHP3wwbu7iRj/w4bPjdu7Akmd9Wsay+D5b/l4rEdvqdzdG1b7nbixPCPiO8vhHvyPBz
 385E/llSqbZjaK2J3SI5gZSHJ4gswJxTFjTktedOgvPFv4fZcHvFT4aqX8PA+EDo17bJOtMyOfV
 ExZ1xI8hw+Ot3ZPKS3f8yiFOYHskYv8M3OUt7ZJtLNXR0Ba5nL4e11wsA2zHLlyU7EgObCqZx5n
 VrYgQ4PKZST6jog3aM3aTacUNuJPD74zlW1FB116vrznUt0ikOoj6GMGWgyJ1SdLwMm6w8NliUP
 yybleFHCqTV1yL7Vz20/87thgnZv8E1Gwy5/QENfuCXC5XbSd+n+f65YdmP1heaFnNxaK7aYR4T
 hkXbH/P1UWA6m62Y38yzSK7qXUJhnN91P+6bO3ZBTLTNTha8kbtaKlBueW4p/6M75fq3+LE+djA
 DvMlL4k5eN7Q7YVLqUzoEvNvUaz0Hfq12y8RZ/kW/hYf1BtbN77+DIKtTJpAKpollaIHOD/45gL
 0OordlYds5ZIcga/3aXMCkeosBRpyMn7g2OO58xVqMDQNYxB3fhRcSVKc7cMpIk6IBnQCnkmvar
 WI+XRAy3oQ2qopxSx+3mtR5eL6pwZu6YUtWG8Zj8D+VvsihDqWNUcIa84B7Dq1/4ekLgQN2ZKbf
 hMJ8SPtJeBNliFw==
X-Developer-Key: i=sebastian.krzyszkowiak@puri.sm; a=openpgp;
 fpr=22DD9FAE006A11435836617CE8F235CF3BDBC3FF
X-Endpoint-Received: by B4 Relay for sebastian.krzyszkowiak@puri.sm/default with auth_id=32
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This improves reliability of sending DSI commands.

Signed-off-by: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
---
 drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c b/drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c
index 55664f5d5aa5..fafd80f3e952 100644
--- a/drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c
+++ b/drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c
@@ -258,7 +258,7 @@ static int mantix_probe(struct mipi_dsi_device *dsi)
 
 	dsi->lanes = 4;
 	dsi->format = MIPI_DSI_FMT_RGB888;
-	dsi->mode_flags = MIPI_DSI_MODE_VIDEO |
+	dsi->mode_flags = MIPI_DSI_MODE_VIDEO | MIPI_DSI_MODE_LPM |
 		MIPI_DSI_MODE_VIDEO_BURST | MIPI_DSI_MODE_VIDEO_SYNC_PULSE;
 
 	ctx->avdd = devm_regulator_get(dev, "avdd");

-- 
2.52.0

