From: Miguel Garcia <miguelgarciaroman8@gmail.com>
Date: Fri, 02 Oct 2026 15:56:57 +0200
Subject: [PATCH] io_uring/rw: commit the ring buffer when a read is queued
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261002-codex-io-uring-eiocbqueued-v1-1-3fb159b33a47@gmail.com>
X-B4-Tracking: v=1; b=H4sIACm4v2oC/x3MQQqDMBAF0KvIrB2IKSr2KsWFmXx1NkmbEBHEu
 ze4fJt3UUZSZHo3FyUcmjWGiq5tSPYlbGD11WSNHTpjLEv0OFkjl6RhY2gU9yso8CzTOPS9e41
 WHNXgm7Dq+eSf+b7/EU0/cGwAAAA=
To: Jens Axboe <axboe@kernel.dk>
Cc: io-uring@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Miguel Garcia <miguelgarciaroman8@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790949423; l=3676;
 i=miguelgarciaroman8@gmail.com; s=default; h=from:subject:message-id;
 bh=v57nh9u23dqRQyIlqtlCgf6++EGJa5Mea4ZnWbGP4a4=;
 b=jQegJ5VAriYKw7EOa0I+F4x5Z+3MQ2xzVA1w5ntmnOMbgxKil73hpDK4c274vKo/SwCav2SRC
 szR3lvcKiPpAQXdCoZgkc5wP2cuS0NtxxhMYULY0N+zDp0mFaROJGDP
X-Developer-Key: i=miguelgarciaroman8@gmail.com; a=ed25519;
 pk=EtrxRdQ/icT1qmJwjNNAVoBUhKKWwrhU2m6QT/xu6bM=
X-Endpoint-Received: by B4 Relay for miguelgarciaroman8@gmail.com/default with auth_id=1101
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

io_read() recycles a provided buffer ring on every negative return
while REQ_F_BUFFERS_COMMIT is set. -EIOCBQUEUED is one of those
returns. IOU_ISSUE_SKIP_COMPLETE is defined as -EIOCBQUEUED, and
io_issue_sqe() turns that into success and leaves the request in
flight. The queued read still writes the user address chosen at
buffer selection.

For a pollable file issued under uring_lock, io_should_commit() is
false, so recycle clears REQ_F_BUFFER_RING and REQ_F_BUFFERS_COMMIT
without moving the ring head. io_req_rw_complete() then skips
io_put_kbuf(). The CQE is posted without IORING_CQE_F_BUFFER, and a
later IOSQE_BUFFER_SELECT takes the same slot while the first read
is still in flight.

FUSE reaches this from a user mount. fuse_file_operations supplies
both .poll and .read_iter. A daemon that negotiates FUSE_ASYNC_DIO,
reports a non-zero size, opens with FOPEN_DIRECT_IO, and answers
FUSE_POLL with -ENOSYS or POLLIN makes io_file_supports_nowait()
succeed. fuse_direct_IO() returns -EIOCBQUEUED for an async kiocb
and keeps the user pages pinned.

Commit the selected length before returning IOU_ISSUE_SKIP_COMPLETE
and leave REQ_F_BUFFER_RING set, so completion still reports the
buffer id. io_req_rw_complete() passes a NULL buffer list, so
dropping the recycle alone leaves the head unchanged. The list
pointer is stack-local, so the issue path has to commit before it
returns. The committed length is rw->len, the same length
io_ring_buffer_select() commits when io_should_commit() is true.
Non-pollable and IO_URING_F_UNLOCKED issues have already cleared
REQ_F_BUFFERS_COMMIT. -EAGAIN still recycles.

Commit d8e1dec2f860 ("io_uring/rw: recycle buffers manually for
non-mshot reads") made io_read() recycle provided buffers on every
negative return, including -EIOCBQUEUED.

Grok, a coding assistant, found this by reading io_read() and
fuse_direct_IO() and drafted the change. Debian gcc 12.2.0 built
io_uring/rw.o and the kernel image. QEMU TCG booted both images.
On the unpatched image two buffered reads shared one address, the
ring head stayed 0, and both CQEs lacked IORING_CQE_F_BUFFER. With
this change the head moved to 1 while the first read was still
queued, that CQE carried the buffer id, and the second read returned
-ENOBUFS.

Fixes: d8e1dec2f860 ("io_uring/rw: recycle buffers manually for non-mshot reads")
Cc: stable@vger.kernel.org # 6.18+
Assisted-by: LLM
Signed-off-by: Miguel Garcia <miguelgarciaroman8@gmail.com>
---
 io_uring/rw.c | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/io_uring/rw.c b/io_uring/rw.c
index 0c9494fd21be..a40263d21afe 100644
--- a/io_uring/rw.c
+++ b/io_uring/rw.c
@@ -1034,6 +1034,21 @@ int io_read(struct io_kiocb *req, unsigned int issue_flags)
 	if (ret >= 0)
 		return kiocb_done(req, ret, &sel, issue_flags);
 
+	/*
+	 * -EIOCBQUEUED leaves the kiocb in flight on the selected user
+	 * address. Commit the ring buffer here. Completion reports the
+	 * id with a NULL list. Error returns still recycle below.
+	 */
+	if (ret == IOU_ISSUE_SKIP_COMPLETE) {
+		if ((req->flags & REQ_F_BUFFERS_COMMIT) && sel.buf_list) {
+			struct io_rw *rw = io_kiocb_to_cmd(req, struct io_rw);
+
+			if (!io_kbuf_commit(req, sel.buf_list, rw->len, 1))
+				req->flags |= REQ_F_BUF_MORE;
+		}
+		return io_fixup_restart_res(ret);
+	}
+
 	if (req->flags & REQ_F_BUFFERS_COMMIT)
 		io_kbuf_recycle(req, sel.buf_list, issue_flags);
 

---
base-commit: 648611ee6ed0d27f8b43b7b5863facc3ec94c31b
change-id: 20261002-codex-io-uring-eiocbqueued-c97655b372cb

Best regards,
-- 
Miguel Garcia <miguelgarciaroman8@gmail.com>

