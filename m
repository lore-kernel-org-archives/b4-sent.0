From: Oliver Hartkopp <socketcan@hartkopp.net>
Date: Sun, 01 Feb 2026 15:33:20 +0100
Subject: [PATCH net-next v8 5/6] can: remove private CAN skb headroom
 infrastructure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260201-can_skb_ext-v8-5-3635d790fe8b@hartkopp.net>
References: <20260201-can_skb_ext-v8-0-3635d790fe8b@hartkopp.net>
In-Reply-To: <20260201-can_skb_ext-v8-0-3635d790fe8b@hartkopp.net>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Oliver Hartkopp <socketcan@hartkopp.net>, 
 Robin van der Gracht <robin@protonic.nl>, 
 Oleksij Rempel <o.rempel@pengutronix.de>, kernel@pengutronix.de, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 netdev@vger.kernel.org
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769956418; l=12992;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=8latfQ42+KWkvgJX7eiG4SXUR1zyD7tvI5xRV1vgLaY=;
 b=hTNTqc0V4X7aLwK9oZlXmHCU2cF0k5pUrxP+Luth3VLtJ9GgN6RE2C5cYpg/+19KIipgwzmAw
 6YK9hnDqjXeC6qc6QzUGsdgjdqPYDHifORACxeQAYbei5abLaAmk09n
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch removes struct can_skb_priv which was stored at skb->head and
the can_skb_reserve() helper which was used to shift skb->head.

Signed-off-by: Marc Kleine-Budde <mkl@pengutronix.de>
Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
 drivers/net/can/dev/skb.c | 31 +++++++++----------------------
 include/linux/can/skb.h   | 31 -------------------------------
 net/can/bcm.c             |  7 ++-----
 net/can/isotp.c           | 12 ++++--------
 net/can/j1939/socket.c    |  4 +---
 net/can/j1939/transport.c |  7 ++-----
 net/can/raw.c             |  5 ++---
 7 files changed, 20 insertions(+), 77 deletions(-)

diff --git a/drivers/net/can/dev/skb.c b/drivers/net/can/dev/skb.c
index 408ee49abce1..95fcdc1026f8 100644
--- a/drivers/net/can/dev/skb.c
+++ b/drivers/net/can/dev/skb.c
@@ -204,40 +204,33 @@ void can_free_echo_skb(struct net_device *dev, unsigned int idx,
 	}
 }
 EXPORT_SYMBOL_GPL(can_free_echo_skb);
 
 /* fill common values for CAN sk_buffs */
-static void init_can_skb_reserve(struct sk_buff *skb)
+static void init_can_skb(struct sk_buff *skb)
 {
 	skb->pkt_type = PACKET_BROADCAST;
 	skb->ip_summed = CHECKSUM_UNNECESSARY;
-
-	skb_reset_mac_header(skb);
-	skb_reset_network_header(skb);
-	skb_reset_transport_header(skb);
-
-	can_skb_reserve(skb);
 }
 
 struct sk_buff *alloc_can_skb(struct net_device *dev, struct can_frame **cf)
 {
 	struct sk_buff *skb;
 	struct can_skb_ext *csx;
 
-	skb = netdev_alloc_skb(dev, sizeof(struct can_skb_priv) +
-			       sizeof(struct can_frame));
+	skb = netdev_alloc_skb(dev, sizeof(struct can_frame));
 	if (unlikely(!skb))
 		goto out_error_cc;
 
 	csx = can_skb_ext_add(skb);
 	if (!csx) {
 		kfree_skb(skb);
 		goto out_error_cc;
 	}
 
 	skb->protocol = htons(ETH_P_CAN);
-	init_can_skb_reserve(skb);
+	init_can_skb(skb);
 	csx->can_iif = dev->ifindex;
 
 	*cf = skb_put_zero(skb, sizeof(struct can_frame));
 
 	return skb;
@@ -253,23 +246,22 @@ struct sk_buff *alloc_canfd_skb(struct net_device *dev,
 				struct canfd_frame **cfd)
 {
 	struct sk_buff *skb;
 	struct can_skb_ext *csx;
 
-	skb = netdev_alloc_skb(dev, sizeof(struct can_skb_priv) +
-			       sizeof(struct canfd_frame));
+	skb = netdev_alloc_skb(dev, sizeof(struct canfd_frame));
 	if (unlikely(!skb))
 		goto out_error_fd;
 
 	csx = can_skb_ext_add(skb);
 	if (!csx) {
 		kfree_skb(skb);
 		goto out_error_fd;
 	}
 
 	skb->protocol = htons(ETH_P_CANFD);
-	init_can_skb_reserve(skb);
+	init_can_skb(skb);
 	csx->can_iif = dev->ifindex;
 
 	*cfd = skb_put_zero(skb, sizeof(struct canfd_frame));
 
 	/* set CAN FD flag by default */
@@ -292,23 +284,22 @@ struct sk_buff *alloc_canxl_skb(struct net_device *dev,
 	struct can_skb_ext *csx;
 
 	if (data_len < CANXL_MIN_DLEN || data_len > CANXL_MAX_DLEN)
 		goto out_error_xl;
 
-	skb = netdev_alloc_skb(dev, sizeof(struct can_skb_priv) +
-			       CANXL_HDR_SIZE + data_len);
+	skb = netdev_alloc_skb(dev, CANXL_HDR_SIZE + data_len);
 	if (unlikely(!skb))
 		goto out_error_xl;
 
 	csx = can_skb_ext_add(skb);
 	if (!csx) {
 		kfree_skb(skb);
 		goto out_error_xl;
 	}
 
 	skb->protocol = htons(ETH_P_CANXL);
-	init_can_skb_reserve(skb);
+	init_can_skb(skb);
 	csx->can_iif = dev->ifindex;
 
 	*cxl = skb_put_zero(skb, CANXL_HDR_SIZE + data_len);
 
 	/* set CAN XL flag and length information by default */
@@ -338,18 +329,14 @@ struct sk_buff *alloc_can_err_skb(struct net_device *dev, struct can_frame **cf)
 	return skb;
 }
 EXPORT_SYMBOL_GPL(alloc_can_err_skb);
 
 /* Check for outgoing skbs that have not been created by the CAN subsystem */
-static bool can_skb_headroom_valid(struct net_device *dev, struct sk_buff *skb)
+static bool can_skb_init_valid(struct net_device *dev, struct sk_buff *skb)
 {
 	struct can_skb_ext *csx = can_skb_ext_find(skb);
 
-	/* af_packet creates a headroom of HH_DATA_MOD bytes which is fine */
-	if (WARN_ON_ONCE(skb_headroom(skb) < sizeof(struct can_skb_priv)))
-		return false;
-
 	/* af_packet does not apply CAN skb specific settings */
 	if (skb->ip_summed == CHECKSUM_NONE || !csx) {
 		/* init CAN skb content */
 		if (!csx) {
 			csx = can_skb_ext_add(skb);
@@ -403,11 +390,11 @@ bool can_dropped_invalid_skb(struct net_device *dev, struct sk_buff *skb)
 
 	default:
 		goto inval_skb;
 	}
 
-	if (!can_skb_headroom_valid(dev, skb))
+	if (!can_skb_init_valid(dev, skb))
 		goto inval_skb;
 
 	return false;
 
 inval_skb:
diff --git a/include/linux/can/skb.h b/include/linux/can/skb.h
index 68c0f24e6914..a70a02967071 100644
--- a/include/linux/can/skb.h
+++ b/include/linux/can/skb.h
@@ -36,41 +36,10 @@ struct sk_buff *alloc_canxl_skb(struct net_device *dev,
 				unsigned int data_len);
 struct sk_buff *alloc_can_err_skb(struct net_device *dev,
 				  struct can_frame **cf);
 bool can_dropped_invalid_skb(struct net_device *dev, struct sk_buff *skb);
 
-/*
- * The struct can_skb_priv is used to transport additional information along
- * with the stored struct can(fd)_frame that can not be contained in existing
- * struct sk_buff elements.
- * N.B. that this information must not be modified in cloned CAN sk_buffs.
- * To modify the CAN frame content or the struct can_skb_priv content
- * skb_copy() needs to be used instead of skb_clone().
- */
-
-/**
- * struct can_skb_priv - private additional data inside CAN sk_buffs
- * @ifindex:	ifindex of the first interface the CAN frame appeared on
- * @frame_len:	length of CAN frame in data link layer
- * @cf:		align to the following CAN frame at skb->data
- */
-struct can_skb_priv {
-	int ifindex;
-	unsigned int frame_len;
-	struct can_frame cf[];
-};
-
-static inline struct can_skb_priv *can_skb_prv(struct sk_buff *skb)
-{
-	return (struct can_skb_priv *)(skb->head);
-}
-
-static inline void can_skb_reserve(struct sk_buff *skb)
-{
-	skb_reserve(skb, sizeof(struct can_skb_priv));
-}
-
 static inline struct can_skb_ext *can_skb_ext_add(struct sk_buff *skb)
 {
 	struct can_skb_ext *csx = skb_ext_add(skb, SKB_EXT_CAN);
 
 	/* skb_ext_add() returns uninitialized space */
diff --git a/net/can/bcm.c b/net/can/bcm.c
index f102d17e8619..b7324e9c955b 100644
--- a/net/can/bcm.c
+++ b/net/can/bcm.c
@@ -310,21 +310,20 @@ static void bcm_can_tx(struct bcm_op *op)
 	if (!dev) {
 		/* RFC: should this bcm_op remove itself here? */
 		return;
 	}
 
-	skb = alloc_skb(op->cfsiz + sizeof(struct can_skb_priv), gfp_any());
+	skb = alloc_skb(op->cfsiz, gfp_any());
 	if (!skb)
 		goto out;
 
 	csx = can_skb_ext_add(skb);
 	if (!csx) {
 		kfree_skb(skb);
 		goto out;
 	}
 
-	can_skb_reserve(skb);
 	csx->can_iif = dev->ifindex;
 
 	skb_put_data(skb, cf, op->cfsiz);
 
 	/* send with loopback */
@@ -1331,22 +1330,20 @@ static int bcm_tx_send(struct msghdr *msg, int ifindex, struct sock *sk,
 
 	/* we need a real device to send frames */
 	if (!ifindex)
 		return -ENODEV;
 
-	skb = alloc_skb(cfsiz + sizeof(struct can_skb_priv), GFP_KERNEL);
+	skb = alloc_skb(cfsiz, GFP_KERNEL);
 	if (!skb)
 		return -ENOMEM;
 
 	csx = can_skb_ext_add(skb);
 	if (!csx) {
 		kfree_skb(skb);
 		return -ENOMEM;
 	}
 
-	can_skb_reserve(skb);
-
 	err = memcpy_from_msg(skb_put(skb, cfsiz), msg, cfsiz);
 	if (err < 0) {
 		kfree_skb(skb);
 		return err;
 	}
diff --git a/net/can/isotp.c b/net/can/isotp.c
index 164c4fbf3e23..da3b72e7afcc 100644
--- a/net/can/isotp.c
+++ b/net/can/isotp.c
@@ -218,11 +218,11 @@ static int isotp_send_fc(struct sock *sk, int ae, u8 flowstatus)
 	struct can_skb_ext *csx;
 	struct canfd_frame *ncf;
 	struct isotp_sock *so = isotp_sk(sk);
 	int can_send_ret;
 
-	nskb = alloc_skb(so->ll.mtu + sizeof(struct can_skb_priv), gfp_any());
+	nskb = alloc_skb(so->ll.mtu, gfp_any());
 	if (!nskb)
 		return 1;
 
 	csx = can_skb_ext_add(nskb);
 	if (!csx) {
@@ -234,13 +234,11 @@ static int isotp_send_fc(struct sock *sk, int ae, u8 flowstatus)
 	if (!dev) {
 		kfree_skb(nskb);
 		return 1;
 	}
 
-	can_skb_reserve(nskb);
 	csx->can_iif = dev->ifindex;
-
 	nskb->dev = dev;
 	can_skb_set_owner(nskb, sk);
 	ncf = (struct canfd_frame *)nskb->data;
 	skb_put_zero(nskb, so->ll.mtu);
 
@@ -778,11 +776,11 @@ static void isotp_send_cframe(struct isotp_sock *so)
 
 	dev = dev_get_by_index(sock_net(sk), so->ifindex);
 	if (!dev)
 		return;
 
-	skb = alloc_skb(so->ll.mtu + sizeof(struct can_skb_priv), GFP_ATOMIC);
+	skb = alloc_skb(so->ll.mtu, GFP_ATOMIC);
 	if (!skb) {
 		dev_put(dev);
 		return;
 	}
 
@@ -791,11 +789,10 @@ static void isotp_send_cframe(struct isotp_sock *so)
 		kfree_skb(skb);
 		netdev_put(dev, NULL);
 		return;
 	}
 
-	can_skb_reserve(skb);
 	csx->can_iif = dev->ifindex;
 
 	cf = (struct canfd_frame *)skb->data;
 	skb_put_zero(skb, so->ll.mtu);
 
@@ -1013,12 +1010,12 @@ static int isotp_sendmsg(struct socket *sock, struct msghdr *msg, size_t size)
 	if (!dev) {
 		err = -ENXIO;
 		goto err_out_drop;
 	}
 
-	skb = sock_alloc_send_skb(sk, so->ll.mtu + sizeof(struct can_skb_priv),
-				  msg->msg_flags & MSG_DONTWAIT, &err);
+	skb = sock_alloc_send_skb(sk, so->ll.mtu, msg->msg_flags & MSG_DONTWAIT,
+				  &err);
 	if (!skb) {
 		dev_put(dev);
 		goto err_out_drop;
 	}
 
@@ -1028,11 +1025,10 @@ static int isotp_sendmsg(struct socket *sock, struct msghdr *msg, size_t size)
 		netdev_put(dev, NULL);
 		err = -ENOMEM;
 		goto err_out_drop;
 	}
 
-	can_skb_reserve(skb);
 	csx->can_iif = dev->ifindex;
 
 	so->tx.len = size;
 	so->tx.idx = 0;
 
diff --git a/net/can/j1939/socket.c b/net/can/j1939/socket.c
index cc698a6dc363..0502b030d238 100644
--- a/net/can/j1939/socket.c
+++ b/net/can/j1939/socket.c
@@ -889,12 +889,11 @@ static struct sk_buff *j1939_sk_alloc_skb(struct net_device *ndev,
 	int ret;
 
 	skb = sock_alloc_send_skb(sk,
 				  size +
 				  sizeof(struct can_frame) -
-				  sizeof(((struct can_frame *)NULL)->data) +
-				  sizeof(struct can_skb_priv),
+				  sizeof(((struct can_frame *)NULL)->data),
 				  msg->msg_flags & MSG_DONTWAIT, &ret);
 	if (!skb)
 		goto failure;
 
 	csx = can_skb_ext_add(skb);
@@ -902,11 +901,10 @@ static struct sk_buff *j1939_sk_alloc_skb(struct net_device *ndev,
 		kfree_skb(skb);
 		ret = -ENOMEM;
 		goto failure;
 	}
 
-	can_skb_reserve(skb);
 	csx->can_iif = ndev->ifindex;
 	skb_reserve(skb, offsetof(struct can_frame, data));
 
 	ret = memcpy_from_msg(skb_put(skb, size), msg, size);
 	if (ret < 0)
diff --git a/net/can/j1939/transport.c b/net/can/j1939/transport.c
index 3456ef481799..2cbe94fc487a 100644
--- a/net/can/j1939/transport.c
+++ b/net/can/j1939/transport.c
@@ -593,23 +593,21 @@ sk_buff *j1939_tp_tx_dat_new(struct j1939_priv *priv,
 {
 	struct sk_buff *skb;
 	struct can_skb_ext *csx;
 	struct j1939_sk_buff_cb *skcb;
 
-	skb = alloc_skb(sizeof(struct can_frame) + sizeof(struct can_skb_priv),
-			GFP_ATOMIC);
+	skb = alloc_skb(sizeof(struct can_frame), GFP_ATOMIC);
 	if (unlikely(!skb))
 		return ERR_PTR(-ENOMEM);
 
 	csx = can_skb_ext_add(skb);
 	if (!csx) {
 		kfree_skb(skb);
 		return ERR_PTR(-ENOMEM);
 	}
 
 	skb->dev = priv->ndev;
-	can_skb_reserve(skb);
 	csx->can_iif = priv->ndev->ifindex;
 	/* reserve CAN header */
 	skb_reserve(skb, offsetof(struct can_frame, data));
 
 	/* skb->cb must be large enough to hold a j1939_sk_buff_cb structure */
@@ -1546,22 +1544,21 @@ j1939_session *j1939_session_fresh_new(struct j1939_priv *priv,
 	struct sk_buff *skb;
 	struct can_skb_ext *csx;
 	struct j1939_sk_buff_cb *skcb;
 	struct j1939_session *session;
 
-	skb = alloc_skb(size + sizeof(struct can_skb_priv), GFP_ATOMIC);
+	skb = alloc_skb(size, GFP_ATOMIC);
 	if (unlikely(!skb))
 		return NULL;
 
 	csx = can_skb_ext_add(skb);
 	if (!csx) {
 		kfree_skb(skb);
 		return NULL;
 	}
 
 	skb->dev = priv->ndev;
-	can_skb_reserve(skb);
 	csx->can_iif = priv->ndev->ifindex;
 	skcb = j1939_skb_to_cb(skb);
 	memcpy(skcb, rel_skcb, sizeof(*skcb));
 
 	session = j1939_session_new(priv, skb, size);
diff --git a/net/can/raw.c b/net/can/raw.c
index 022154b0f6cc..eee244ffc31e 100644
--- a/net/can/raw.c
+++ b/net/can/raw.c
@@ -951,23 +951,22 @@ static int raw_sendmsg(struct socket *sock, struct msghdr *msg, size_t size)
 	if (can_cap_enabled(dev, CAN_CAP_RO)) {
 		err = -EACCES;
 		goto put_dev;
 	}
 
-	skb = sock_alloc_send_skb(sk, size + sizeof(struct can_skb_priv),
-				  msg->msg_flags & MSG_DONTWAIT, &err);
+	skb = sock_alloc_send_skb(sk, size, msg->msg_flags & MSG_DONTWAIT,
+				  &err);
 	if (!skb)
 		goto put_dev;
 
 	csx = can_skb_ext_add(skb);
 	if (!csx) {
 		kfree_skb(skb);
 		err = -ENOMEM;
 		goto put_dev;
 	}
 
-	can_skb_reserve(skb);
 	csx->can_iif = dev->ifindex;
 
 	/* fill the skb before testing for valid CAN frames */
 	err = memcpy_from_msg(skb_put(skb, size), msg, size);
 	if (err < 0)

-- 
2.51.0

