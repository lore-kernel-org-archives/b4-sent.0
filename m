From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 21 Oct 2026 14:03:26 +0800
Subject: [PATCH 2/5] media: i2c: it6625: reject DV timings changes while
 streaming
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-upstream-it6625-dv-timings-fix-v1-2-5881babdc4c2@ite.com.tw>
References: <20261021-upstream-it6625-dv-timings-fix-v1-0-5881babdc4c2@ite.com.tw>
In-Reply-To: <20261021-upstream-it6625-dv-timings-fix-v1-0-5881babdc4c2@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792562608; l=1961;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=2E6vyPI7NuJRNW/ZUJlvYSDjxi4Zgtor1gRn8WvnAGQ=;
 b=8H1ZMqeRTA6AU15ES0ZdmW5+cFygfvrIf05SDnQ6toWayDWSK8TR17jnFk/PZtfKPDLwpE+V9
 V8Xu/Rpli+yBEThtyJl/2jT6EDGDrpSPklKeWRymajhafF6H7aZGt5C
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

S_DV_TIMINGS replaced the configured timings and the ACTIVE pad format
while the subdev was streaming, so the reported pad format no longer
matched the stream being produced. it6625_set_fmt() already refuses to
change the format while streaming.

Return -EBUSY in that case, as documented for VIDIOC_S_DV_TIMINGS. The
check runs with the active state locked, after the identical-timings
and validity checks, so setting the same timings again still succeeds
and invalid timings still get -ERANGE.

it6625_pad_s_dv_timings() passed on only -ERANGE from
it6625_update_timings_if_changed() and returned 0 for anything else,
which would have reported -EBUSY as success. Pass every error on.

Fixes: 142e5f00bd57 ("media: i2c: add driver for ITE IT6625/IT6626")
Assisted-by: LLM
Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index 0d3bc83e4e865e55bb9940c7e958b85eedf9869a..a499b5e39acfbb1acaffc077d4f1fbdca3071a40 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -1483,6 +1483,8 @@ it6625_update_timings_if_changed(struct it6625 *it6625,
 						  it6625_get_timings_cap(it6625),
 						  NULL, NULL)) {
 			ret = -ERANGE;
+		} else if (v4l2_subdev_is_streaming(sd)) {
+			ret = -EBUSY;
 		} else {
 			it6625->timings = *timings;
 			it6625_fill_timings_format(&it6625->timings, fmt);
@@ -1588,8 +1590,9 @@ static int it6625_pad_s_dv_timings(struct v4l2_subdev *sd, unsigned int pad,
 		v4l2_print_dv_timings(sd->name, __func__, timings, false);
 
 	ret = it6625_update_timings_if_changed(it6625, timings);
-	if (ret == -ERANGE) {
-		v4l2_dbg(1, debug, sd, "%s: timings out of range", __func__);
+	if (ret < 0) {
+		v4l2_dbg(1, debug, sd, "%s: failed to set timings: %d",
+			 __func__, ret);
 		return ret;
 	}
 

-- 
2.34.1

