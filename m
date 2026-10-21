From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 21 Oct 2026 14:03:25 +0800
Subject: [PATCH 1/5] media: i2c: it6625: keep the configured DV timings on
 5V changes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-upstream-it6625-dv-timings-fix-v1-1-5881babdc4c2@ite.com.tw>
References: <20261021-upstream-it6625-dv-timings-fix-v1-0-5881babdc4c2@ite.com.tw>
In-Reply-To: <20261021-upstream-it6625-dv-timings-fix-v1-0-5881babdc4c2@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792562608; l=2162;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=7IBszv5mgeCCnM+3Dp8JO2qhtzhMhD85q51gl4iqtKo=;
 b=bFax78KbrxQjJO6gCUSUvl/OJLSj+uwyWcVWczBRH+zKwusUZPtEwT6VP+WcTQkeVzKNEQZnh
 1JxAQ1RcOvdDHvNseCpo/bTqrnl0Jfi43AT48y5TNhqo7nXz+g3ByNQ
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Every change of the HDMI 5V state cleared the configured DV timings and
set the ACTIVE pad format to 0x0. Both stayed that way after the input
came back, until userspace set the timings again, so G_DV_TIMINGS and
the pad format no longer reflected what had been configured.

The V4L2 API says receivers must not change the configured timings on
their own when the input changes; that is left to the application.
Userspace still learns about signal loss from the
V4L2_CID_DV_RX_POWER_PRESENT control and its event, from
QUERY_DV_TIMINGS returning -ENOLINK, and from the source-change event.
None of these depended on clearing the timings.

Drop the clear from the 5V interrupt handler, together with
it6625_clear_timings(), which has no other user.

Fixes: 142e5f00bd57 ("media: i2c: add driver for ITE IT6625/IT6626")
Assisted-by: LLM
Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 15 ---------------
 1 file changed, 15 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index b74df9dbf8c2cab7461c69bc0f926141ed7a506c..0d3bc83e4e865e55bb9940c7e958b85eedf9869a 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -1192,26 +1192,11 @@ static void it6625_fill_timings_format(const struct v4l2_dv_timings *timings,
 		     V4L2_FIELD_INTERLACED : V4L2_FIELD_NONE;
 }
 
-static void it6625_clear_timings(struct it6625 *it6625)
-{
-	struct v4l2_subdev *sd = &it6625->sd;
-	struct v4l2_subdev_state *state = v4l2_subdev_lock_and_get_active_state(sd);
-	struct v4l2_mbus_framefmt *fmt = v4l2_subdev_state_get_format(state, 0);
-
-	scoped_guard(mutex, &it6625->it6625_lock) {
-		memset(&it6625->timings, 0, sizeof(it6625->timings));
-		it6625_fill_timings_format(&it6625->timings, fmt);
-	}
-
-	v4l2_subdev_unlock_state(state);
-}
-
 static void it6625_irq_hdmi_5v_change(struct it6625 *it6625)
 {
 	struct v4l2_subdev *sd = &it6625->sd;
 	int ret;
 
-	it6625_clear_timings(it6625);
 	ret = it6625_v4l2_sd_ctrl_update(sd);
 	if (ret)
 		dev_err(it6625->dev, "%s: failed to update controls: %d", __func__, ret);

-- 
2.34.1

