From: Henrik Ma Johansson <dahankzter@gmail.com>
Date: Sun, 27 Sep 2026 11:48:57 +0200
Subject: [PATCH RFC] io_uring: add support for copy_file_range
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260927-cfr-rfc-v1-1-5b9ddbe0490f@gmail.com>
References: <20260927-cfr-rfc-v1-0-5b9ddbe0490f@gmail.com>
In-Reply-To: <20260927-cfr-rfc-v1-0-5b9ddbe0490f@gmail.com>
To: Jens Axboe <axboe@kernel.dk>, io-uring@vger.kernel.org
Cc: Christian Brauner <brauner@kernel.org>, linux-fsdevel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Henrik Ma Johansson <dahankzter@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=5989; i=dahankzter@gmail.com;
 h=from:subject:message-id; bh=Y6Qn2ejRW03ZlzzYwHZEwXGGECb9VUTiKUeZHr12C64=;
 b=kA0DAAoWDPOq2hz2HxMByyZiAGq45ojIJ1Ago3XO71ITlZp47priYq3soRwBsopgd/bXNrMrF
 Yh1BAAWCgAdFiEE0nxFoc4A2G1BZPBgDPOq2hz2HxMFAmq45ogACgkQDPOq2hz2HxMA+AD9HKtC
 EBKpaw9I1OxRog5R5yRt05ZCll14okDK9ncq7xwBALEnPkPzjEKz0e+NFjkLOnBqGgXOGmZBuNT
 LMcCmU90J
X-Developer-Key: i=dahankzter@gmail.com; a=openpgp;
 fpr=D27C45A1CE00D86D4164F0600CF3AADA1CF61F13
X-Endpoint-Received: by B4 Relay for dahankzter@gmail.com/default with auth_id=1067
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

copy_file_range(2) lets the filesystem decide how to copy: XFS, Btrfs and
OCFS2 share extents instead of copying data (reflink), and NFS, CIFS and
Ceph can have the server copy without data crossing the network. Neither
is reachable through io_uring today. IORING_OP_SPLICE requires one end to
be a pipe, so the only io_uring alternative is two linked splices through
a pipe, which always copies bytes.

Add IORING_OP_COPY_FILE_RANGE, eliminating the need for applications to
keep a thread pool or offload mechanism just to issue copy_file_range
without blocking. The SQE is packed like splice: fd_out in fd, off_out in
off, off_in in splice_off_in and fd_in in splice_fd_in, where
SPLICE_F_FD_IN_FIXED selects a registered file. An offset of -1 uses and
advances the file position, like a NULL offset to the syscall. No
copy_file_range flags exist, so splice_flags accepts only
SPLICE_F_FD_IN_FIXED.

There is no nonblocking path for copy_file_range, so the request is
always punted to io-wq, like splice, fallocate and ftruncate. Writes to
the same output file are serialized through hash_reg_file, as for those
ops. As with other data transfer opcodes, auditing is skipped; the
copy_file_range syscall is in no audit class either.

The length is clamped to MAX_RW_COUNT, as the CQE result is 32 bits and
->copy_file_range() and ->remap_file_range() may otherwise return more
than INT_MAX. A short copy is allowed by copy_file_range semantics;
callers loop, as they do for the syscall. As for other transfer
opcodes, a result that doesn't match the (clamped) requested length
fails the request for the purpose of links. A zero length is passed
through, as vfs_copy_file_range() does its checks before returning 0,
so errors match the syscall.

As in the networking opcodes, -ERESTARTSYS is turned into -EINTR, as the
request cannot be restarted like a syscall. NFS returns it when an
in-flight server-side copy is interrupted by cancellation.

Assisted-by: LLM sparse
Signed-off-by: Henrik Ma Johansson <dahankzter@gmail.com>
---
 include/uapi/linux/io_uring.h |  1 +
 io_uring/opdef.c              | 11 ++++++++
 io_uring/splice.c             | 58 +++++++++++++++++++++++++++++++++++++++++++
 io_uring/splice.h             |  3 +++
 4 files changed, 73 insertions(+)

diff --git a/include/uapi/linux/io_uring.h b/include/uapi/linux/io_uring.h
index 909fb7aea638..a6bda05ed1e0 100644
--- a/include/uapi/linux/io_uring.h
+++ b/include/uapi/linux/io_uring.h
@@ -318,6 +318,7 @@ enum io_uring_op {
 	IORING_OP_PIPE,
 	IORING_OP_NOP128,
 	IORING_OP_URING_CMD128,
+	IORING_OP_COPY_FILE_RANGE,
 
 	/* this goes last, obviously */
 	IORING_OP_LAST,
diff --git a/io_uring/opdef.c b/io_uring/opdef.c
index cf3aa2242cd7..2f4c869993b1 100644
--- a/io_uring/opdef.c
+++ b/io_uring/opdef.c
@@ -591,6 +591,13 @@ const struct io_issue_def io_issue_defs[] = {
 		.prep			= io_uring_cmd_prep,
 		.issue			= io_uring_cmd,
 	},
+	[IORING_OP_COPY_FILE_RANGE] = {
+		.needs_file		= 1,
+		.hash_reg_file		= 1,
+		.audit_skip		= 1,
+		.prep			= io_copy_file_range_prep,
+		.issue			= io_copy_file_range,
+	},
 };
 
 const struct io_cold_def io_cold_defs[] = {
@@ -849,6 +856,10 @@ const struct io_cold_def io_cold_defs[] = {
 		.sqe_copy		= io_uring_cmd_sqe_copy,
 		.cleanup		= io_uring_cmd_cleanup,
 	},
+	[IORING_OP_COPY_FILE_RANGE] = {
+		.name			= "COPY_FILE_RANGE",
+		.cleanup		= io_splice_cleanup,
+	},
 };
 
 const char *io_uring_get_opcode(u8 opcode)
diff --git a/io_uring/splice.c b/io_uring/splice.c
index e81ebbb91925..740f759a683b 100644
--- a/io_uring/splice.c
+++ b/io_uring/splice.c
@@ -147,3 +147,61 @@ int io_splice(struct io_kiocb *req, unsigned int issue_flags)
 	io_req_set_res(req, ret, 0);
 	return IOU_COMPLETE;
 }
+
+int io_copy_file_range_prep(struct io_kiocb *req, const struct io_uring_sqe *sqe)
+{
+	struct io_splice *sp = io_kiocb_to_cmd(req, struct io_splice);
+
+	if (READ_ONCE(sqe->addr3) || READ_ONCE(sqe->buf_index))
+		return -EINVAL;
+
+	sp->off_in = READ_ONCE(sqe->splice_off_in);
+	sp->off_out = READ_ONCE(sqe->off);
+	sp->len = min_t(u32, READ_ONCE(sqe->len), MAX_RW_COUNT);
+	sp->flags = READ_ONCE(sqe->splice_flags);
+	if (unlikely(sp->flags & ~SPLICE_F_FD_IN_FIXED))
+		return -EINVAL;
+	sp->splice_fd_in = READ_ONCE(sqe->splice_fd_in);
+	sp->rsrc_node = NULL;
+	req->flags |= REQ_F_FORCE_ASYNC;
+	return 0;
+}
+
+int io_copy_file_range(struct io_kiocb *req, unsigned int issue_flags)
+{
+	struct io_splice *sp = io_kiocb_to_cmd(req, struct io_splice);
+	struct file *out = sp->file_out;
+	loff_t pos_in, pos_out;
+	struct file *in;
+	ssize_t ret;
+
+	WARN_ON_ONCE(issue_flags & IO_URING_F_NONBLOCK);
+
+	in = io_splice_get_file(req, issue_flags);
+	if (!in) {
+		ret = -EBADF;
+		goto done;
+	}
+
+	pos_in = (sp->off_in == -1) ? in->f_pos : sp->off_in;
+	pos_out = (sp->off_out == -1) ? out->f_pos : sp->off_out;
+
+	ret = vfs_copy_file_range(in, pos_in, out, pos_out, sp->len, 0);
+	if (ret == -ERESTARTSYS)
+		ret = -EINTR;
+
+	if (ret > 0) {
+		if (sp->off_in == -1)
+			in->f_pos = pos_in + ret;
+		if (sp->off_out == -1)
+			out->f_pos = pos_out + ret;
+	}
+
+	if (!(sp->flags & SPLICE_F_FD_IN_FIXED))
+		fput(in);
+done:
+	if (ret != sp->len)
+		req_set_fail(req);
+	io_req_set_res(req, ret, 0);
+	return IOU_COMPLETE;
+}
diff --git a/io_uring/splice.h b/io_uring/splice.h
index b9b2848327fb..83138fab8fe8 100644
--- a/io_uring/splice.h
+++ b/io_uring/splice.h
@@ -6,3 +6,6 @@ int io_tee(struct io_kiocb *req, unsigned int issue_flags);
 void io_splice_cleanup(struct io_kiocb *req);
 int io_splice_prep(struct io_kiocb *req, const struct io_uring_sqe *sqe);
 int io_splice(struct io_kiocb *req, unsigned int issue_flags);
+
+int io_copy_file_range_prep(struct io_kiocb *req, const struct io_uring_sqe *sqe);
+int io_copy_file_range(struct io_kiocb *req, unsigned int issue_flags);

-- 
2.55.0

