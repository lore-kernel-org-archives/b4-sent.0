From: Daan De Meyer <daan@amutable.com>
Date: Tue, 27 Oct 2026 16:09:37 +0100
Subject: [PATCH] io_uring/net: don't retry a non-blocking connect() that
 fails with -EAGAIN
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-b4-io-uring-connect-eagain-v1-1-f4e3aaaa49ee@amutable.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWM0QrCMAxFf2Xk2cBW5gR/RXxIurSLYCrtJsLYv
 9vq47ncc3YoklUKXLsdsry1aLIKw6kDv5BFQZ0rg+vdNPTugjyiJtyyWkSfzMSvKBRJDQP7QOf
 RzRMz1MArS9DPL367/7ls/KhGK7YHUxHkTOaXNj2prJLhOL5nW049lwAAAA==
X-Change-ID: 20261027-b4-io-uring-connect-eagain-fbcfa542d6bb
To: Jens Axboe <axboe@kernel.dk>
Cc: io-uring@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daan De Meyer <daan@amutable.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793113782; l=3987;
 i=daan@amutable.com; s=20260712; h=from:subject:message-id;
 bh=+tauznRyjDSoB6VE5cwuu1Dh5SUyiGcquSpMY3vzX90=;
 b=O2A7vNtxGH0EWkqALMv8O4Sv9NliAsDagjJyoowFY10nYi/HctgeLO+1ApQxMlHxsynvoA0yQ
 kalUT4sTNNaCEptdetIsUxCt5zz8YXfd1LbRBD13NdoR1//wTf4s6Hf
X-Developer-Key: i=daan@amutable.com; a=ed25519;
 pk=I1l+WwrtmzRgofA5SQ1wTuJi18fjh91w+f5uRkFeZEA=
X-Endpoint-Received: by B4 Relay for daan@amutable.com/20260712 with auth_id=868
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IORING_OP_CONNECT on an O_NONBLOCK AF_UNIX stream socket retries a
connect that fails with -EAGAIN because the listener's backlog is full.
Polling the client socket doesn't help: an unconnected stream socket
reports EPOLLOUT and EPOLLHUP right away, before the backlog drains. So
io_uring retries the connect until the apoll retry limit is hit, then
punts the request to io-wq. With a full backlog, io_connect() runs 128
times in the submitting task and once more in a new io-wq worker. That
worker stays in the task's thread group, so a later
unshare(CLONE_NEWUSER) fails with -EINVAL.

None of this changes the result. __sys_connect_file() adds the socket's
own O_NONBLOCK to every attempt, so the attempt from io-wq fails with
-EAGAIN as well. That -EAGAIN becomes the CQE result, and connect(2)
returns the same -EAGAIN.

Let's complete the request with -EAGAIN right away when the socket has
O_NONBLOCK set, like connect(2) does. io_accept() already completes
-EAGAIN this way for IORING_ACCEPT_DONTWAIT. -EINPROGRESS still waits
for the connection to complete. A blocking socket still ends up in
io-wq, where the connect sleeps until the listener accepts.

Fixes: f8e85cf255ad ("io_uring: add support for IORING_OP_CONNECT")
Signed-off-by: Daan De Meyer <daan@amutable.com>
---
io_connect() calls per task with a full AF_UNIX backlog, counted with a
kprobe on io_connect():

                                  before          after
  SOCK_NONBLOCK, full backlog     128 + 1 io-wq   1, no io-wq worker
  blocking, full backlog          128 + 1 io-wq   128 + 1 io-wq
  SOCK_NONBLOCK TCP, SYN dropped  2               2

The CQE results don't change: -EAGAIN for the non-blocking AF_UNIX
socket, and 0 for the other two cases once accept() makes room.

I left the blocking case alone. The poll doesn't help there either, but
io_queue_async() always tries io_arm_poll_handler() for a pollable file,
so an issue handler can't ask for io-wq directly. Setting
REQ_F_FORCE_ASYNC in io_connect() on -EAGAIN for a blocking socket works:
the poll is ready at arm time, and io_req_task_submit() then punts the
request to io-wq. In a test build that cut the blocking case to 1 + 2
calls, and the tests below passed. Every other user sets that flag at
prep time, though, so I can send it as a follow-up if that's acceptable.

Besides AF_UNIX stream and seqpacket sockets, AF_IUCV is the only family
that returns -EAGAIN for a non-blocking connect. Its poll reports
EPOLLOUT before the connection exists, so the retries don't help there
either.

A liburing regression test, test/connect-backlog.c, will be sent
separately. It covers the non-blocking and blocking AF_UNIX cases and a
non-blocking TCP connect that gets -EINPROGRESS, on normal, SQPOLL and
DEFER_TASKRUN rings. The liburing connect, connect-rep, socket* and
accept* tests pass with and without this patch.
---
 io_uring/net.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/io_uring/net.c b/io_uring/net.c
index eeab88e77fd8..1ba3cc0f171d 100644
--- a/io_uring/net.c
+++ b/io_uring/net.c
@@ -1877,6 +1877,17 @@ int io_connect(struct io_kiocb *req, unsigned int issue_flags)
 			if (connect->seen_econnaborted)
 				goto out;
 			connect->seen_econnaborted = true;
+		} else if (req->file->f_flags & O_NONBLOCK) {
+			/*
+			 * __sys_connect_file() adds O_NONBLOCK from the socket
+			 * to every attempt, so a retry from io-wq fails with
+			 * -EAGAIN as well. A poll on the socket doesn't wait
+			 * until a retry can succeed. For example, an AF_UNIX
+			 * client reports EPOLLOUT right away while the
+			 * listener's backlog is full. Complete the request
+			 * with -EAGAIN, like connect(2) does.
+			 */
+			goto out;
 		}
 		return -EAGAIN;
 	}

---
base-commit: d135ab453a7400a34930bdda1ef4bdc8acfac80e
change-id: 20261027-b4-io-uring-connect-eagain-fbcfa542d6bb

Best regards,
--  
Daan De Meyer <daan@amutable.com>

