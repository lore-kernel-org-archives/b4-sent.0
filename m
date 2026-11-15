From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 14 Nov 2026 20:29:23 -0500
Subject: [PATCH RFC net v4 5/8] net/iucv: factor out the HiperSockets frame
 dispatch and state changes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-b4-disp-fc0634a3-v4-5-f96c506447ce@proton.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794706158; l=7474;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=BNAZtikCBJei0ASy2WgzatfOm8YeIdFf9/iGDFegDGE=;
 b=v9r8wsBSEJ+0vY0TkPxfLeNVfcaTN6qXU346I+rouF+9JEbcekGF95oVXvhqkXKlajmJ3erQr
 VXF6+psv5cBBd0UE2cjETWL1jzhn68zDAYP9LoJ5tldc9ZifbQI2u/T
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the switch on the frame type out of afiucv_hs_rcv() into
afiucv_hs_dispatch(), and the state changes a SYN|ACK, a SYN|FIN and a
FIN make into afiucv_hs_synack(), afiucv_hs_synfin() and
afiucv_hs_fin(). The three are still called under the bh_lock_sock() of
their callbacks, which now test sk where they tested iucv_sk(sk), a
cast of it. They are defined ahead of iucv_proto: the next patch
reaches them from proto->release_cb. afiucv_hs_synfin() and
afiucv_hs_fin() are the same for now and stay two: a later patch sets
RCV_SHUTDOWN in the second only.

No functional change. The next patch runs the dispatch from a second
place and the three state changes from the task that owns the socket.

Cc: stable@vger.kernel.org # 6.18.x, needed by the next patch
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
v4: unchanged, was 4/7.
v3: https://lore.kernel.org/netdev/20261110-b4-disp-2a6b4364-v3-4-35677b68e697@proton.me/

checkpatch asks for a Fixes: tag because of the stable line. There is
none to give: the patch fixes nothing and is marked for stable only so
that 6/8 applies there.

The kernel with 1/8 to 5/8 gives the result of the one with 1/8 to 4/8
in every test: the 53 default ones and the 28 opt-in ones (window,
strays, connect(), leaks).
---
 net/iucv/af_iucv.c | 151 ++++++++++++++++++++++++++++++++++-------------------
 1 file changed, 97 insertions(+), 54 deletions(-)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index 80eb90b1ef3c..957315bec2b4 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -39,6 +39,44 @@
 
 static char iucv_userid[80];
 
+/**
+ * afiucv_hs_synack() - connect a socket, on the SYN|ACK to its SYN
+ * @sk:		the socket, in IUCV_BOUND
+ * @window:	the window in the SYN|ACK: the frames the peer takes from us
+ *
+ * Context: Softirq, under bh_lock_sock().
+ */
+static void afiucv_hs_synack(struct sock *sk, u16 window)
+{
+	iucv_sk(sk)->msglimit_peer = window;
+	sk->sk_state = IUCV_CONNECTED;
+	sk->sk_state_change(sk);
+}
+
+/**
+ * afiucv_hs_synfin() - refuse a socket, on the SYN|FIN to its SYN
+ * @sk:		the socket, in IUCV_BOUND
+ *
+ * Context: As afiucv_hs_synack().
+ */
+static void afiucv_hs_synfin(struct sock *sk)
+{
+	sk->sk_state = IUCV_DISCONN;
+	sk->sk_state_change(sk);
+}
+
+/**
+ * afiucv_hs_fin() - disconnect a socket, on the FIN of its peer
+ * @sk:		the socket, in IUCV_CONNECTED
+ *
+ * Context: As afiucv_hs_synack().
+ */
+static void afiucv_hs_fin(struct sock *sk)
+{
+	sk->sk_state = IUCV_DISCONN;
+	sk->sk_state_change(sk);
+}
+
 static struct proto iucv_proto = {
 	.name		= "AF_IUCV",
 	.owner		= THIS_MODULE,
@@ -2041,17 +2079,13 @@ static int afiucv_hs_callback_syn(struct sock *sk, struct sk_buff *skb)
  */
 static int afiucv_hs_callback_synack(struct sock *sk, struct sk_buff *skb)
 {
-	struct iucv_sock *iucv = iucv_sk(sk);
-
-	if (!iucv || sk->sk_state != IUCV_BOUND) {
+	if (!sk || sk->sk_state != IUCV_BOUND) {
 		kfree_skb(skb);
 		return NET_RX_SUCCESS;
 	}
 
 	bh_lock_sock(sk);
-	iucv->msglimit_peer = iucv_trans_hdr(skb)->window;
-	sk->sk_state = IUCV_CONNECTED;
-	sk->sk_state_change(sk);
+	afiucv_hs_synack(sk, iucv_trans_hdr(skb)->window);
 	bh_unlock_sock(sk);
 	consume_skb(skb);
 	return NET_RX_SUCCESS;
@@ -2062,16 +2096,13 @@ static int afiucv_hs_callback_synack(struct sock *sk, struct sk_buff *skb)
  */
 static int afiucv_hs_callback_synfin(struct sock *sk, struct sk_buff *skb)
 {
-	struct iucv_sock *iucv = iucv_sk(sk);
-
-	if (!iucv || sk->sk_state != IUCV_BOUND) {
+	if (!sk || sk->sk_state != IUCV_BOUND) {
 		kfree_skb(skb);
 		return NET_RX_SUCCESS;
 	}
 
 	bh_lock_sock(sk);
-	sk->sk_state = IUCV_DISCONN;
-	sk->sk_state_change(sk);
+	afiucv_hs_synfin(sk);
 	bh_unlock_sock(sk);
 	consume_skb(skb);
 	return NET_RX_SUCCESS;
@@ -2082,19 +2113,15 @@ static int afiucv_hs_callback_synfin(struct sock *sk, struct sk_buff *skb)
  */
 static int afiucv_hs_callback_fin(struct sock *sk, struct sk_buff *skb)
 {
-	struct iucv_sock *iucv = iucv_sk(sk);
-
 	/* other end of connection closed */
-	if (!iucv) {
+	if (!sk) {
 		kfree_skb(skb);
 		return NET_RX_SUCCESS;
 	}
 
 	bh_lock_sock(sk);
-	if (sk->sk_state == IUCV_CONNECTED) {
-		sk->sk_state = IUCV_DISCONN;
-		sk->sk_state_change(sk);
-	}
+	if (sk->sk_state == IUCV_CONNECTED)
+		afiucv_hs_fin(sk);
 	bh_unlock_sock(sk);
 	consume_skb(skb);
 	return NET_RX_SUCCESS;
@@ -2162,6 +2189,57 @@ static int afiucv_hs_callback_rx(struct sock *sk, struct sk_buff *skb)
 	return NET_RX_SUCCESS;
 }
 
+/**
+ * afiucv_hs_dispatch() - run the callback of a frame
+ * @sk:		the socket the frame is for, or NULL if there is none
+ * @skb:	the frame
+ *
+ * Context: Softirq.
+ * Return: NET_RX_SUCCESS.
+ */
+static int afiucv_hs_dispatch(struct sock *sk, struct sk_buff *skb)
+{
+	struct af_iucv_trans_hdr *trans_hdr = iucv_trans_hdr(skb);
+	int err = NET_RX_SUCCESS;
+
+	switch (trans_hdr->flags) {
+	case AF_IUCV_FLAG_SYN:
+		/* connect request */
+		err = afiucv_hs_callback_syn(sk, skb);
+		break;
+	case (AF_IUCV_FLAG_SYN | AF_IUCV_FLAG_ACK):
+		/* connect request confirmed */
+		err = afiucv_hs_callback_synack(sk, skb);
+		break;
+	case (AF_IUCV_FLAG_SYN | AF_IUCV_FLAG_FIN):
+		/* connect request refused */
+		err = afiucv_hs_callback_synfin(sk, skb);
+		break;
+	case (AF_IUCV_FLAG_FIN):
+		/* close request */
+		err = afiucv_hs_callback_fin(sk, skb);
+		break;
+	case (AF_IUCV_FLAG_WIN):
+		err = afiucv_hs_callback_win(sk, skb);
+		if (skb->len == sizeof(struct af_iucv_trans_hdr)) {
+			consume_skb(skb);
+			break;
+		}
+		fallthrough;	/* and receive non-zero length data */
+	case (AF_IUCV_FLAG_SHT):
+		/* shutdown request */
+		fallthrough;	/* and receive zero length data */
+	case 0:
+		/* plain data frame */
+		IUCV_SKB_CB(skb)->class = trans_hdr->iucv_hdr.class;
+		err = afiucv_hs_callback_rx(sk, skb);
+		break;
+	default:
+		kfree_skb(skb);
+	}
+	return err;
+}
+
 /*
  * afiucv_hs_rcv() - base function for arriving data through HiperSockets
  *                   transport
@@ -2242,42 +2320,7 @@ static int afiucv_hs_rcv(struct sk_buff *skb, struct net_device *dev,
 	 data -> send FIN
 	 SYN|ACK, SYN|FIN, FIN -> no action? */
 
-	switch (trans_hdr->flags) {
-	case AF_IUCV_FLAG_SYN:
-		/* connect request */
-		err = afiucv_hs_callback_syn(sk, skb);
-		break;
-	case (AF_IUCV_FLAG_SYN | AF_IUCV_FLAG_ACK):
-		/* connect request confirmed */
-		err = afiucv_hs_callback_synack(sk, skb);
-		break;
-	case (AF_IUCV_FLAG_SYN | AF_IUCV_FLAG_FIN):
-		/* connect request refused */
-		err = afiucv_hs_callback_synfin(sk, skb);
-		break;
-	case (AF_IUCV_FLAG_FIN):
-		/* close request */
-		err = afiucv_hs_callback_fin(sk, skb);
-		break;
-	case (AF_IUCV_FLAG_WIN):
-		err = afiucv_hs_callback_win(sk, skb);
-		if (skb->len == sizeof(struct af_iucv_trans_hdr)) {
-			consume_skb(skb);
-			break;
-		}
-		fallthrough;	/* and receive non-zero length data */
-	case (AF_IUCV_FLAG_SHT):
-		/* shutdown request */
-		fallthrough;	/* and receive zero length data */
-	case 0:
-		/* plain data frame */
-		IUCV_SKB_CB(skb)->class = trans_hdr->iucv_hdr.class;
-		err = afiucv_hs_callback_rx(sk, skb);
-		break;
-	default:
-		kfree_skb(skb);
-	}
-
+	err = afiucv_hs_dispatch(sk, skb);
 	if (sk)
 		sock_put(sk);
 	return err;

-- 
2.56.0

