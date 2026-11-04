From: orkunsari <sariorkunemin@gmail.com>
Date: Wed, 04 Nov 2026 14:56:19 +0300
Subject: [PATCH] io_uring: only wait for in-flight requests if the closing
 task uses the ring
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-io-uring-wait-inflight-v1-1-4361a0905e20@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSwqDMBRG4a3IHfeCER+lW5EOYryJfylRkvgAc
 e9N2+E3OOekKAES6VGcFGRDxOwz1K0gM2nvhDFmU1VWrVJlzZh5DfCOd43E8PYNNyVurO3uujO
 tGRvK8RLE4viN++ffcR1eYtL3Rtf1ASYhsHB6AAAA
X-Change-ID: 20261104-io-uring-wait-inflight-5ff78a7c6cd5
To: Jens Axboe <axboe@kernel.dk>
Cc: io-uring@vger.kernel.org, linux-kernel@vger.kernel.org, 
 orkunsari <sariorkunemin@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793793378; l=2611;
 i=sariorkunemin@gmail.com; s=20261103; h=from:subject:message-id;
 bh=rQjol/LPkMVu62dXGlOPXlCfjI+XemuiRWZSMmo7src=;
 b=5PjPbkizTDH9QC18dQaOuU/zlDs99/qdedC5HPYSwnnn7xu5G0a0zJmuwde5JUJ/9WSp+JOMi
 H7Iswq6AR7bCSTo9tfyNAm8ivkZoyQEd7DNKmcATRsB2PLu7LezQyMy
X-Developer-Key: i=sariorkunemin@gmail.com; a=ed25519;
 pk=MJ3Y3somkGDQVAXOSR189QAqWOcfzYCRkL1cSQgJXnE=
X-Endpoint-Received: by B4 Relay for sariorkunemin@gmail.com/20261103 with auth_id=1408
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 13d3783a55b7 ("io_uring: wait for in-flight requests on
ring release"), the task dropping the last reference to a ring file
waits in io_ring_ctx_wait_inflight() until every request on the ring
has completed, and only a fatal signal ends the wait early.  The
requests may belong to other tasks and may not complete for an
unbounded time, e.g. a read on a FUSE file whose server never replies.
A process that merely received the ring fd over a UNIX socket and
closes it then blocks in close(2) for as long as those requests stay
in flight.

The comment in io_ring_ctx_wait_and_kill() states that the wait is
meant for requests owned by the task closing the ring.  Only tasks that
created or submitted to a ring have a node for it in their
io_uring_task, so skip the wait for any other task and leave the
remaining requests to io_ring_exit_work() as before.

A thread of the same process that never attached to the ring no longer
waits either when it drops the last reference.  A task that is attached
can still be held up by requests submitted by other tasks; that case
is not addressed here.

This was found by AI-assisted code review (Claude Code).  The fix has
been build-tested with W=1 only; no reproducer was run.

Fixes: 13d3783a55b7 ("io_uring: wait for in-flight requests on ring release")
Signed-off-by: orkunsari <sariorkunemin@gmail.com>
---
Regression in v7.4-rc1 only; released kernels are not affected.
---
 io_uring/io_uring.c | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/io_uring/io_uring.c b/io_uring/io_uring.c
index 03724419c4..04e3da5de0 100644
--- a/io_uring/io_uring.c
+++ b/io_uring/io_uring.c
@@ -2547,7 +2547,16 @@ static __cold void io_ring_ctx_wait_inflight(struct io_ring_ctx *ctx)
 
 	if (current->flags & (PF_KTHREAD | PF_EXITING))
 		return;
-	if (tctx && atomic_read(&tctx->in_cancel))
+	/*
+	 * Tasks that have attached to this ring (created it, submitted to it,
+	 * registered its fd, ...) have a node for it in their io_uring_task.
+	 * A task without one owns no requests here, e.g. one that received
+	 * the fd over a socket, and must not be made to wait for requests it
+	 * has no control over.
+	 */
+	if (!tctx || !xa_load(&tctx->xa, (unsigned long)ctx))
+		return;
+	if (atomic_read(&tctx->in_cancel))
 		return;
 
 	while (io_ring_ctx_inflight(ctx) && !fatal_signal_pending(current)) {

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261104-io-uring-wait-inflight-5ff78a7c6cd5

Best regards,
--  
orkunsari <sariorkunemin@gmail.com>

