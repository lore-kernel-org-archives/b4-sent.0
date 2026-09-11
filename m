From: Haseeb Malik <haseebulhaq55@gmail.com>
Date: Fri, 11 Sep 2026 19:57:21 -0400
Subject: [PATCH net] macsec: initialize SecY before registering the
 netdevice
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260911-fix-macsec-net-v1-1-c82aa58ae741@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGCVpGoC/x2MQQrCQAxFr1KyNnSmYku9irjIxIzNolEmIkLp3
 Y0u3+P9v4FLU3E4dxs0eavrwwLyoQNeyO6CeguGIQ1jmnPGqh9ciV0YTV5Y67HwSSYqiSBGzyZ
 R/A8vEAFcQxZywdLIePl9he5XUoN9/wIHzjdwgAAAAA==
To: Sabrina Dubroca <sd@queasysnail.net>
Cc: Andrew Lunn <andrew+netdev@lunn.ch>, Simon Horman <horms@kernel.org>, 
 Hangbin Liu <hangbin.liu@linux.dev>, 
 Felix Walter <felix.walter@cloudandheat.com>, netdev@vger.kernel.org, 
 syzkaller-bugs@googlegroups.com, Jakub Kicinski <kuba@kernel.org>, 
 syzbot+f2f6312ad1b5a0bfe316@syzkaller.appspotmail.com, 
 "David S. Miller" <davem@davemloft.net>, Paolo Abeni <pabeni@redhat.com>, 
 Eric Dumazet <edumazet@google.com>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789171045; l=5581;
 i=haseebulhaq55@gmail.com; s=default; h=from:subject:message-id;
 bh=KSA/709t2+4DBX9OBd6ktaJ9IHFKNEyjhqrtYtrgPRk=;
 b=FrLFoZNkqAVAf7jQS/0uFbGMIu17BznN0PwdWaGq1SToCd23aRuB6hYGqH+mVpXpzbVxTabmS
 enUsZOBgTJtBKiIxLN+NmoXcMhIT5LsIaTkofNp4wm66wc4EjNhz+9M
X-Developer-Key: i=haseebulhaq55@gmail.com; a=ed25519;
 pk=U/yCVc6cTsqDqxWLzvoONZ7DUA3EfRU+rfO9Xxo4p2w=
X-Endpoint-Received: by B4 Relay for haseebulhaq55@gmail.com/default with auth_id=1026
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Creating a MACsec device with MAC offload over an LRO-capable lower
device triggers a warning in rtmsg_ifinfo_build_skb() when IPv4
forwarding is enabled by default.

register_netdevice() invokes inetdev_init(), which disables LRO and emits
a NETDEV_FEAT_CHANGE notification. This reaches macsec_fill_info() before
macsec_add_dev() initializes the SecY. key_len is still zero, so
macsec_fill_info() returns -EMSGSIZE and trips the WARN_ON in
rtmsg_ifinfo_build_skb(), even though the skb has enough space.

Initialize the SecY and apply the new-link attributes before registration.
Move the per-CPU statistics and metadata destination allocation into
ndo_init(), and release partial allocations on failure. Keep SCI
assignment after registration because ndo_init() may inherit the lower
device's MAC address.

Fixes: ccfdec908922 ("macsec: Add support for GCM-AES-256 cipher suite")
Reported-by: syzbot+f2f6312ad1b5a0bfe316@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=f2f6312ad1b5a0bfe316
Suggested-by: Sabrina Dubroca <sd@queasysnail.net>
Link: https://lists.openwall.net/linux-kernel/2026/08/19/552
Assisted-by: LLM
Signed-off-by: Haseeb Malik <haseebulhaq55@gmail.com>
---
Tests:
  - arm64 KASAN/lockdep kernel build
  - original syzbot reproducer and reduced reproducer
  - 16 cipher/offload/forwarding combinations
  - link notifications, configuration error paths, and encrypted veth
    traffic
  - W=1 MACsec object builds with allmodconfig and allyesconfig
---
 drivers/net/macsec.c | 66 ++++++++++++++++++++++++++++------------------------
 1 file changed, 35 insertions(+), 31 deletions(-)

diff --git a/drivers/net/macsec.c b/drivers/net/macsec.c
index 6f9f3aceffaa..11207d671fb6 100644
--- a/drivers/net/macsec.c
+++ b/drivers/net/macsec.c
@@ -3539,6 +3539,20 @@ static int macsec_dev_init(struct net_device *dev)
 	if (err)
 		return err;
 
+	err = -ENOMEM;
+	macsec->stats = netdev_alloc_pcpu_stats(struct pcpu_secy_stats);
+	if (!macsec->stats)
+		goto destroy_gro_cells;
+
+	macsec->secy.tx_sc.stats = netdev_alloc_pcpu_stats(struct pcpu_tx_sc_stats);
+	if (!macsec->secy.tx_sc.stats)
+		goto free_secy_stats;
+
+	macsec->secy.tx_sc.md_dst = metadata_dst_alloc(0, METADATA_MACSEC,
+						       GFP_KERNEL);
+	if (!macsec->secy.tx_sc.md_dst)
+		goto free_tx_sc_stats;
+
 	macsec_inherit_tso_max(dev);
 
 	dev->hw_features = real_dev->hw_features & MACSEC_OFFLOAD_FEATURES;
@@ -3560,6 +3574,14 @@ static int macsec_dev_init(struct net_device *dev)
 	netdev_hold(real_dev, &macsec->dev_tracker, GFP_KERNEL);
 
 	return 0;
+
+free_tx_sc_stats:
+	free_percpu(macsec->secy.tx_sc.stats);
+free_secy_stats:
+	free_percpu(macsec->stats);
+destroy_gro_cells:
+	gro_cells_destroy(&macsec->gro_cells);
+	return err;
 }
 
 static void macsec_dev_uninit(struct net_device *dev)
@@ -4116,29 +4138,11 @@ static sci_t dev_to_sci(struct net_device *dev, __be16 port)
 	return make_sci(dev->dev_addr, port);
 }
 
-static int macsec_add_dev(struct net_device *dev, sci_t sci, u8 icv_len)
+static void macsec_init_secy(struct net_device *dev, u8 icv_len)
 {
 	struct macsec_dev *macsec = macsec_priv(dev);
 	struct macsec_secy *secy = &macsec->secy;
 
-	macsec->stats = netdev_alloc_pcpu_stats(struct pcpu_secy_stats);
-	if (!macsec->stats)
-		return -ENOMEM;
-
-	secy->tx_sc.stats = netdev_alloc_pcpu_stats(struct pcpu_tx_sc_stats);
-	if (!secy->tx_sc.stats)
-		return -ENOMEM;
-
-	secy->tx_sc.md_dst = metadata_dst_alloc(0, METADATA_MACSEC, GFP_KERNEL);
-	if (!secy->tx_sc.md_dst)
-		/* macsec and secy percpu stats will be freed when unregistering
-		 * net_device in macsec_free_netdev()
-		 */
-		return -ENOMEM;
-
-	if (sci == MACSEC_UNDEF_SCI)
-		sci = dev_to_sci(dev, MACSEC_PORT_ES);
-
 	secy->netdev = dev;
 	secy->operational = true;
 	secy->key_len = DEFAULT_SAK_LEN;
@@ -4148,16 +4152,12 @@ static int macsec_add_dev(struct net_device *dev, sci_t sci, u8 icv_len)
 	secy->replay_protect = false;
 	secy->xpn = DEFAULT_XPN;
 
-	secy->sci = sci;
-	secy->tx_sc.md_dst->u.macsec_info.sci = sci;
 	secy->tx_sc.active = true;
 	secy->tx_sc.encoding_sa = DEFAULT_ENCODING_SA;
 	secy->tx_sc.encrypt = DEFAULT_ENCRYPT;
 	secy->tx_sc.send_sci = DEFAULT_SEND_SCI;
 	secy->tx_sc.end_station = false;
 	secy->tx_sc.scb = false;
-
-	return 0;
 }
 
 static struct lock_class_key macsec_netdev_addr_lock_key;
@@ -4220,6 +4220,14 @@ static int macsec_newlink(struct net_device *dev,
 	if (rx_handler && rx_handler != macsec_handle_frame)
 		return -EBUSY;
 
+	/* Registration can notify listeners before returning. */
+	macsec_init_secy(dev, icv_len);
+	if (data) {
+		err = macsec_changelink_common(dev, data);
+		if (err)
+			return err;
+	}
+
 	err = register_netdevice(dev);
 	if (err < 0)
 		return err;
@@ -4247,15 +4255,11 @@ static int macsec_newlink(struct net_device *dev,
 		goto unlink;
 	}
 
-	err = macsec_add_dev(dev, sci, icv_len);
-	if (err)
-		goto unlink;
+	if (sci == MACSEC_UNDEF_SCI)
+		sci = dev_to_sci(dev, MACSEC_PORT_ES);
 
-	if (data) {
-		err = macsec_changelink_common(dev, data);
-		if (err)
-			goto del_dev;
-	}
+	macsec->secy.sci = sci;
+	macsec->secy.tx_sc.md_dst->u.macsec_info.sci = sci;
 
 	/* If h/w offloading is available, propagate to the device */
 	if (macsec_is_offloaded(macsec)) {

---
base-commit: 78445023439506ebd83b86d40b1e428a3b309d4a
change-id: 20260911-fix-macsec-net-ff3bc5e7ab0a

Best regards,
-- 
Haseeb Malik <haseebulhaq55@gmail.com>

