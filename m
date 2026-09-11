From: Quanye Yang <quanyeyang@proton.me>
Date: Fri, 11 Sep 2026 23:42:07 +0800
Subject: [PATCH mptcp-net v2 1/2] mptcp: reset msk state on early connect
 failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260911-mptcp-connect-undo-net-v2-1-54224cea2238@proton.me>
References: <20260911-mptcp-connect-undo-net-v2-0-54224cea2238@proton.me>
In-Reply-To: <20260911-mptcp-connect-undo-net-v2-0-54224cea2238@proton.me>
To: mptcp@lists.linux.dev
Cc: 
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789141332; l=1608;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=Gb88AGXvEtF1PuBgJ2BG7vao+UDAMuDxJ22yWrqoiy4=;
 b=zeaCexkhDYeOzuZvUNipNnmSRiTtnq2sR3HltMgMaq1XoBpP/uDkO22WPbVHJ9NTktUtm6+03
 69BzlIMHj9ZDmFdgYRLX5ZP/Uw+YLIgfE2Nu66FKcD1lpwkTdQYNoRY
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
 net/mptcp/protocol.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/net/mptcp/protocol.c b/net/mptcp/protocol.c
index e1f08f71cdb1..10817ab03cbb 100644
--- a/net/mptcp/protocol.c
+++ b/net/mptcp/protocol.c
@@ -4197,9 +4197,16 @@ static int mptcp_connect(struct sock *sk, struct sockaddr_unsized *uaddr,
 	 * subflow_finish_connect()
 	 */
 	if (unlikely(err)) {
-		/* avoid leaving a dangling token in an unconnected socket */
 		mptcp_token_destroy(msk);
 		mptcp_set_state(sk, TCP_CLOSE);
+
+		spin_lock_bh(&msk->fallback_lock);
+		msk->allow_subflows = true;
+		msk->allow_infinite_fallback = true;
+		clear_bit(MPTCP_FALLBACK_DONE, &msk->flags);
+		spin_unlock_bh(&msk->fallback_lock);
+
+		mptcp_subflow_ctx_reset(mptcp_subflow_ctx(ssk));
 		return err;
 	}
 

-- 
2.55.0

