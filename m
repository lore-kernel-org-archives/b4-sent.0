From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 14 Nov 2026 20:29:20 -0500
Subject: [PATCH RFC net v4 2/8] net/iucv: do not clear SEND_SHUTDOWN to
 send a control frame
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-b4-disp-fc0634a3-v4-2-f96c506447ce@proton.me>
References: <20261114-b4-disp-fc0634a3-v4-0-f96c506447ce@proton.me>
In-Reply-To: <20261114-b4-disp-fc0634a3-v4-0-f96c506447ce@proton.me>
To: Jakub Kicinski <kuba@kernel.org>, 
 Alexandra Winter <wintera@linux.ibm.com>, Paolo Abeni <pabeni@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, 
 Hidayath Khan <hidayath@linux.ibm.com>, Eric Dumazet <edumazet@kernel.org>
Cc: Thorsten Winkler <twinkler@linux.ibm.com>, 
 Simon Horman <horms@kernel.org>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nagamani PV <nagamani@linux.ibm.com>, 
 linux-s390@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794706158; l=4835;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=B0pcVs5Hy8pGhGv4ssAFevhx+TtT3x9fnZV79eL5Myk=;
 b=kjWnMMaH391XKhaNxRPLC+8ay25iNjrng9/kRN9eRWRQmvStNbnSxI61QVHQ2jaGzFhWNihNZ
 tJl7VnQwKDxCF41/HZEENC7Bm38xDazdmgA/10wNkrzt7hnzS9UmD/V
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

iucv_send_ctrl() allocates with sock_alloc_send_skb(), which fails once
SEND_SHUTDOWN is set, so it clears the bit first and writes a copy of
sk_shutdown back afterwards. recvmsg() calls it for a window update and
the NETDEV_GOING_DOWN notifier for a FIN, both without the socket lock.
On a socket that has shut down sending:

- A shutdown(SHUT_RD) done in between is undone when the copy is
  written back: the call returned 0 and the socket still receives.
- sendmsg() can find SEND_SHUTDOWN clear and send data after the SHT of
  a shutdown(SHUT_WR) that already returned.

Allocate the control frame with sock_wmalloc() behind the test of
sk_sndbuf that sock_alloc_send_skb() makes, and leave sk_shutdown alone.

Fixes: 4e0ad3221691 ("Subject: [PATCH] af_iucv: enable control sends in case of SEND_SHUTDOWN")
Cc: stable@vger.kernel.org # 6.18.x
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
New in v4. iucv_send_ctrl() clearing SEND_SHUTDOWN is what the AI
review of v3 3/7 is about ([4] in the cover letter), what the notes of
v3 2/7 and 7/7 left open, and where my copy of Hidayath's sk_shutdown
test loses its bit. v2 rewrote the function and v3 dropped that on
Alexandra's review. This is only the part about sk_shutdown; the
allocation that ignores sk_sndbuf for a FIN and the first SHT stays out
(cover letter, "Not in v4"). It goes ahead of 3/8 and 4/8: the test 3/8
adds and the wait 4/8 moves out of the socket lock both rely on the bit
staying set.

The first item, in the emulated setup: a task reads on a socket shut
down for sending, with SO_MSGLIMIT 2 so that nearly every read sends a
window update, and another calls shutdown(SHUT_RD). Over four runs of
200 cycles poll() then shows no EPOLLRDHUP in 12 to 57 cycles of a run
on net and with 1/8, and in none from this patch on.

The wake-up the AI review describes is the one for the memory wait of
4/8, and missing it takes two waits that overlap, so a test kernel on
top of the series has them: the writer sleeps 1000 ms between releasing
the socket and its wait for send memory, a window update waits 1500 ms
in iucv_send_ctrl() ahead of its allocation, and the sk_state_change()
that recvmsg() calls when its window update finds no room is taken out,
as it would wake the writer. A writer blocks with the send memory full
and SO_SNDTIMEO 8 s, shutdown(SHUT_WR) follows at 200 ms, and at 300 ms
a recv() that owes a window update. The writer returns -EPIPE after
1803 ms, when the reader lets go of the socket lock. With the clear and
the restore put back around that delay it sleeps until its timeout,
9193 ms. Without the reader the writer returns on both kernels when the
1000 ms are over.

By inspection:
- the second item of the message
- poll() on a socket shut down both ways reported no EPOLLHUP while
  the bit was clear
- sock_alloc_send_skb() also returned and cleared a pending sk_err,
  which af_iucv sets only at the end of close(), after its FIN
- SOCK_NOSPACE is no longer set; SOCKWQ_ASYNC_NOSPACE still is, for a
  socket with O_ASYNC
- I have no KCSAN build: of Hidayath's reports on net-next, the 6
  between afiucv_hs_rcv() and iucv_send_ctrl() and the 2 between
  iucv_send_ctrl() and iucv_sock_shutdown() are on these writes
---
 net/iucv/af_iucv.c | 27 +++++++++++++--------------
 1 file changed, 13 insertions(+), 14 deletions(-)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index daed2a3cfd66..92468293f7c1 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -401,26 +401,25 @@ static void iucv_sever_path(struct sock *sk, int with_user_data)
 static int iucv_send_ctrl(struct sock *sk, u8 flags)
 {
 	struct iucv_sock *iucv = iucv_sk(sk);
-	int err = 0;
 	int blen;
 	struct sk_buff *skb;
-	u8 shutdown = 0;
 
 	blen = sizeof(struct af_iucv_trans_hdr) +
 	       LL_RESERVED_SPACE(iucv->hs_dev);
-	if (sk->sk_shutdown & SEND_SHUTDOWN) {
-		/* controlling flags should be sent anyway */
-		shutdown = sk->sk_shutdown;
-		sk->sk_shutdown &= RCV_SHUTDOWN;
-	}
-	skb = sock_alloc_send_skb(sk, blen, 1, &err);
-	if (skb) {
-		skb_reserve(skb, blen);
-		err = afiucv_hs_send(NULL, sk, skb, flags);
+	/* Control frames go out after a shutdown too, so this is not
+	 * sock_alloc_send_skb(), which fails on SEND_SHUTDOWN. sk_shutdown is
+	 * left alone: it is read without the socket lock, and not every
+	 * caller here holds it.
+	 */
+	if (sk_wmem_alloc_get(sk) >= READ_ONCE(sk->sk_sndbuf)) {
+		sk_set_bit(SOCKWQ_ASYNC_NOSPACE, sk);
+		return -EAGAIN;
 	}
-	if (shutdown)
-		sk->sk_shutdown = shutdown;
-	return err;
+	skb = sock_wmalloc(sk, blen, 1, sk->sk_allocation);
+	if (!skb)
+		return -ENOBUFS;
+	skb_reserve(skb, blen);
+	return afiucv_hs_send(NULL, sk, skb, flags);
 }
 
 /**

-- 
2.56.0

