From: Junrui Luo <moonafterrain@outlook.com>
Date: Thu, 13 Aug 2026 13:51:58 +0800
Subject: [PATCH] media: vicodec: zero-initialize stateful decoder heap
 buffers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-vicodec-fixes-v1-1-13077b5b6c29@outlook.com>
X-B4-Tracking: v=1; b=H4sIAH1bfWoC/x3LSQqAMBAF0atIrw1kEKeriIvQ+WpvjCQgQvDuB
 pePogplJEGmuSmUcEuWeFaYtiE+/LlDSagmq22vR+PULRwDWG3yICs/GXBnzcBwVJ8r4Q91Wdb
 3/QBwAUhgXwAAAA==
X-Change-ID: 20260813-vicodec-fixes-a91ec4217ce3
To: Hans Verkuil <hverkuil@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Keiichi Watanabe <keiichiw@chromium.org>
Cc: Mauro Carvalho Chehab <mchehab+samsung@kernel.org>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yuhao Jiang <danisjiang@gmail.com>, stable@vger.kernel.org, 
 Junrui Luo <moonafterrain@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2248;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=Co0FqQGmxCGN7homuUKiJci3TA2XlUb++kqLUM8OU6I=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrNq4FcwX4xRVD+VW9a3mMk8/5theWmz79tQTHhnzE
 7+lLBZ0zu8oZWEQ42KQFVNkOV5w6ZuF7xbdLT5bkmHmsDKBDGHg4hSAiWz5zvBX/v/Ttem39G4H
 lC0Sy5pwZiLLyd+Gx+17D5ex5ha42N30ZmRo62NXf/JN+P0zLodwFZb7ugeD53uv33jOxXXyX97
 ZJn85AGjLStw=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vicodec_start_streaming() allocates state->ref_frame.buf and the
compressed_frame buffer with kvmalloc() for the stateful decoder and
leaves both uninitialized.

decode_plane() derives is_intra from the reference pointer being NULL
(is_intra = !ref) rather than from frame-sequence state, and the
stateful decoder always passes a valid ref, so a P-coded first frame
reaches add_deltas() over stale heap content that is then folded into
the decoded frame and returned via VIDIOC_DQBUF. The padding rows
between visible_height and coded_height leak on every P-frame as well,
since copy_cap_to_ref() writes only visible_height rows while
decode_plane() reads up to round_up(visible_height, 8). For
compressed_frame, only comp_size bytes are copied into the new
comp_max_size allocation, leaving the tail uninitialized for derlc() to
walk into.

Use kvzalloc() for both allocations.

Fixes: 256bf813ba39 ("media: vicodec: add the virtual codec driver")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 drivers/media/test-drivers/vicodec/vicodec-core.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/media/test-drivers/vicodec/vicodec-core.c b/drivers/media/test-drivers/vicodec/vicodec-core.c
index 318e8330f16a..7ebde8f3fc37 100644
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
base-commit: f5bbbfec59b4e2fb7520a91de3df8a6174325d6a
change-id: 20260813-vicodec-fixes-a91ec4217ce3

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

