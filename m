From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 28 Aug 2026 14:07:47 -0500
Subject: [PATCH net v3] net/iucv: fix the recvmsg window update
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260828-b4-disp-33fac0ed-v3-1-e6d061880ee0@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQrCMBAFf6W8swtpYjX6K8VDmmx0PcSSrSKU/
 rtRjzMws0K5CivO3YrKL1F5lAZu1yHeQrkySWoMa+zBeOtp2lMSncm5HKLhRNkd49Cf/JBCj5b
 NlbO8f8sRhRdc/lKf053j8p1h2z6KVXkVeQAAAA==
X-Change-ID: 20260828-b4-disp-33fac0ed-f37c51985da1
To: Alexandra Winter <wintera@linux.ibm.com>, 
 Paolo Abeni <pabeni@redhat.com>, Jakub Kicinski <kuba@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, 
 Thorsten Winkler <twinkler@linux.ibm.com>, 
 Eric Dumazet <edumazet@google.com>
Cc: Aswin Karuvally <aswin@linux.ibm.com>, netdev@vger.kernel.org, 
 Simon Horman <horms@kernel.org>, linux-s390@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hidayath Khan <hidayath@linux.ibm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787944066; l=5446;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=ck8H8yZfyBarvnWPyo7vTYMZxtw0v0L/GSa+8TIy3Rg=;
 b=g3wex2M0rFIWtV9Q/CsSIBlRtDgsxLWetJE+fWFHvyTSzR0EeLERD5bhOJCpIlJTevdGKsVcp
 K8S4uWqorLKCKp5n6XUi0nfuRFj+VevgtvzxJRJ5NQKX4gLk3LT9DTy
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

iucv_sock_recvmsg() sends the HiperSockets-only AF_IUCV_FLAG_WIN without
testing the transport, so on a classic z/VM socket iucv_send_ctrl() sizes
the skb through a NULL iucv->hs_dev. SO_MSGLIMIT accepts 1, so msglimit / 2
is zero and one recvmsg() on its own socket is enough for an unprivileged
process to take a spurious disconnect.

It also calls iucv_send_ctrl() under spin_lock_bh(&message_q.lock), which
allocates GFP_KERNEL inside a section the code treats as atomic. Sending
outside that lock lets two recvmsg() reach afiucv_hs_send() at once, where
msg_recv is sampled for the advertised window and subtracted after
dev_queue_xmit() -- and sendmsg reaches that counter under lock_sock()
while recvmsg holds no socket lock, so both can subtract the same value,
the counter goes negative and the credit reaches the peer twice.

Test the transport, claim the credit with atomic_xchg() after the last
error exit and hand it back if the transmit fails, and send once the lock
is dropped.

Fixes: 3881ac441f64 ("af_iucv: add HiperSockets transport")
Fixes: 238965b71b96 ("net/af_iucv: build proper skbs for HiperTransport")
Cc: stable@vger.kernel.org
Tested-by: Aswin Karuvally <aswin@linux.ibm.com>
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
v3: squashed the three v2 patches into one, as Alexandra Winter asked -- they
    are one subject (iucv->msg_recv handling), they had a stated dependency,
    and one patch is easier to backport. No code change from v2 1-3 combined.

    The v2 1/3 changelog said the NULL read faults under relocate_lowcore.
    That is out: Alexandra booted with it and did not hit a page fault. I have
    no explanation to offer in its place: vmem.c:521-524 skips the first
    sizeof(struct lowcore) bytes from the identity mapping whether or not the
    lowcore was relocated. So the changelog now claims only the disconnect,
    which she reproduced.

    Tested-by carried from v2: the code is identical to v2 1-3 applied in
    order.

v2: https://lore.kernel.org/all/20260821-b4-disp-3a6e8695-v2-0-37597ff723a8@proton.me/
v1: https://lore.kernel.org/all/20260815-b4-disp-8a791503-v1-0-fbae9a511144@proton.me/

Not reproduced here: CONFIG_AFIUCV depends on S390 and I have no Z. The
counter race was checked under LKMM -- the counter reaches -2 before the
atomic_xchg() and cannot after -- and the tree builds clean for s390.
---
 net/iucv/af_iucv.c | 42 +++++++++++++++++++++++++-----------------
 1 file changed, 25 insertions(+), 17 deletions(-)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index 4e5cc9da6e06..db261ecd19af 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -210,12 +210,6 @@ static int afiucv_hs_send(struct iucv_message *imsg, struct sock *sock,
 	phs_hdr->flags = flags;
 	if (flags == AF_IUCV_FLAG_SYN)
 		phs_hdr->window = iucv->msglimit;
-	else if ((flags == AF_IUCV_FLAG_WIN) || !flags) {
-		confirm_recv = atomic_read(&iucv->msg_recv);
-		phs_hdr->window = confirm_recv;
-		if (confirm_recv)
-			phs_hdr->flags = phs_hdr->flags | AF_IUCV_FLAG_WIN;
-	}
 	memcpy(phs_hdr->destUserID, iucv->dst_user_id, 8);
 	memcpy(phs_hdr->destAppName, iucv->dst_name, 8);
 	memcpy(phs_hdr->srcUserID, iucv->src_user_id, 8);
@@ -250,13 +244,22 @@ static int afiucv_hs_send(struct iucv_message *imsg, struct sock *sock,
 	}
 	skb->protocol = cpu_to_be16(ETH_P_AF_IUCV);
 
+	/* Claim the receive credit here, not while building the header: every
+	 * way this frame can be dropped has now been ruled out, so the window
+	 * is zeroed only for as long as the transmit itself takes.
+	 */
+	if (flags == AF_IUCV_FLAG_WIN || !flags) {
+		confirm_recv = atomic_xchg(&iucv->msg_recv, 0);
+		phs_hdr->window = confirm_recv;
+		if (confirm_recv)
+			phs_hdr->flags = phs_hdr->flags | AF_IUCV_FLAG_WIN;
+	}
+
 	atomic_inc(&iucv->skbs_in_xmit);
 	err = dev_queue_xmit(skb);
 	if (net_xmit_eval(err)) {
 		atomic_dec(&iucv->skbs_in_xmit);
-	} else {
-		atomic_sub(confirm_recv, &iucv->msg_recv);
-		WARN_ON(atomic_read(&iucv->msg_recv) < 0);
+		atomic_add(confirm_recv, &iucv->msg_recv);
 	}
 	return net_xmit_eval(err);
 
@@ -1241,6 +1244,7 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 	struct iucv_sock *iucv = iucv_sk(sk);
 	unsigned int copied, rlen;
 	struct sk_buff *skb, *rskb, *cskb;
+	bool send_win = false;
 	int err = 0;
 	u32 offset;
 
@@ -1331,16 +1335,20 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 		if (skb_queue_empty(&iucv->backlog_skb_q)) {
 			if (!list_empty(&iucv->message_q.list))
 				iucv_process_message_q(sk);
-			if (atomic_read(&iucv->msg_recv) >=
-							iucv->msglimit / 2) {
-				err = iucv_send_ctrl(sk, AF_IUCV_FLAG_WIN);
-				if (err) {
-					sk->sk_state = IUCV_DISCONN;
-					sk->sk_state_change(sk);
-				}
-			}
+			if (iucv->transport == AF_IUCV_TRANS_HIPER &&
+			    atomic_read(&iucv->msg_recv) >=
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

---
base-commit: 1b78070aaef63512688aebfbc82365ef9d6660f1
change-id: 20260828-b4-disp-33fac0ed-f37c51985da1

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

