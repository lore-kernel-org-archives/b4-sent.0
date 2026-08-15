From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 15 Aug 2026 11:04:46 -0500
Subject: [PATCH net 2/2] net/iucv: send the window update outside
 message_q.lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260815-b4-disp-8a791503-v1-2-fbae9a511144@proton.me>
References: <20260815-b4-disp-8a791503-v1-0-fbae9a511144@proton.me>
In-Reply-To: <20260815-b4-disp-8a791503-v1-0-fbae9a511144@proton.me>
To: Paolo Abeni <pabeni@redhat.com>, Jakub Kicinski <kuba@kernel.org>, 
 Thorsten Winkler <twinkler@linux.ibm.com>, 
 Alexandra Winter <wintera@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>
Cc: netdev@vger.kernel.org, Ursula Braun <ursula.braun@de.ibm.com>, 
 linux-s390@vger.kernel.org, Hidayath Khan <hidayath@linux.ibm.com>, 
 Simon Horman <horms@kernel.org>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786809884; l=2272;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=L56L5SgoTNqaUSYL7t66jKwxwKt6Vsm3YTGtl+pA+g8=;
 b=c62iVuhmkLGiW0Ajgwi+6seVbKKOqFeHWRq9Hi5CLUk24XWvph6FVli+LN/G5GceIiFkDRMeY
 hrnL1M9eNzDD8iGbpo07XckKbaxcczLtchTLMS6U674yA9J9hQEcxi4
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

iucv_sock_recvmsg() calls iucv_send_ctrl() with message_q.lock held, and
iucv_send_ctrl() allocates through sock_alloc_send_skb() with
sk->sk_allocation -- GFP_KERNEL here -- so the allocation may sleep inside
the spin_lock_bh() section; noblock suppresses only the wait for send
buffer space, not the allocation flags. The section's other allocation,
alloc_iucv_recv_skb() under iucv_process_message_q(), uses GFP_ATOMIC.

Note that the update is due and send it after the lock is dropped. The
lock protects backlog_skb_q and message_q.list, neither of which the send
touches. It does widen an existing msg_recv race -- afiucv_hs_send() reads
the counter and subtracts it later, and recvmsg holds no socket lock, so
two recvmsg can now interleave where before only recvmsg and sendmsg
could. Both trip the same WARN_ON.

Fixes: 3881ac441f64 ("af_iucv: add HiperSockets transport")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/iucv/af_iucv.c | 19 +++++++++++--------
 1 file changed, 11 insertions(+), 8 deletions(-)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index 0bc4a15f4b56..e31ef3a87ec5 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -1241,6 +1241,7 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 	struct iucv_sock *iucv = iucv_sk(sk);
 	unsigned int copied, rlen;
 	struct sk_buff *skb, *rskb, *cskb;
+	bool send_win = false;
 	int err = 0;
 	u32 offset;
 
@@ -1332,16 +1333,18 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 			if (!list_empty(&iucv->message_q.list))
 				iucv_process_message_q(sk);
 			if (iucv->transport == AF_IUCV_TRANS_HIPER &&
-			    atomic_read(&iucv->msg_recv) >=
-							iucv->msglimit / 2) {
-				err = iucv_send_ctrl(sk, AF_IUCV_FLAG_WIN);
-				if (err) {
-					sk->sk_state = IUCV_DISCONN;
-					sk->sk_state_change(sk);
-				}
-			}
+			    atomic_read(&iucv->msg_recv) >= iucv->msglimit / 2)
+				send_win = true;
 		}
 		spin_unlock_bh(&iucv->message_q.lock);
+
+		if (send_win) {
+			err = iucv_send_ctrl(sk, AF_IUCV_FLAG_WIN);
+			if (err) {
+				sk->sk_state = IUCV_DISCONN;
+				sk->sk_state_change(sk);
+			}
+		}
 	}
 
 done:

-- 
2.55.0

