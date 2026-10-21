From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 21 Oct 2026 14:03:27 +0800
Subject: [PATCH 3/5] media: i2c: it6625: report the detected sync
 polarities
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-upstream-it6625-dv-timings-fix-v1-3-5881babdc4c2@ite.com.tw>
References: <20261021-upstream-it6625-dv-timings-fix-v1-0-5881babdc4c2@ite.com.tw>
In-Reply-To: <20261021-upstream-it6625-dv-timings-fix-v1-0-5881babdc4c2@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792562608; l=1444;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=HPSgHM3Y+fd8cDiU68xcmrplgXw3v/Q6cYK/4GDwOYE=;
 b=Fltqk1otKEOcTWFe2uWOLbCSM/tnXN1Ur6bY17AZWt/DkAoMX3p3QWS99VERVYZ+RWHR12951
 BbxRiwUeWLFBn1KW/uCwquCqtRZ+Nd/xu8aCSmvASztP4JT+5bFLGb6
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

QUERY_DV_TIMINGS always reported negative horizontal and vertical sync,
because the sync polarity bits of the video info register were never
read and bt->polarities stayed zero.

Bit 1 of the register is set for a positive horizontal sync and bit 2
for a positive vertical sync. This was measured with
negative/negative, positive/positive and negative-H/positive-V inputs;
the mixed case shows that the two bits map independently.

Map each bit to its V4L2_DV_*SYNC_POS_POL flag. The register and the
UAPI order the two bits differently, so they are mapped one by one.

Fixes: 142e5f00bd57 ("media: i2c: add driver for ITE IT6625/IT6626")
Assisted-by: LLM
Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index a499b5e39acfbb1acaffc077d4f1fbdca3071a40..85f10d10337130565a0799daa32311510e312a68 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -818,6 +818,8 @@ static int it6625_get_detected_timings(struct it6625 *it6625,
 
 	bt->interlaced = val & B_INTERLACE ?
 			 V4L2_DV_INTERLACED : V4L2_DV_PROGRESSIVE;
+	bt->polarities = (val & B_VSWPOL ? V4L2_DV_VSYNC_POS_POL : 0) |
+			 (val & B_HSWPOL ? V4L2_DV_HSYNC_POS_POL : 0);
 
 	if (it6625_read_bytes(it6625, REG_H_ACTIVE_1, (u8 *)&active, sizeof(active)) < 0)
 		return -EIO;

-- 
2.34.1

