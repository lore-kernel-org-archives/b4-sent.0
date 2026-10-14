From: Richard Leitner <richard.leitner@linux.dev>
Date: Wed, 14 Oct 2026 08:49:08 +0200
Subject: [PATCH v2 1/8] media: i2c: ov9282: handle error from exposure
 range update
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-ov9282-fixes-v2-1-3bb376d8b1a9@linux.dev>
References: <20261014-ov9282-fixes-v2-0-3bb376d8b1a9@linux.dev>
In-Reply-To: <20261014-ov9282-fixes-v2-0-3bb376d8b1a9@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Daniele Alessandrelli <daniele.alessandrelli@gmail.com>, 
 "Paul J. Murphy" <paul.j.murphy@intel.com>, 
 Martina Krasteva <martinax.krasteva@intel.com>, 
 Richard Leitner <richard.leitner@linux.dev>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>, Bryan O'Donoghue <bod@kernel.org>, 
 Jacopo Mondi <jacopo@jmondi.org>
Cc: Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 Gyula Kelemen <gyula.kelemen@advasolutions.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791960586; l=1053;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=zgzIKcPpPlhwn+/jD26bwEQDWYZk4cqXx3wE756XGPw=;
 b=McsawXTKwPYKEZZ9iQYdUz3LTZT5hDS9NIGhgxUPF62Ln+fU+AuYx22pKn/FfCL2X4D93b2iP
 +1H2r/zhWeTC2EjRzKU6ml+MSwZ/DPpre31OWMdWxFgoTJXt7W6zOJO
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When setting V4L2_CID_VBLANK the V4L2 range for the exposure control is
updated by v4l2_ctrl_modify_range(). This range update missed a return
value check, which resulted in ov9282_set_ctrl() not returning on an error
from that function call.

Fix this by checking the return value and returning it on error.

Reviewed-by: Dave Stevenson <dave.stevenson@raspberrypi.com>
Fixes: 14ea315bbeb75 ("media: i2c: Add ov9282 camera sensor driver")
Cc: stable@vger.kernel.org
Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index 5d301660a87d8..c10b2e205834e 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -608,6 +608,8 @@ static int ov9282_set_ctrl(struct v4l2_ctrl *ctrl)
 					       ov9282->cur_mode->height -
 					       OV9282_EXPOSURE_OFFSET,
 					       1, OV9282_EXPOSURE_DEFAULT);
+		if (ret)
+			return ret;
 		break;
 	}
 

-- 
2.53.0

