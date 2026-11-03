From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Tue, 03 Nov 2026 11:05:07 +0800
Subject: [PATCH v2 4/5] media: i2c: it6625: fix the second-field vertical
 timings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-upstream-it6625-dv-timings-fix-v2-4-127b879da6d3@ite.com.tw>
References: <20261103-upstream-it6625-dv-timings-fix-v2-0-127b879da6d3@ite.com.tw>
In-Reply-To: <20261103-upstream-it6625-dv-timings-fix-v2-0-127b879da6d3@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793675109; l=1934;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=kjV6HwTublUdyqILykbIunpVKxzo/F9RhLJo1ICO5Lk=;
 b=IRW6ENPtai6JniH1HJKJaLkoKekUtHW+QoNJv62PtPvhePbCjLk3ax2CsuLJ1rL0FwaQ1b9Y3
 Ou3tTgg/gwSCJ05tqNufuO4ZOpWCORk0Gt6gbGt8sksBvC6DuCcNr+c
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For interlaced input, the driver reported the second field with a
vertical sync of vsync + 1 lines and zero front and back porches. A
1080i frame then totalled 1108 lines instead of 1125, and any rate
derived from the detected timings was wrong.

The vertical active, total and porch/sync registers hold the values of
the first field: on 1080i input they read 540 active and 562 total
lines, with a 2/5/15 line front porch/sync/back porch.

Derive the second field the way the CEA-861 interlaced formats define
it, and as the interlaced presets in v4l2-dv-timings.h describe it:
the same front porch and sync as the first field, and one more
back-porch line. Without V4L2_DV_FL_FIRST_FIELD_EXTRA_LINE, the extra
line of an odd frame total belongs to the second field. The detected
1080i50 and 1080i60 vertical timings now equal those of the CEA
presets, 1125 lines per frame.

Fixes: 142e5f00bd57 ("media: i2c: add driver for ITE IT6625/IT6626")
Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index 85f10d10337130565a0799daa32311510e312a68..75bcb8304c02c7c0c5feeb02af6c93378fcfa5d7 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -839,8 +839,15 @@ static int it6625_get_detected_timings(struct it6625 *it6625,
 
 	bt->pixelclock = it6625_get_pclk(it6625);
 	if (bt->interlaced == V4L2_DV_INTERLACED) {
+		/*
+		 * The vertical registers hold the first field. As in the
+		 * CEA-861 interlaced formats, the second field has the same
+		 * front porch and sync, and one more back-porch line.
+		 */
 		bt->height *= 2;
-		bt->il_vsync = bt->vsync + 1;
+		bt->il_vfrontporch = bt->vfrontporch;
+		bt->il_vsync = bt->vsync;
+		bt->il_vbackporch = bt->vbackporch + 1;
 	}
 
 	return 0;

-- 
2.34.1

