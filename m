From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 21 Aug 2026 06:17:33 -0500
Subject: [PATCH net v2 3/3] net/iucv: send the window update outside
 message_q.lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-b4-disp-3a6e8695-v2-3-37597ff723a8@proton.me>
References: <20260821-b4-disp-3a6e8695-v2-0-37597ff723a8@proton.me>
In-Reply-To: <20260821-b4-disp-3a6e8695-v2-0-37597ff723a8@proton.me>
To: Eric Dumazet <edumazet@google.com>, Paolo Abeni <pabeni@redhat.com>, 
 Jakub Kicinski <kuba@kernel.org>, Alexandra Winter <wintera@linux.ibm.com>, 
 Thorsten Winkler <twinkler@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>
Cc: Hidayath Khan <hidayath@linux.ibm.com>, Simon Horman <horms@kernel.org>, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-s390@vger.kernel.org, Ursula Braun <ursula.braun@de.ibm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787311050; l=1987;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=EWiW3Q06PiBKk4QOZ/RVbzwZ2pT/eM2TGSityU6WPw0=;
 b=X9RlmlLOvvGwqBAvQgiE+Xzah8fMZJkCoUV4zOd7BiKwfb1FAPYx0Cv8NLpJpHCUm9vQUIz5C
 eK46Z1Eu3/WBBRLhhNiwGqkWES0Bigm9XjJTKs7Us/2ZuaiSBJITdJW
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

iucv_sock_recvmsg() calls iucv_send_ctrl() with message_q.lock held, and
iucv_send_ctrl() allocates through sock_alloc_send_skb() with
sk->sk_allocation -- GFP_KERNEL here -- so the allocation may sleep inside
the spin_lock_bh() section; noblock suppresses only the wait for send
buffer space, not the allocation flags. CONFIG_DEBUG_ATOMIC_SLEEP reports
it.

Note that the update is due and send it once the lock is dropped. That
leaves two recvmsg() able to reach afiucv_hs_send() concurrently, which
message_q.lock used to prevent; the preceding patch is what makes that
safe, so do not apply this one without it.

Fixes: 3881ac441f64 ("af_iucv: add HiperSockets transport")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/iucv/af_iucv.c | 18 +++++++++++-------
 1 file changed, 11 insertions(+), 7 deletions(-)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index 492a45bb2bba..a7c0f60bb5bf 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -1244,6 +1244,7 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 	struct iucv_sock *iucv = iucv_sk(sk);
 	unsigned int copied, rlen;
 	struct sk_buff *skb, *rskb, *cskb;
+	bool send_win = false;
 	int err = 0;
 	u32 offset;
 
@@ -1336,15 +1337,18 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 				iucv_process_message_q(sk);
 			if (iucv->transport == AF_IUCV_TRANS_HIPER &&
 			    atomic_read(&iucv->msg_recv) >=
-							iucv->msglimit / 2) {
-				err = iucv_send_ctrl(sk, AF_IUCV_FLAG_WIN);
-				if (err) {
-					sk->sk_state = IUCV_DISCONN;
-					sk->sk_state_change(sk);
-				}
-			}
+							iucv->msglimit / 2)
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

