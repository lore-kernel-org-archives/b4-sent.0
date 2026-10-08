From: Eugene Gvozdetsky <gvozdet@gmail.com>
Date: Fri, 09 Oct 2026 01:08:49 +0200
Subject: [PATCH] io_uring/register: don't exempt disabled rings from task
 restrictions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-iouring-task-restrict-fix-v1-1-a49daf55a12c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMUQ6CMBCE4auQfXaTtoqiVyE+YB1wNSlmtxASw
 t2t+vhNMv9KBhUYXaqVFLOYjKnA7yqKjy4NYLkXU3Dh6J07s4yTSho4d/ZihWWVmLmXhVH3h+b
 U7IOvQeX/VpT5126vf9t0eyLmb5C27QMRcAbhfQAAAA==
X-Change-ID: 20261009-iouring-task-restrict-fix-e5f48783215e
To: io-uring@vger.kernel.org
Cc: axboe@kernel.dk
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791500966; l=3821;
 i=gvozdet@gmail.com; s=20261008; h=from:subject:message-id;
 bh=cdFQ4UtQGKX6YaASaL+SIz6nnuzTFRGO0iWleVHzN10=;
 b=Lkm1NEveYfQCHaq4n8lZj9IHrtIsrazlCwZd3ItDz4VVg8rh7WmjPV9po/fc3IBtpkfnVBssI
 sDffB9qYal1DLqBnu/K3cyRHAutS9qMVnjD0waQbBwB0FrHsRnQUF8V
X-Developer-Key: i=gvozdet@gmail.com; a=ed25519;
 pk=uTBwpnHhIeOy5EodeIOQfzaWk1OTDqMQTa4YeyIO4ms=
X-Endpoint-Received: by B4 Relay for gvozdet@gmail.com/20261008 with auth_id=1138
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A ring created with IORING_SETUP_R_DISABLED is exempt from its register
restrictions until it is enabled. This lets the creator register the
restrictions and then enable the ring with IORING_REGISTER_ENABLE_RINGS,
whether or not that opcode is in the allowed set.

Since commit ed82f35b926b ("io_uring: allow registration of per-task
restrictions"), a ring also inherits restrictions from the task that
creates it, and the same exemption applies to those. A task whose
register opcodes are restricted can therefore create a disabled ring,
issue any register opcode on it, and then enable it.

Mark rings whose restrictions were inherited from the task, and keep
checking register opcodes for them while the ring is disabled. Enabling
such a ring now requires IORING_REGISTER_ENABLE_RINGS to be in the
task's allowed set. Per-ring restrictions registered on a disabled ring
work as before.

Fixes: ed82f35b926b ("io_uring: allow registration of per-task restrictions")
Cc: stable@vger.kernel.org
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Eugene Gvozdetsky <gvozdet@gmail.com>
---
Tested on v7.3-rc6 in a VM with a test that sets task restrictions
and checks register ops on normal and IORING_SETUP_R_DISABLED rings.
Without the patch, a disabled ring allows any register op. With it,
the task's register restrictions also apply while the ring is
disabled. Per-ring restrictions set on a disabled ring still work
(IORING_REGISTER_RESTRICTIONS followed by IORING_REGISTER_ENABLE_RINGS).
Applies cleanly to for-next.
---
 include/linux/io_uring_types.h | 2 ++
 io_uring/io_uring.c            | 1 +
 io_uring/register.c            | 9 ++++++++-
 3 files changed, 11 insertions(+), 1 deletion(-)

diff --git a/include/linux/io_uring_types.h b/include/linux/io_uring_types.h
index 39629ee77..8126af652 100644
--- a/include/linux/io_uring_types.h
+++ b/include/linux/io_uring_types.h
@@ -322,6 +322,8 @@ enum {
 	IO_RING_F_DRAIN_DISABLED	= BIT(10),
 	IO_RING_F_COMPAT		= BIT(11),
 	IO_RING_F_IOWQ_LIMITS_SET	= BIT(12),
+	/* restrictions were inherited from the task that created the ring */
+	IO_RING_F_RESTRICT_INHERITED	= BIT(13),
 };
 
 struct iou_ctx {};
diff --git a/io_uring/io_uring.c b/io_uring/io_uring.c
index cbea989c5..662475a05 100644
--- a/io_uring/io_uring.c
+++ b/io_uring/io_uring.c
@@ -2955,6 +2955,7 @@ static void io_ctx_restriction_clone(struct io_ring_ctx *ctx,
 	struct io_restriction *dst = &ctx->restrictions;
 
 	io_restriction_clone(dst, src);
+	ctx->int_flags |= IO_RING_F_RESTRICT_INHERITED;
 	if (dst->bpf_filters)
 		WRITE_ONCE(ctx->bpf_filters, dst->bpf_filters->filters);
 	if (dst->op_registered)
diff --git a/io_uring/register.c b/io_uring/register.c
index 02bc103bc..d0da8f043 100644
--- a/io_uring/register.c
+++ b/io_uring/register.c
@@ -764,7 +764,14 @@ static int __io_uring_register(struct io_ring_ctx *ctx, unsigned opcode,
 	if (ctx->submitter_task && ctx->submitter_task != current)
 		return -EEXIST;
 
-	if ((ctx->int_flags & IO_RING_F_REG_RESTRICTED) && !(ctx->flags & IORING_SETUP_R_DISABLED)) {
+	/*
+	 * A disabled ring is exempt from its own register restrictions, so
+	 * that the creator can set them up and then enable the ring. That
+	 * does not apply to restrictions inherited from the task.
+	 */
+	if ((ctx->int_flags & IO_RING_F_REG_RESTRICTED) &&
+	    (!(ctx->flags & IORING_SETUP_R_DISABLED) ||
+	     (ctx->int_flags & IO_RING_F_RESTRICT_INHERITED))) {
 		opcode = array_index_nospec(opcode, IORING_REGISTER_LAST);
 		if (!test_bit(opcode, ctx->restrictions.register_op))
 			return -EACCES;

---
base-commit: 6c377d19d4a5116d9bec5203aa3c6c11523e7898
change-id: 20261009-iouring-task-restrict-fix-e5f48783215e

Best regards,
--  
Eugene Gvozdetsky <gvozdet@gmail.com>

