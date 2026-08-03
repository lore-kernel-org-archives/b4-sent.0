From: Junrui Luo <moonafterrain@outlook.com>
Date: Mon, 03 Aug 2026 15:29:36 +0800
Subject: [PATCH] media: vicodec: fix NULL deref on oversized frame
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-vicodec-fixes-v1-1-f3cc40cacd05@outlook.com>
X-B4-Tracking: v=1; b=H4sIAF9DcGoC/x3LTQqAIBBA4avErBP8qbCuEi1Cx5qNhoIE4t0bW
 n48XoOCmbDANjTIWKlQigw1DuDuM14oyLNBS71IK42o5JJHJwK9WESwRplVG5zUDPw8Gf/Ay37
 0/gGlSAuEXwAAAA==
X-Change-ID: 20260803-vicodec-fixes-f8313923e415
To: Hans Verkuil <hverkuil@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Dafna Hirschfeld <dafna3@gmail.com>
Cc: Mauro Carvalho Chehab <mchehab+samsung@kernel.org>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Nicolas Dufresne <nicolas@ndufresne.ca>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Yuhao Jiang <danisjiang@gmail.com>, 
 stable@vger.kernel.org, Junrui Luo <moonafterrain@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2344;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=iV3617BfwTniNi3UKnCkcCHXT5MEjJv0HupDO6zG/sQ=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrALnRosKNnO1BXc+WMzrUhcLu3bjFMdO4ZyWL3rLt
 QIzWzz/WHSUsjCIcTHIiimyHC+49M3Cd4vuFp8tyTBzWJlAhjBwcQrARHZnMDLcaH5U8mXvl6/+
 1pNS+gOWKTrsY/sUo/V66Rm207xfPr0IZ2RorFzk9n7NaZb1re+0NRWOB9+wvZFuvH+22fbH8g/
 5Ap/xAAAntku5
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

job_ready() only honours the is_header_valid() verdict when
ctx->comp_has_frame is set, and comp_has_frame is only set once
comp_size reaches the full frame size. Since the copy is clamped to
ctx->comp_max_size, a header advertising a larger size leaves comp_size
stuck at comp_max_size, so comp_has_frame stays false and the failed
validation is discarded.

Control then falls into the resolution change branch, which calls
update_capture_data_from_header(). That function re-derives info via
info_from_header(), assigns it to q_dst->info and dereferences it as
q_dst->info->sizeimage_mult, with no NULL check of its own.
is_header_valid() does check that same info_from_header() result --
if (!info) return false which is precisely the false verdict
job_ready() discarded above. info_from_header() returns NULL whenever the
header flags resolve to no supported pixel format.

Drop the comp_has_frame conjunct so an invalid header always bails out.
The resolution change path is unaffected, as it is entered with a valid
header. Oversized frames are then rejected by device_process(), which
already returns -EINVAL when comp_frame_size exceeds comp_max_size.

Fixes: 3b15f68e19c2 ("media: vicodec: Add support for resolution change event.")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 drivers/media/test-drivers/vicodec/vicodec-core.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/media/test-drivers/vicodec/vicodec-core.c b/drivers/media/test-drivers/vicodec/vicodec-core.c
index 318e8330f16a..dfc8dde4bad6 100644
--- a/drivers/media/test-drivers/vicodec/vicodec-core.c
+++ b/drivers/media/test-drivers/vicodec/vicodec-core.c
@@ -654,7 +654,7 @@ static int job_ready(void *priv)
 	 * if the header is invalid the device_run will just drop the frame
 	 * with an error
 	 */
-	if (!is_header_valid(&ctx->state.header) && ctx->comp_has_frame)
+	if (!is_header_valid(&ctx->state.header))
 		return 1;
 	flags = ntohl(ctx->state.header.flags);
 	hdr_width_div = (flags & V4L2_FWHT_FL_CHROMA_FULL_WIDTH) ? 1 : 2;

---
base-commit: 075b74841bd0065a3bda3440873c747938e69b68
change-id: 20260803-vicodec-fixes-f8313923e415

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

