From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 22 Oct 2026 21:48:34 -0500
Subject: [PATCH net 1/2] net/iucv: clear hs_dev before dropping its
 reference
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-b4-disp-b35a9153-v1-1-d74645876195@proton.me>
References: <20261022-b4-disp-b35a9153-v1-0-d74645876195@proton.me>
In-Reply-To: <20261022-b4-disp-b35a9153-v1-0-d74645876195@proton.me>
To: Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Paolo Abeni <pabeni@redhat.com>, 
 Alexandra Winter <wintera@linux.ibm.com>, 
 Thorsten Winkler <twinkler@linux.ibm.com>
Cc: Nagamani PV <nagamani@linux.ibm.com>, netdev@vger.kernel.org, 
 Hidayath Khan <hidayath@linux.ibm.com>, linux-s390@vger.kernel.org, 
 Simon Horman <horms@kernel.org>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792723713; l=6587;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=P+HCe6jSRQ3Dc8YpOmP3IA+B+Jzvut22mF+psyFknnI=;
 b=FIYU02GkQh+Mk/dq1thsKlF0OzyxEs4HhydLLNysGrRzMu32q4niTJeDBLXKV0UlBDVCKfGFF
 4d0JEWJzh/zBhfDeBah966rPJG/LgLh6WFd//HbrUDb0U+iO9Rs7EfZ
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

iucv_sock_close() drops the socket's reference on its HiperSockets
device and only then clears iucv->hs_dev, while afiucv_hs_rcv() compares
that field against the ingress device for every socket in the list,
under iucv_sk_list.lock and not the socket lock. Between the two it
compares a pointer the socket no longer holds; KCSAN reports the plain
read against the plain write. The order dates from 800c5eb7b5eb, the
compare from 80230a18c164. Nothing user-visible is known from it: the
receive path holds the ingress device, so the stale pointer is compared,
never dereferenced.

Clear the pointer first, through a local, then drop the reference, and
mark the lookup's read and the two stores that race with it: the clear
in close and the listener's child's, which is in iucv_sk_list from
iucv_sock_alloc() on. The child now takes its device and
sk_bound_dev_if from the frame the lookup matched, held before it is
published, instead of reading the listener's fields: close() clears
them under lock_sock(), which the bh_lock_sock() in
afiucv_hs_callback_syn() does not exclude, so the callback can pass its
IUCV_LISTEN check and then read a field close() has cleared. That a SYN
can be accepted while the listener closes is left to the socket-locking
rework; this is its KCSAN-visible part. bind()'s hs_dev store runs
under the list's write lock and stays plain. sk_bound_dev_if, which
getsockopt() reads without the lock, is marked where close(), bind()
and the child store it; annotation only.

Fixes: 800c5eb7b5eb ("af_iucv: change net_device handling for HS transport")
Fixes: 80230a18c164 ("net/iucv: filter frames in afiucv_hs_rcv() by ingress device")
Reported-by: Hidayath Khan <hidayath@linux.ibm.com>
Closes: https://lore.kernel.org/netdev/b3fea2ca-25ff-42c0-812c-f8cc6bb6667e@linux.ibm.com/
Suggested-by: Hidayath Khan <hidayath@linux.ibm.com>
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Nagamani PV's "net/iucv: fix races in afiucv_netdev_event()" [1] marks the
same store in close(); Alexandra Winter asked him to hold it for the
locking series and he agreed [2]. This one goes now on a new, independent
KCSAN report, and its close() hunk subsumes his, which marks the store
but keeps dev_put() first; once this is applied, the
afiucv_netdev_event() read is what remains for his patch.

The loop's memcmp()s on the name fields are plain as well, against
connect()'s stores under lock_sock(); they were not in Hidayath's report
and are not touched here. The child that afiucv_hs_callback_syn() leaks
on its error paths (iucv_sock_kill() on a socket that was never closed
is a no-op), with the device reference it holds when dev_queue_xmit()
fails, is pre-existing; Hidayath flagged it in August [3] and his fix
for it is pending. A child the callback enqueues after
iucv_sock_cleanup_listen() has drained the accept queue is never
accepted or killed either; it now holds the device the frame arrived on,
where before it held the listener's device or nothing, depending on
which side of the clear it read.

Tested on s390x under QEMU TCG (net-next 8df0638138d3, KASAN +
PROVE_LOCKING) with an emulated HiperSockets adapter under the real qeth
and qdio drivers. The rework's test set, 53 tests, gives the same result
with and without this patch: the 8 that fail on net-next are the bugs
the rework fixes, and they fail the same way. That setup has no KCSAN
and nothing that drives afiucv_hs_rcv()'s lookup against a close() at
the right instant. Hidayath's KCSAN report covers the lookup's read and
proposed the clear-before-put order through a local; the child's device
source comes from reading the code.

[1] https://lore.kernel.org/netdev/20260917071706.23831-1-nagamani@linux.ibm.com/
[2] https://lore.kernel.org/netdev/1d9d3cc1-24fb-40e0-a4c7-6fbfbcf4dc37@linux.ibm.com/
[3] https://lore.kernel.org/netdev/5f88daf4-cd8e-4464-b132-ac45be205121@linux.ibm.com/
---
 net/iucv/af_iucv.c | 32 ++++++++++++++++++++++++--------
 1 file changed, 24 insertions(+), 8 deletions(-)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index db261ecd19af..501e758c5e68 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -447,9 +447,16 @@ static void iucv_sock_close(struct sock *sk)
 	}
 
 	if (iucv->hs_dev) {
-		dev_put(iucv->hs_dev);
-		iucv->hs_dev = NULL;
-		sk->sk_bound_dev_if = 0;
+		struct net_device *dev = iucv->hs_dev;
+
+		/* afiucv_hs_rcv() matches frames on hs_dev under
+		 * iucv_sk_list.lock, not the socket lock: clear it before the
+		 * reference goes, so the match can no longer find a device
+		 * this socket does not hold.
+		 */
+		WRITE_ONCE(iucv->hs_dev, NULL);
+		WRITE_ONCE(sk->sk_bound_dev_if, 0);
+		dev_put(dev);
 	}
 
 	/* mark socket for deletion by iucv_sock_kill() */
@@ -630,7 +637,7 @@ static int iucv_sock_bind(struct socket *sock, struct sockaddr_unsized *addr,
 				__iucv_auto_name(iucv);
 			else
 				memcpy(iucv->src_name, sa->siucv_name, 8);
-			sk->sk_bound_dev_if = dev->ifindex;
+			WRITE_ONCE(sk->sk_bound_dev_if, dev->ifindex);
 			iucv->hs_dev = dev;
 			dev_hold(dev);
 			sk->sk_state = IUCV_BOUND;
@@ -1912,9 +1919,14 @@ static int afiucv_hs_callback_syn(struct sock *sk, struct sk_buff *skb)
 	memcpy(niucv->dst_user_id, trans_hdr->srcUserID, 8);
 	memcpy(niucv->src_name, iucv->src_name, 8);
 	memcpy(niucv->src_user_id, iucv->src_user_id, 8);
-	nsk->sk_bound_dev_if = sk->sk_bound_dev_if;
-	niucv->hs_dev = iucv->hs_dev;
-	dev_hold(niucv->hs_dev);
+	/* skb->dev is the device the lookup matched against the listener's
+	 * hs_dev; the listener's own fields are cleared by close() under
+	 * lock_sock(), which this softirq does not hold. nsk is in
+	 * iucv_sk_list already: hold, then publish.
+	 */
+	WRITE_ONCE(nsk->sk_bound_dev_if, skb->dev->ifindex);
+	dev_hold(skb->dev);
+	WRITE_ONCE(niucv->hs_dev, skb->dev);
 	afiucv_swap_src_dest(skb);
 	trans_hdr->flags = AF_IUCV_FLAG_SYN | AF_IUCV_FLAG_ACK;
 	trans_hdr->window = niucv->msglimit;
@@ -2087,7 +2099,11 @@ static int afiucv_hs_rcv(struct sk_buff *skb, struct net_device *dev,
 	sk = NULL;
 	read_lock(&iucv_sk_list.lock);
 	sk_for_each(sk, &iucv_sk_list.head) {
-		if (iucv_sk(sk)->hs_dev != dev)
+		/* Cleared before iucv_sock_close() drops the reference:
+		 * whichever value is read is a device the socket still
+		 * holds, or NULL.
+		 */
+		if (READ_ONCE(iucv_sk(sk)->hs_dev) != dev)
 			continue;
 		if (trans_hdr->flags == AF_IUCV_FLAG_SYN) {
 			if ((!memcmp(&iucv_sk(sk)->src_name,

-- 
2.56.0

