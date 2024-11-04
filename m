From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Mon, 04 Nov 2024 14:43:32 +0800
Subject: [PATCH v7 02/10] drm/bridge: it6505: improve AUX operation for
 edid read
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241104-v7-upstream-v7-2-8b71fd0f1d2d@ite.com.tw>
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
 Hermes Wu <Hermes.wu@ite.com.tw>, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730702658; l=1532;
 i=Hermes.wu@ite.com.tw; s=20241101; h=from:subject:message-id;
 bh=32P1BrTFeT18E3yzyJHILz0Ri1zpfzlb6udBE3GEmSs=;
 b=jAs4ALalPFcT/no3nP40m25b5d4wCMZzy9ChzrGptppyfoD/zleahHwKaciyvSguICLiNee66
 CacZdXxGEfmA1sLto+u5wJqWVQ1m7IwfxlxbzcRJXLAO7j8jXEfUYg2
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=FOYYbsP2Nlw6mjB3rLFYSLmAiENzj4AWQly5XTcDuMM=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241101 with auth_id=268
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The original AUX operation using data registers is limited to 4 bytes.
The AUX operation command CMD_AUX_I2C_EDID_READ uses AUX FIFO and
is capable of reading 16 bytes.
This improves the speed of EDID read.

Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@linaro.org>
Signed-off-by: Hermes Wu <hermes.wu@ite.com.tw>
---
 drivers/gpu/drm/bridge/ite-it6505.c | 10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/bridge/ite-it6505.c b/drivers/gpu/drm/bridge/ite-it6505.c
index 3272ca6951f2585f9592834869de23ac50ce41a4..9747d7ccf435d536da55c6a3ff79e504b7c724f0 100644
--- a/drivers/gpu/drm/bridge/ite-it6505.c
+++ b/drivers/gpu/drm/bridge/ite-it6505.c
@@ -1076,10 +1076,13 @@ static ssize_t it6505_aux_do_transfer(struct it6505 *it6505,
 				      size_t size, enum aux_cmd_reply *reply)
 {
 	int i, ret_size, ret = 0, request_size;
+	int fifo_max_size = (cmd == CMD_AUX_I2C_EDID_READ) ? AUX_FIFO_MAX_SIZE : 4;
 
 	mutex_lock(&it6505->aux_lock);
-	for (i = 0; i < size; i += 4) {
-		request_size = min((int)size - i, 4);
+	i = 0;
+	do {
+		request_size = min_t(int, (int)size - i, fifo_max_size);
+
 		ret_size = it6505_aux_operation(it6505, cmd, address + i,
 						buffer + i, request_size,
 						reply);
@@ -1088,8 +1091,9 @@ static ssize_t it6505_aux_do_transfer(struct it6505 *it6505,
 			goto aux_op_err;
 		}
 
+		i += request_size;
 		ret += ret_size;
-	}
+	} while (i < size);
 
 aux_op_err:
 	mutex_unlock(&it6505->aux_lock);

-- 
2.34.1

