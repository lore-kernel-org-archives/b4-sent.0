From: Richard Leitner <richard.leitner@linux.dev>
Date: Mon, 14 Sep 2026 21:21:03 +0200
Subject: [PATCH 06/10] media: i2c: ov9282: refresh flash_duration range on
 an HBLANK write
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-ov9282-fixes-v1-6-f520af59df1b@linux.dev>
References: <20260914-ov9282-fixes-v1-0-f520af59df1b@linux.dev>
In-Reply-To: <20260914-ov9282-fixes-v1-0-f520af59df1b@linux.dev>
To: Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Martina Krasteva <martinax.krasteva@intel.com>, 
 "Paul J. Murphy" <paul.j.murphy@intel.com>, 
 Daniele Alessandrelli <daniele.alessandrelli@gmail.com>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 Gyula Kelemen <gyula.kelemen@advasolutions.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.16-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789413683; l=1339;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=+9D94c2OnHxByotyk71RiVy678NF0Rq9EnxYDsY4DUE=;
 b=JZMY05pUX3MajCM1j9FFQ79UlIRT5svduZfkVMrNnEvqzNZy238MT6AzNBwL5QWAcgg8uqnnD
 RdSoL8Wu9EbDPb1Zb5bsQDN35moVeepLsqT9UU2PfDf0LSwndBOWPHK
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The strobe ceiling is the exposure time in microseconds, so it follows
the line time, and the line length sets the line time. Writing HBLANK moves
it and nothing recomputes the flash_duration ceiling.

Therefore add the missing flash_duration range update when HBLANK is set.

The exposure range is counted in lines, so it is unaffected and does not
need refreshing here.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index e64d8343c18e9..632184e76b9bd 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -674,6 +674,19 @@ static int ov9282_set_ctrl(struct v4l2_ctrl *ctrl)
 		if (ret)
 			return ret;
 		break;
+	case V4L2_CID_HBLANK:
+		/*
+		 * HBLANK affects the line time, which then affects the flash
+		 * duration. Therefore recalculate the flash duration range
+		 * here.
+		 */
+		exposure = ov9282_exposure_to_us(ov9282, ov9282->exp_ctrl->val);
+		ret = __v4l2_ctrl_modify_range(ov9282->flash_duration, 0,
+					       exposure, 1,
+					       OV9282_STROBE_FRAME_SPAN_DEFAULT);
+		if (ret)
+			return ret;
+		break;
 	}
 
 	/* Set controls only if sensor is in power on state */

-- 
2.53.0

