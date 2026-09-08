From: Junrui Luo <moonafterrain@outlook.com>
Date: Tue, 08 Sep 2026 15:27:21 +0800
Subject: [PATCH v2] media: vicodec: zero-initialize stateful decoder heap
 buffers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-fixes-v2-1-4775af868cda@outlook.com>
X-B4-Tracking: v=1; b=H4sIANi4n2oC/y2MwQ6CMBBEf4Xs2Zq2CKWe/A/DAcoiG5U1LTYa0
 n+3opnTm5m8FQJ6wgDHYgWPkQLxnEHvCnBTN19Q0JAZtNS1tLIRI70wiO5QldqaURqnIX8fHrc
 hX89t5onCwv69aaP6tj9Do0oRyfGA7m+KSuSU0pi+6mun7Ymfy435und8hzal9AHTugV7pAAAA
 A==
X-Change-ID: 20260908-fixes-a453297f07c2
To: Hans Verkuil <hverkuil@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Keiichi Watanabe <keiichiw@chromium.org>, 
 Nicolas Dufresne <nicolas@ndufresne.ca>
Cc: Mauro Carvalho Chehab <mchehab+samsung@kernel.org>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yuhao Jiang <danisjiang@gmail.com>, stable@vger.kernel.org, 
 Junrui Luo <moonafterrain@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2104;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=H8Q/kdKbBfEfe7vkpaLiMv4vI0tAEFtnxHDHcSar3uw=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrPk7bl6ZsZOtY/HZomVM2zZUxDuza7fpufFsKrHUF
 OOr2Gr98kpHKQuDGBeDrJgiy/GCS98sfLfobvHZkgwzh5UJZAgDF6cATGRuBMNf8RvpN3fUaptp
 Prxf3VGisZDp97uQqxNYEsP906Iv7pNIZ/hfbnu1KPsHs7qvyKTT2ofP7mb7+8ncu1evzqrj4sw
 f7nO5AYPrS4g=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The stateful decoder leaks uninitialized kernel heap memory to userspace.
A process that can open the decoder video node gets it back in the CAPTURE
buffers it dequeues.

The reference frame and the compressed frame buffer are allocated with
kvmalloc() in vicodec_start_streaming(), and the decoder can read them
before they have been written. The first frame is allowed to be a P-frame,
in which case it is decoded against a reference frame that was never
produced, and the padding rows below the visible area are never written
for any frame.

Use kvzalloc() for both allocations.

Fixes: 256bf813ba39 ("media: vicodec: add the virtual codec driver")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
Changes in v2:
- Rewrite the commit message per Nicolas' review.
- Link to v1: https://lore.kernel.org/r/20260813-vicodec-fixes-v1-1-13077b5b6c29@outlook.com
---
 drivers/media/test-drivers/vicodec/vicodec-core.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/media/test-drivers/vicodec/vicodec-core.c b/drivers/media/test-drivers/vicodec/vicodec-core.c
index ff9d50fb05fd..0b898ed5801f 100644
--- a/drivers/media/test-drivers/vicodec/vicodec-core.c
+++ b/drivers/media/test-drivers/vicodec/vicodec-core.c
@@ -1595,9 +1595,9 @@ static int vicodec_start_streaming(struct vb2_queue *q,
 	}
 	state->ref_stride = q_data->coded_width * info->luma_alpha_step;
 
-	state->ref_frame.buf = kvmalloc(total_planes_size, GFP_KERNEL);
+	state->ref_frame.buf = kvzalloc(total_planes_size, GFP_KERNEL);
 	state->ref_frame.luma = state->ref_frame.buf;
-	new_comp_frame = kvmalloc(ctx->comp_max_size, GFP_KERNEL);
+	new_comp_frame = kvzalloc(ctx->comp_max_size, GFP_KERNEL);
 
 	if (!state->ref_frame.luma || !new_comp_frame) {
 		kvfree(state->ref_frame.luma);

---
base-commit: a500db7819c50db59e55f1b4fa1c3baa5a2616f3
change-id: 20260908-fixes-a453297f07c2

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

