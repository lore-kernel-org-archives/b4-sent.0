From: Quanye Yang <quanyeyang@proton.me>
Date: Sat, 17 Oct 2026 05:46:42 -0700
Subject: [PATCH mptcp-net] mptcp: push pending data after a sendmsg copy
 fault
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-fix-mptcp-issue-640-v1-1-50a7bace7d43@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQqDMBBFryKz7kBiQyxeRbpoxtFOoTFkYimId
 2+sy8d//22gnIUV+maDzB9RWWIFe2mAno84M8pYGVrTemtsh5N88Z0KJRTVldE7g+S6QObmwnj
 1UJ8pc9X+1QFOOXKB+znpGl5M5ajCvv8Adh4uCoIAAAA=
X-Change-ID: 20261017-fix-mptcp-issue-640-c47bc084bd36
To: MPTCP Linux <mptcp@lists.linux.dev>
Cc: 
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792241204; l=1554;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=BZQcEIK5odqd77DaV+ORXYQi6bbhxS0Ut7pU2pUkSKc=;
 b=oP9E23Yodx6pUoAr1SMzz0UTCMaPLOW2RbNUoes/eMQ4Kg4hXbeANUEUg6nv1ANnCjY/PI7Nk
 Gm7boeGsBwwA+0y1QRIjRDexW3ODk5wcxgmE9zsDIbzssoHClN+Ci0l
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mptcp_sendmsg() copies into the msk write queue first, then
__mptcp_push_pending() on the success path. tcp_sendmsg_locked()
does the opposite: its do_error path jumps to out, and out
calls tcp_push() when copied > 0.

A later iovec fault (copy_from_iter / -EFAULT) after a successful
iteration therefore returns the partial byte count but leaves the
already-queued dfrag on rtx_queue. No subflow packet is sent, no
retransmission timer is armed, and DATA_FIN stays blocked on
first_pending.

Push in do_error when copied is already non-zero. Do not move
the push to out: copied is a size_t, and sk_stream_error()
stores a negative errno there.

Fixes: 69800e516e96 ("mptcp: propagate fastclose error")
Closes: https://github.com/multipath-tcp/mptcp_net-next/issues/640
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
 net/mptcp/protocol.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/net/mptcp/protocol.c b/net/mptcp/protocol.c
index 05c38564e8fd..f72e0e3d2619 100644
--- a/net/mptcp/protocol.c
+++ b/net/mptcp/protocol.c
@@ -2129,8 +2129,10 @@ static int mptcp_sendmsg(struct sock *sk, struct msghdr *msg, size_t len)
 	return copied;
 
 do_error:
-	if (copied)
+	if (copied) {
+		__mptcp_push_pending(sk, msg->msg_flags);
 		goto out;
+	}
 
 	copied = sk_stream_error(sk, msg->msg_flags, ret);
 	goto out;

---
base-commit: a22035be824449c4921ec406f6383089016a628c
change-id: 20261017-fix-mptcp-issue-640-c47bc084bd36

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

