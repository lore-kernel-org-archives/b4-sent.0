From: David Heidelberg <david@ixit.cz>
Date: Mon, 23 Nov 2026 13:02:41 +0100
Subject: [PATCH 3/4] media: ccs: Update PLL and blanking limits when
 pixel_array crop changes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-ccs-clanked-fixes-v1-3-fb2bcc87a517@ixit.cz>
References: <20261123-ccs-clanked-fixes-v1-0-fb2bcc87a517@ixit.cz>
In-Reply-To: <20261123-ccs-clanked-fixes-v1-0-fb2bcc87a517@ixit.cz>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: linux-media@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1591; i=david@ixit.cz;
 h=from:subject:message-id; bh=QGTTXuPwavl0KdtDE+/cVgC3PoTioJyQHFBbgY7e6Mk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrBCtfrQZHr5QZNgqzaTA3wMqKow1YFr91SM4DR
 2ld2lA5h/KJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawQrXwAKCRBgAj/E00kg
 cowoD/98zhQ4qAUK4OspU3IPh78f8LixDf4JaVX84noSwcQrQy0MZLz8wX2cpICq4Q4lz7Pmgsj
 xKBABRn7tQdWQjXQEoU0CtLO0vVI5bRInMGq/PxbTkK1WXYUvn/zMG2BARWR7jTSN+3vYV7FcGv
 rzNFPe4R+NQ1l0gPFuGcq9nZbPItohnT1miOH9gHZPiNOuWWWzHkBzzGrtYYLmjag4IH6BIPQOj
 ce/gdGz5ydHVoaYTZ3wN3tX7O0QBjsnDAcp+lM6GZYsGDg2j+q48iI6kK+yd3pqkREM5mftQSnm
 2I7X0ffZgtukfEg38VwI8OvpYbXtJxvslrUz+aBdotWGYmbblM1y6YwdtBwwxfp5bxD8CHmkIAp
 FAtD/3FK2Wux6LO2J52RK3sZzHHUlsdXXMQKHSIU5TnLPqMzt8EbOR45VMnl8fBN+evzIF5UJ2j
 6sYI3+raMNdpPk8wVNFEn2f9XLdq6dIUSBTqx7YZ9upgGzty9INSzX+PU3zRQjo75cO/P2g3KXR
 qBQaS6U5yfeJ1/bsEO/tik1l3Ea2Ba34k+BTTu8I5arIGeWt42cYl+G5mXSfIhLrpXmpkkC7x/m
 1UiPRVTEDbeOwR4DxikItk5C1pMGy7VKrBZV6LnmxS6RLCBo1y6L2G1JhvUBcqnUeD6Ff7/hzUg
 yi79T1qs28+T/Ow==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ccs_update_blanking() and __ccs_update_exposure_limits() compute the
VBLANK, HBLANK, and EXPOSURE control ranges relative to the pixel_array
source crop rectangle (pa_src). While ccs_set_compose() calls
ccs_pll_blanking_update() for active selections, ccs_set_crop() never
does, leaving blanking and exposure ranges stale after changing the
analog crop rectangle.

Call ccs_pll_blanking_update() at the end of ccs_set_crop() when
updating the active crop on the pixel_array sub-device.

Fixes: ccfc97bdb5ae ("[media] smiapp: Add driver")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/i2c/ccs/ccs-core.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/media/i2c/ccs/ccs-core.c b/drivers/media/i2c/ccs/ccs-core.c
index df636b8df0b51..85748c6110ecc 100644
--- a/drivers/media/i2c/ccs/ccs-core.c
+++ b/drivers/media/i2c/ccs/ccs-core.c
@@ -2573,16 +2573,20 @@ static int ccs_set_crop(struct v4l2_subdev *subdev,
 	sel->r.left = min_t(int, sel->r.left, src_size.width - sel->r.width);
 	sel->r.top = min_t(int, sel->r.top, src_size.height - sel->r.height);
 
 	*crop = sel->r;
 
 	if (ssd != sensor->pixel_array && sel->pad == CCS_PAD_SINK)
 		ccs_propagate(subdev, sd_state, V4L2_SEL_TGT_CROP);
 
+	if (ssd == sensor->pixel_array &&
+	    sel->which == V4L2_SUBDEV_FORMAT_ACTIVE)
+		return ccs_pll_blanking_update(sensor);
+
 	return 0;
 }
 
 static void ccs_get_native_size(struct ccs_subdev *ssd, struct v4l2_rect *r)
 {
 	r->top = 0;
 	r->left = 0;
 	r->width = CCS_LIM(ssd->sensor, X_ADDR_MAX) + 1;

-- 
2.55.0

