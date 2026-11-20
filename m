From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 20 Nov 2026 01:13:16 +0000
Subject: [PATCH] tee: optee: check for the supplicant under supp->mutex
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-optee-supp-toctou-v1-1-d9a2bdea1c90@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBG4auQWTsJU6MGrmJcYPnRYUGbTmtMC
 Hen6PJbvLeSISmM+malhI+ahqVCTg3597C8wDpWk2vdVUQ6DjEDbCVGzsHnUHgcnL9MbXfDWah
 2MWHS7+95f/xt5TnD52NE27YDbTJKYnUAAAA=
X-Change-ID: 20261119-optee-supp-toctou-da2c5f097e31
To: Jens Wiklander <jenswi@kernel.org>, Sumit Garg <sumit.garg@kernel.org>
Cc: op-tee@lists.trustedfirmware.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795137196; l=2397;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=r+DQHxCOjcjVvvLW4z3rrN6VNbrbMcD//gJUMsCvQXA=;
 b=irKeG1tS1xjH2e5wZixMtRgpxVJnRQ42nvZOXhZQvcCjRW+s/qZsKt4qjlzxguZIhsC7zCLaY
 M6C+ScbZGmkAimKTGANjsQOXkqKi7IURLIKJZ756ptsYLTjbLFW2Hkr
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

optee_supp_thrd_req() checks supp->ctx without supp->mutex. If the
supplicant is released between the check and queueing, a supp_nowait
request is queued after optee_supp_release() aborted the queue and
waits until a new supplicant opens. For in-kernel clients that can
be forever.

Do the check under supp->mutex, together with queueing the request.

Fixes: 42bf4152d8a7 ("tee: add supp_nowait flag in tee_context struct")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Found by Sashiko in its review of [1]; the race is older than that patch.
Tested on an Orange Pi 5 (7.3-based, KASAN and lockdep) with a test-only
2 ms delay between the check and queueing; 1242 of 2000 supp_nowait
requests stranded without this patch, none with it. A real
tee-supplicant was not tested.

Developed with Claude (Anthropic), which wrote the code and the commit
message. I reviewed it.

[1] https://lore.kernel.org/r/20261115-optee-supp-close-v1-1-4e0b14f3a97c@gmail.com
---
 drivers/tee/optee/supp.c | 17 ++++++++++-------
 1 file changed, 10 insertions(+), 7 deletions(-)

diff --git a/drivers/tee/optee/supp.c b/drivers/tee/optee/supp.c
index 06747e90c230..fd8d1f363f2f 100644
--- a/drivers/tee/optee/supp.c
+++ b/drivers/tee/optee/supp.c
@@ -91,13 +91,6 @@ u32 optee_supp_thrd_req(struct tee_context *ctx, u32 func, size_t num_params,
 	struct optee_supp_req *req;
 	u32 ret;
 
-	/*
-	 * Return in case there is no supplicant available and
-	 * non-blocking request.
-	 */
-	if (!supp->ctx && ctx->supp_nowait)
-		return TEEC_ERROR_COMMUNICATION;
-
 	req = kzalloc_obj(*req);
 	if (!req)
 		return TEEC_ERROR_OUT_OF_MEMORY;
@@ -109,6 +102,16 @@ u32 optee_supp_thrd_req(struct tee_context *ctx, u32 func, size_t num_params,
 
 	/* Insert the request in the request list */
 	mutex_lock(&supp->mutex);
+	/*
+	 * Return in case there is no supplicant available and
+	 * non-blocking request.
+	 */
+	if (!supp->ctx && ctx->supp_nowait) {
+		mutex_unlock(&supp->mutex);
+		kfree(req);
+		return TEEC_ERROR_COMMUNICATION;
+	}
+
 	req->id = idr_alloc(&supp->idr, req, 1, 0, GFP_KERNEL);
 	if (req->id < 0) {
 		mutex_unlock(&supp->mutex);

---
base-commit: e21989d08e0d6abacfff71387d0cb36dd96a4079
change-id: 20261119-optee-supp-toctou-da2c5f097e31

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

