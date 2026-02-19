From: Oliver Hartkopp <socketcan@hartkopp.net>
Date: Thu, 19 Feb 2026 17:51:19 +0100
Subject: [PATCH v3 3/3] can: statistics: add missing atomic access in hot
 path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260219-bcm_spin_lock_init-v3-3-c61026740d7b@hartkopp.net>
References: <20260219-bcm_spin_lock_init-v3-0-c61026740d7b@hartkopp.net>
In-Reply-To: <20260219-bcm_spin_lock_init-v3-0-c61026740d7b@hartkopp.net>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 "David S. Miller" <davem@davemloft.net>, 
 Urs Thuermann <urs.thuermann@volkswagen.de>, 
 Vincent Mailhol <mailhol@kernel.org>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Oliver Hartkopp <socketcan@hartkopp.net>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771519907; l=1840;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=ce7R8+1V1nd+aDx9P0nYxydlLO4gPk56OeKnN14t8O4=;
 b=NI/Zlcw/wCHgSJq9WwYK+uKaDdwN14qJIYw5kqLk0kNHqzTrxm8XvQKSCjFB8zJ9covPS5WHC
 /sU+xTvn5moD1gQqVmrLSWS5mb+oet2z7PmhEIxmXoJ/bW+RIrhnnpP
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 80b5f90158d1 ("can: statistics: use atomic access in hot path")
fixed a KCSAN issue in can_receive() but missed to convert the 'matches'
variable used in can_rcv_filter().

Fixes: 80b5f90158d1 ("can: statistics: use atomic access in hot path")
Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
 net/can/af_can.c | 4 ++--
 net/can/af_can.h | 2 +-
 2 files changed, 3 insertions(+), 3 deletions(-)

diff --git a/net/can/af_can.c b/net/can/af_can.c
index 22c65a014861..31a5eab3fab3 100644
--- a/net/can/af_can.c
+++ b/net/can/af_can.c
@@ -467,11 +467,11 @@ int can_rx_register(struct net *net, struct net_device *dev, canid_t can_id,
 	dev_rcv_lists = can_dev_rcv_lists_find(net, dev);
 	rcv_list = can_rcv_list_find(&can_id, &mask, dev_rcv_lists);
 
 	rcv->can_id = can_id;
 	rcv->mask = mask;
-	rcv->matches = 0;
+	atomic_long_set(&rcv->matches, 0);
 	rcv->func = func;
 	rcv->data = data;
 	rcv->ident = ident;
 	rcv->sk = sk;
 
@@ -571,11 +571,11 @@ void can_rx_unregister(struct net *net, struct net_device *dev, canid_t can_id,
 EXPORT_SYMBOL(can_rx_unregister);
 
 static inline void deliver(struct sk_buff *skb, struct receiver *rcv)
 {
 	rcv->func(skb, rcv->data);
-	rcv->matches++;
+	atomic_long_inc(&rcv->matches);
 }
 
 static int can_rcv_filter(struct can_dev_rcv_lists *dev_rcv_lists, struct sk_buff *skb)
 {
 	struct receiver *rcv;
diff --git a/net/can/af_can.h b/net/can/af_can.h
index 22f3352c77fe..87887014f562 100644
--- a/net/can/af_can.h
+++ b/net/can/af_can.h
@@ -50,11 +50,11 @@
 
 struct receiver {
 	struct hlist_node list;
 	canid_t can_id;
 	canid_t mask;
-	unsigned long matches;
+	atomic_long_t matches;
 	void (*func)(struct sk_buff *skb, void *data);
 	void *data;
 	char *ident;
 	struct sock *sk;
 	struct rcu_head rcu;

-- 
2.51.0

