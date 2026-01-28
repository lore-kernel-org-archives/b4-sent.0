From: Oliver Hartkopp <socketcan@hartkopp.net>
Date: Wed, 28 Jan 2026 22:10:52 +0100
Subject: [PATCH net-next V3 2/7] can: use netdev_put() instead of
 deprecated dev_put()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260128-can_skb_ext-v1-2-71b8bcbfd8cf@hartkopp.net>
References: <20260128-can_skb_ext-v1-0-71b8bcbfd8cf@hartkopp.net>
In-Reply-To: <20260128-can_skb_ext-v1-0-71b8bcbfd8cf@hartkopp.net>
To: netdev@vger.kernel.org, linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769634697; l=9728;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=IOisqz4qnDqPglh2hS6TkUQ5GGqkENcxyp0DwDEBFMU=;
 b=UOm6RAja35r5X11AKL7kvMpakfbQhGuikbTjKwy1i86x833MMh16U5dssxISi/tSANIarbJnZ
 FDhyeIlg7L2BrkrWnOfROlq2DGGuNtR4luLsNz8uF72CZLriqlEbXeb
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Checkpatch complained about using dev_put() in the following patch of this
series. Prepare the CAN subsystem to use netdev_put() consistently.

Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
 net/can/bcm.c          | 18 +++++++++---------
 net/can/isotp.c        | 18 +++++++++---------
 net/can/j1939/main.c   |  6 +++---
 net/can/j1939/socket.c |  8 ++++----
 net/can/raw.c          |  6 +++---
 5 files changed, 28 insertions(+), 28 deletions(-)

diff --git a/net/can/bcm.c b/net/can/bcm.c
index 8ed60f18c2eaff7053cb2c76e5e4cf1124dd3ac5..f76d60252803e62f438fd1936f366008698172e7 100644
--- a/net/can/bcm.c
+++ b/net/can/bcm.c
@@ -339,11 +339,11 @@ static void bcm_can_tx(struct bcm_op *op)
 	if (op->count > 0)
 		op->count--;
 
 	spin_unlock_bh(&op->bcm_tx_lock);
 out:
-	dev_put(dev);
+	netdev_put(dev);
 }
 
 /*
  * bcm_send_to_user - send a BCM message to the userspace
  *                    (consisting of bcm_msg_head + x CAN frames)
@@ -852,11 +852,11 @@ static int bcm_delete_rx_op(struct list_head *ops, struct bcm_msg_head *mh,
 
 					dev = dev_get_by_index(sock_net(op->sk),
 							       op->ifindex);
 					if (dev) {
 						bcm_rx_unreg(dev, op);
-						dev_put(dev);
+						netdev_put(dev);
 					}
 				}
 			} else
 				can_rx_unregister(sock_net(op->sk), NULL,
 						  op->can_id,
@@ -1290,11 +1290,11 @@ static int bcm_rx_setup(struct bcm_msg_head *msg_head, struct msghdr *msg,
 						      REGMASK(op->can_id),
 						      bcm_rx_handler, op,
 						      "bcm", sk);
 
 				op->rx_reg_dev = dev;
-				dev_put(dev);
+				netdev_put(dev);
 			}
 
 		} else
 			err = can_rx_register(sock_net(sk), NULL, op->can_id,
 					      REGMASK(op->can_id),
@@ -1344,11 +1344,11 @@ static int bcm_tx_send(struct msghdr *msg, int ifindex, struct sock *sk,
 
 	can_skb_prv(skb)->ifindex = dev->ifindex;
 	skb->dev = dev;
 	can_skb_set_owner(skb, sk);
 	err = can_send(skb, 1); /* send with loopback */
-	dev_put(dev);
+	netdev_put(dev);
 
 	if (err)
 		return err;
 
 	return cfsiz + MHSIZ;
@@ -1403,15 +1403,15 @@ static int bcm_sendmsg(struct socket *sock, struct msghdr *msg, size_t size)
 			dev = dev_get_by_index(sock_net(sk), ifindex);
 			if (!dev)
 				return -ENODEV;
 
 			if (dev->type != ARPHRD_CAN) {
-				dev_put(dev);
+				netdev_put(dev);
 				return -ENODEV;
 			}
 
-			dev_put(dev);
+			netdev_put(dev);
 		}
 	}
 
 	lock_sock(sk);
 
@@ -1622,11 +1622,11 @@ static int bcm_release(struct socket *sock)
 				struct net_device *dev;
 
 				dev = dev_get_by_index(net, op->ifindex);
 				if (dev) {
 					bcm_rx_unreg(dev, op);
-					dev_put(dev);
+					netdev_put(dev);
 				}
 			}
 		} else
 			can_rx_unregister(net, NULL, op->can_id,
 					  REGMASK(op->can_id),
@@ -1682,17 +1682,17 @@ static int bcm_connect(struct socket *sock, struct sockaddr_unsized *uaddr, int
 		if (!dev) {
 			ret = -ENODEV;
 			goto fail;
 		}
 		if (dev->type != ARPHRD_CAN) {
-			dev_put(dev);
+			netdev_put(dev);
 			ret = -ENODEV;
 			goto fail;
 		}
 
 		bo->ifindex = dev->ifindex;
-		dev_put(dev);
+		netdev_put(dev);
 
 	} else {
 		/* no interface reference for ifindex = 0 ('any' CAN device) */
 		bo->ifindex = 0;
 	}
diff --git a/net/can/isotp.c b/net/can/isotp.c
index 4bb60b8f9b96188a328e77be2fdefcb879da1089..b36173db119c85a6ef74a172236c08b372b875a9 100644
--- a/net/can/isotp.c
+++ b/net/can/isotp.c
@@ -258,11 +258,11 @@ static int isotp_send_fc(struct sock *sk, int ae, u8 flowstatus)
 	can_send_ret = can_send(nskb, 1);
 	if (can_send_ret)
 		pr_notice_once("can-isotp: %s: can_send_ret %pe\n",
 			       __func__, ERR_PTR(can_send_ret));
 
-	dev_put(dev);
+	netdev_put(dev);
 
 	/* reset blocksize counter */
 	so->rx.bs = 0;
 
 	/* reset last CF frame rx timestamp for rx stmin enforcement */
@@ -771,11 +771,11 @@ static void isotp_send_cframe(struct isotp_sock *so)
 	if (!dev)
 		return;
 
 	skb = alloc_skb(so->ll.mtu + sizeof(struct can_skb_priv), GFP_ATOMIC);
 	if (!skb) {
-		dev_put(dev);
+		netdev_put(dev);
 		return;
 	}
 
 	can_skb_reserve(skb);
 	can_skb_prv(skb)->ifindex = dev->ifindex;
@@ -809,11 +809,11 @@ static void isotp_send_cframe(struct isotp_sock *so)
 		pr_notice_once("can-isotp: %s: can_send_ret %pe\n",
 			       __func__, ERR_PTR(can_send_ret));
 		if (can_send_ret == -ENOBUFS)
 			pr_notice_once("can-isotp: tx queue is full\n");
 	}
-	dev_put(dev);
+	netdev_put(dev);
 }
 
 static void isotp_create_fframe(struct canfd_frame *cf, struct isotp_sock *so,
 				int ae)
 {
@@ -999,11 +999,11 @@ static int isotp_sendmsg(struct socket *sock, struct msghdr *msg, size_t size)
 	}
 
 	skb = sock_alloc_send_skb(sk, so->ll.mtu + sizeof(struct can_skb_priv),
 				  msg->msg_flags & MSG_DONTWAIT, &err);
 	if (!skb) {
-		dev_put(dev);
+		netdev_put(dev);
 		goto err_out_drop;
 	}
 
 	can_skb_reserve(skb);
 	can_skb_prv(skb)->ifindex = dev->ifindex;
@@ -1081,11 +1081,11 @@ static int isotp_sendmsg(struct socket *sock, struct msghdr *msg, size_t size)
 	cf->flags = so->ll.tx_flags;
 
 	skb->dev = dev;
 	skb->sk = sk;
 	err = can_send(skb, 1);
-	dev_put(dev);
+	netdev_put(dev);
 	if (err) {
 		pr_notice_once("can-isotp: %s: can_send_ret %pe\n",
 			       __func__, ERR_PTR(err));
 
 		/* no transmission -> no timeout monitoring */
@@ -1212,11 +1212,11 @@ static int isotp_release(struct socket *sock)
 							  isotp_rcv, sk);
 
 				can_rx_unregister(net, dev, so->txid,
 						  SINGLE_MASK(so->txid),
 						  isotp_rcv_echo, sk);
-				dev_put(dev);
+				netdev_put(dev);
 				synchronize_rcu();
 			}
 		}
 	}
 
@@ -1304,16 +1304,16 @@ static int isotp_bind(struct socket *sock, struct sockaddr_unsized *uaddr, int l
 	if (!dev) {
 		err = -ENODEV;
 		goto out;
 	}
 	if (dev->type != ARPHRD_CAN) {
-		dev_put(dev);
+		netdev_put(dev);
 		err = -ENODEV;
 		goto out;
 	}
 	if (READ_ONCE(dev->mtu) < so->ll.mtu) {
-		dev_put(dev);
+		netdev_put(dev);
 		err = -EINVAL;
 		goto out;
 	}
 	if (!(dev->flags & IFF_UP))
 		notify_enetdown = 1;
@@ -1329,11 +1329,11 @@ static int isotp_bind(struct socket *sock, struct sockaddr_unsized *uaddr, int l
 
 	/* register for echo skb's */
 	can_rx_register(net, dev, tx_id, SINGLE_MASK(tx_id),
 			isotp_rcv_echo, sk, "isotpe", sk);
 
-	dev_put(dev);
+	netdev_put(dev);
 
 	/* switch to new settings */
 	so->ifindex = ifindex;
 	so->rxid = rx_id;
 	so->txid = tx_id;
diff --git a/net/can/j1939/main.c b/net/can/j1939/main.c
index a93af55df5fd500fa5d564160ad563a3883d2eac..dadf5be529070dcb4c077e68049e091511ef5361 100644
--- a/net/can/j1939/main.c
+++ b/net/can/j1939/main.c
@@ -161,11 +161,11 @@ static void __j1939_priv_release(struct kref *kref)
 
 	WARN_ON_ONCE(!list_empty(&priv->active_session_list));
 	WARN_ON_ONCE(!list_empty(&priv->ecus));
 	WARN_ON_ONCE(!list_empty(&priv->j1939_socks));
 
-	dev_put(ndev);
+	netdev_put(ndev);
 	kfree(priv);
 }
 
 void j1939_priv_put(struct j1939_priv *priv)
 {
@@ -279,11 +279,11 @@ struct j1939_priv *j1939_netdev_start(struct net_device *ndev)
 		/* Someone was faster than us, use their priv and roll
 		 * back our's.
 		 */
 		kref_get(&priv_new->rx_kref);
 		mutex_unlock(&j1939_netdev_lock);
-		dev_put(ndev);
+		netdev_put(ndev);
 		kfree(priv);
 		return priv_new;
 	}
 	j1939_priv_set(ndev, priv);
 
@@ -296,11 +296,11 @@ struct j1939_priv *j1939_netdev_start(struct net_device *ndev)
 
  out_priv_put:
 	j1939_priv_set(ndev, NULL);
 	mutex_unlock(&j1939_netdev_lock);
 
-	dev_put(ndev);
+	netdev_put(ndev);
 	kfree(priv);
 
 	return ERR_PTR(ret);
 }
 
diff --git a/net/can/j1939/socket.c b/net/can/j1939/socket.c
index 1589e8ca634ecc2b59eb0c2a1e48f546fafccbe0..ad188a86790f269b8a9d022e67d0ef3ea8560349 100644
--- a/net/can/j1939/socket.c
+++ b/net/can/j1939/socket.c
@@ -481,30 +481,30 @@ static int j1939_sk_bind(struct socket *sock, struct sockaddr_unsized *uaddr, in
 			ret = -ENODEV;
 			goto out_release_sock;
 		}
 
 		if (ndev->reg_state != NETREG_REGISTERED) {
-			dev_put(ndev);
+			netdev_put(ndev);
 			ret = -ENODEV;
 			goto out_release_sock;
 		}
 
 		can_ml = can_get_ml_priv(ndev);
 		if (!can_ml) {
-			dev_put(ndev);
+			netdev_put(ndev);
 			ret = -ENODEV;
 			goto out_release_sock;
 		}
 
 		if (!(ndev->flags & IFF_UP)) {
-			dev_put(ndev);
+			netdev_put(ndev);
 			ret = -ENETDOWN;
 			goto out_release_sock;
 		}
 
 		priv = j1939_netdev_start(ndev);
-		dev_put(ndev);
+		netdev_put(ndev);
 		if (IS_ERR(priv)) {
 			ret = PTR_ERR(priv);
 			goto out_release_sock;
 		}
 
diff --git a/net/can/raw.c b/net/can/raw.c
index fb4f9c854df04d90ed6bd4601c616ac39bb85ad9..cf217671d9ce9419c5e32f926bf64df5f95e4a1f 100644
--- a/net/can/raw.c
+++ b/net/can/raw.c
@@ -518,11 +518,11 @@ static int raw_bind(struct socket *sock, struct sockaddr_unsized *uaddr, int len
 			netdev_hold(ro->dev, &ro->dev_tracker, GFP_KERNEL);
 	}
 
 out_put_dev:
 	/* remove potential reference from dev_get_by_index() */
-	dev_put(dev);
+	netdev_put(dev);
 out:
 	release_sock(sk);
 	rtnl_unlock();
 
 	if (notify_enetdown) {
@@ -989,21 +989,21 @@ static int raw_sendmsg(struct socket *sock, struct msghdr *msg, size_t size)
 
 	skb_setup_tx_timestamp(skb, &sockc);
 
 	err = can_send(skb, ro->loopback);
 
-	dev_put(dev);
+	netdev_put(dev);
 
 	if (err)
 		goto send_failed;
 
 	return size;
 
 free_skb:
 	kfree_skb(skb);
 put_dev:
-	dev_put(dev);
+	netdev_put(dev);
 send_failed:
 	return err;
 }
 
 static int raw_recvmsg(struct socket *sock, struct msghdr *msg, size_t size,

-- 
2.47.3

