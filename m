From: Mark Amirkan <markdamirkan@gmail.com>
Date: Sun, 13 Sep 2026 10:30:05 +0000
Subject: [PATCH net] mptcp: return sk_wait_data() errors from recvmsg()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260913-b4-send-mptcp-recv-error-v1-1-4eaa3684a8b8@gmail.com>
X-B4-Tracking: v=1; b=H4sIAC17pmoC/yWMwQ6CMBAFf4Xs2U0KqAF/xXCQ5VXXxNJsKyEh/
 LtVjzPJzEYJpkh0qTYyLJp0DgXqQ0XyuIU7WKfC1Ljm7Pq65fHICWHiV8wS2SALw2w2hne+6zu
 4kwiVPBq8rr/1lQIyDX+Z3uMTkr9T2vcPxYYZLIEAAAA=
X-Change-ID: 20260913-b4-send-mptcp-recv-error-ef0f898e05cc
To: Matthieu Baerts <matttbe@kernel.org>, 
 Mat Martineau <martineau@kernel.org>, mptcp@lists.linux.dev
Cc: Jakub Kicinski <kuba@kernel.org>, Geliang Tang <geliang@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Simon Horman <horms@kernel.org>, 
 linux-kernel@vger.kernel.org, Paolo Abeni <pabeni@redhat.com>, 
 netdev@vger.kernel.org, Eric Dumazet <edumazet@google.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789295423; l=1552;
 i=markdamirkan@gmail.com; s=pscsi-20260818; h=from:subject:message-id;
 bh=nFns6QPwNtc6ZlWxL0DfCPRqrLoyi61MO8NmnrCReZ0=;
 b=zUnCB4O2oj2YTonWyuK6Qcw/TnT5pXlznkPJPKBbwLfP6dmUgoy5JYhplV6fjLQ/c/NfTunoJ
 yPRzcwrZ8Q8A6ln++W+b0owuF5pCAcU12geosagpf0liSbGaRVjlZH4
X-Developer-Key: i=markdamirkan@gmail.com; a=ed25519;
 pk=/wb49ibt4gZFDncmhFQBYtjPvzT1tfJtvK4Mqt1P2Wc=
X-Endpoint-Received: by B4 Relay for markdamirkan@gmail.com/pscsi-20260818 with auth_id=961
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 581302298524 ("mptcp: error out earlier on disconnect") made
mptcp_recvmsg() stop when sk_wait_data() returns an error.  The error is
stored in err, but the function then jumps to a path which returns
copied.  When no data was copied, recvmsg() therefore returns zero and
reports a false EOF.

Store the result in copied, which is the value returned by the function.
This also keeps the usual partial-read result when data was copied before
the error.

A recvmsg() blocked in one thread reproduces the issue when another
thread disconnects the same MPTCP socket with connect(AF_UNSPEC).
Before this change recvmsg() returns zero; afterwards it returns -EPIPE.

Fixes: 581302298524 ("mptcp: error out earlier on disconnect")
Cc: stable@vger.kernel.org
Assisted-by: Symbolic
Signed-off-by: Mark Amirkan <markdamirkan@gmail.com>
---
 net/mptcp/protocol.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/net/mptcp/protocol.c b/net/mptcp/protocol.c
index 0098e28309..8dc25ef154 100644
--- a/net/mptcp/protocol.c
+++ b/net/mptcp/protocol.c
@@ -2459,7 +2459,7 @@ static int mptcp_recvmsg(struct sock *sk, struct msghdr *msg, size_t len,
 		mptcp_cleanup_rbuf(msk, copied);
 		err = sk_wait_data(sk, &timeo, last);
 		if (err < 0) {
-			err = copied ? : err;
+			copied = copied ? : err;
 			goto out_err;
 		}
 	}

---
base-commit: 78445023439506ebd83b86d40b1e428a3b309d4a
change-id: 20260913-b4-send-mptcp-recv-error-ef0f898e05cc

Best regards,
--  
Mark Amirkan <markdamirkan@gmail.com>

