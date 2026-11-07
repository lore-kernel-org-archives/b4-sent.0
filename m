From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Sat, 07 Nov 2026 05:28:40 -0600
Subject: [PATCH 1/2] staging: octeon: fix return type and void arithmetic
 in cvm_oct_xmit_pow()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261107-octeon-tx-fixes-v1-1-db03f73a6e6f@gmail.com>
References: <20261107-octeon-tx-fixes-v1-0-db03f73a6e6f@gmail.com>
In-Reply-To: <20261107-octeon-tx-fixes-v1-0-db03f73a6e6f@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794050920; l=1936;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=uv0ajB/v7UJ7qTX2q5slJYpaa4Ctj3c6fam5AwUuhec=;
 b=kN3EdoAHkeBaPGbtyCSYiHdNHJq+zHf4O/qvNIHN/mxnlEgt8pN18didbY8zff3ueC41Fj5cU
 mDq1W1/GR3VDGyqAARRP4XkeAi/o2yJJNxlxKazFusof4WQmysRTr4i
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cvm_oct_xmit_pow() returns netdev_tx_t, but currently uses naked '0'
constants instead of the symbolic NETDEV_TX_OK value defined by the
networking stack. Replace these with NETDEV_TX_OK.

Additionally, arithmetic on void pointers is a non-standard GCC
extension. Change packet_buffer and copy_location from void * to u8 *
to avoid -Wpointer-arith warnings.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
 drivers/staging/octeon/ethernet-tx.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/drivers/staging/octeon/ethernet-tx.c b/drivers/staging/octeon/ethernet-tx.c
index 5e536827f87a..13a205648f8b 100644
--- a/drivers/staging/octeon/ethernet-tx.c
+++ b/drivers/staging/octeon/ethernet-tx.c
@@ -505,8 +505,8 @@ netdev_tx_t cvm_oct_xmit(struct sk_buff *skb, struct net_device *dev)
 netdev_tx_t cvm_oct_xmit_pow(struct sk_buff *skb, struct net_device *dev)
 {
 	struct octeon_ethernet *priv = netdev_priv(dev);
-	void *packet_buffer;
-	void *copy_location;
+	u8 *packet_buffer;
+	u8 *copy_location;
 
 	/* Get a work queue entry */
 	struct cvmx_wqe *work = cvmx_fpa_alloc(CVMX_FPA_WQE_POOL);
@@ -516,7 +516,7 @@ netdev_tx_t cvm_oct_xmit_pow(struct sk_buff *skb, struct net_device *dev)
 				   dev->name);
 		dev->stats.tx_dropped++;
 		dev_kfree_skb_any(skb);
-		return 0;
+		return NETDEV_TX_OK;
 	}
 
 	/* Get a packet buffer */
@@ -527,7 +527,7 @@ netdev_tx_t cvm_oct_xmit_pow(struct sk_buff *skb, struct net_device *dev)
 		cvmx_fpa_free(work, CVMX_FPA_WQE_POOL, 1);
 		dev->stats.tx_dropped++;
 		dev_kfree_skb_any(skb);
-		return 0;
+		return NETDEV_TX_OK;
 	}
 
 	/*
@@ -605,7 +605,7 @@ netdev_tx_t cvm_oct_xmit_pow(struct sk_buff *skb, struct net_device *dev)
 	dev->stats.tx_packets++;
 	dev->stats.tx_bytes += skb->len;
 	dev_consume_skb_any(skb);
-	return 0;
+	return NETDEV_TX_OK;
 }
 
 /**

-- 
2.56.0

