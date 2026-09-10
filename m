From: Quanye Yang <quanyeyang@proton.me>
Date: Thu, 10 Sep 2026 20:23:33 +0800
Subject: [PATCH mptcp-net 1/2] mptcp: reset msk state on early connect
 failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260910-mptcp-connect-undo-net-v1-1-446e4a4ae3e7@proton.me>
References: <20260910-mptcp-connect-undo-net-v1-0-446e4a4ae3e7@proton.me>
In-Reply-To: <20260910-mptcp-connect-undo-net-v1-0-446e4a4ae3e7@proton.me>
To: mptcp@lists.linux.dev
Cc: 
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789043021; l=2066;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=vjSZbBARSjNtpftevI+lTUhTZMMym6vvPVQ1xF8WwG0=;
 b=mAJthT8d2QlMsuYYE1D0kHdtVaNQnAGhiqReRtXoDvCEGljBB1ABTCSd8ydYUp6lw4VcSCD7Y
 zmfWp9CQu0OCg10Iy44VcqLpbGyS/4BegyGeI+o1N5EcDaTxe5YgHCI
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mptcp_connect() can fall back before the subflow SYN is sent, for
example when the netns is in an MPTCP blackhole, token allocation
fails, or MD5SIG is in use. If the subsequent subflow connect()
fails immediately (EAFNOSUPPORT, ENETUNREACH, ...),
__inet_stream_connect() returns while the socket is still
SS_UNCONNECTED and never calls ->disconnect().

The error path only dropped the token and moved the msk back to
TCP_CLOSE. MPTCP_FALLBACK_DONE, allow_subflows and
request_mptcp were left as after early fallback, so a later
connect() on the same fd stayed TCP-only.

Closes: https://github.com/multipath-tcp/mptcp_net-next/issues/633
Fixes: 0235d075a592 ("mptcp: mark as fallback even early ones")
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
 net/mptcp/protocol.c | 22 +++++++++++++++++++---
 1 file changed, 19 insertions(+), 3 deletions(-)

diff --git a/net/mptcp/protocol.c b/net/mptcp/protocol.c
index e1f08f71cdb1..ad476d29bf3d 100644
--- a/net/mptcp/protocol.c
+++ b/net/mptcp/protocol.c
@@ -4129,6 +4129,24 @@ static int mptcp_ioctl(struct sock *sk, int cmd, int *karg)
 	return 0;
 }
 
+static void mptcp_connect_undo(struct sock *sk)
+{
+	struct mptcp_sock *msk = mptcp_sk(sk);
+	struct sock *ssk = msk->first;
+
+	mptcp_token_destroy(msk);
+	mptcp_set_state(sk, TCP_CLOSE);
+
+	spin_lock_bh(&msk->fallback_lock);
+	msk->allow_subflows = true;
+	msk->allow_infinite_fallback = true;
+	clear_bit(MPTCP_FALLBACK_DONE, &msk->flags);
+	spin_unlock_bh(&msk->fallback_lock);
+
+	if (ssk)
+		mptcp_subflow_ctx_reset(mptcp_subflow_ctx(ssk));
+}
+
 static int mptcp_connect(struct sock *sk, struct sockaddr_unsized *uaddr,
 			 int addr_len)
 {
@@ -4197,9 +4215,7 @@ static int mptcp_connect(struct sock *sk, struct sockaddr_unsized *uaddr,
 	 * subflow_finish_connect()
 	 */
 	if (unlikely(err)) {
-		/* avoid leaving a dangling token in an unconnected socket */
-		mptcp_token_destroy(msk);
-		mptcp_set_state(sk, TCP_CLOSE);
+		mptcp_connect_undo(sk);
 		return err;
 	}
 

-- 
2.55.0

