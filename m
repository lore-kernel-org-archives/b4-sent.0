From: Haseeb Malik <haseebulhaq55@gmail.com>
Date: Fri, 18 Sep 2026 15:01:29 -0400
Subject: [PATCH net v2] macsec: initialize SecY before registering the
 netdevice
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-fix-macsec-net-v2-1-784203ec4836@gmail.com>
X-B4-Tracking: v=1; b=H4sIAIiKrWoC/3WNwQ6CMBBEf4Xs2VVaRcCT/2E4bNcFmkgxLSEaw
 r+7cPc4kzdvFkgSvSS4ZQtEmX3yY9BgDxlwT6ET9E/NYHN7zWtjsPUfHIiTMAaZsG3PjgspyeU
 EOnpHUWIXPkABaLR0lARdpMD95tL6NJAPG9/7NI3xu//PZl/9u5oNGuTKEhUVSXkx904tryOPA
 zTruv4ABmU0vswAAAA=
To: sd@queasysnail.net
Cc: felix.walter@cloudandheat.com, edumazet@google.com, 
 linux-kernel@vger.kernel.org, andrew+netdev@lunn.ch, hangbin.liu@linux.dev, 
 kuba@kernel.org, netdev@vger.kernel.org, pabeni@redhat.com, 
 horms@kernel.org, davem@davemloft.net, syzkaller-bugs@googlegroups.com, 
 syzbot+f2f6312ad1b5a0bfe316@syzkaller.appspotmail.com, 
 Haseeb Malik <haseebulhaq55@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789758088; l=6548;
 i=haseebulhaq55@gmail.com; s=default; h=from:subject:message-id;
 bh=Ofpz92fyDetbB9sI3s9Y5WrVdHLm9pvDMHak9KjjLSU=;
 b=vNEEA34fqIpmcmaFFh0Asy9wQ4Q84rQJOhdwEstm8Leuu2iJIw3J4W81K0RM3qV87ut3aRj7H
 68rvFSiHG9EA0l/icu0sw+dW67WNPJfO9vARQ3W6HCchTXpzlGnYT+m
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
Move MAC address inheritance into macsec_newlink() so the SCI can also be
initialized before registration-time notifications report it. Move the
per-CPU statistics and metadata destination allocation into ndo_init(),
and release partial allocations on failure.

Fixes: ccfdec908922 ("macsec: Add support for GCM-AES-256 cipher suite")
Reported-by: syzbot+f2f6312ad1b5a0bfe316@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=f2f6312ad1b5a0bfe316
Suggested-by: Sabrina Dubroca <sd@queasysnail.net>
Link: https://lists.openwall.net/linux-kernel/2026/08/19/552
Signed-off-by: Haseeb Malik <haseebulhaq55@gmail.com>
---
Changes in v2:
- Initialize the SCI before registration, including MAC address inheritance,
  so registration-time notifications carry the configured SCI.
- Wrap the per-CPU statistics allocation at 80 columns.
- Link to v1: https://lore.kernel.org/netdev/20260911-fix-macsec-net-v1-1-c82aa58ae741@gmail.com/
---
 drivers/net/macsec.c | 84 +++++++++++++++++++++++++++-------------------------
 1 file changed, 43 insertions(+), 41 deletions(-)

diff --git a/drivers/net/macsec.c b/drivers/net/macsec.c
index 6f9f3aceffaa..78a19b134632 100644
--- a/drivers/net/macsec.c
+++ b/drivers/net/macsec.c
@@ -3539,6 +3539,22 @@ static int macsec_dev_init(struct net_device *dev)
 	if (err)
 		return err;
 
+	err = -ENOMEM;
+	macsec->stats = netdev_alloc_pcpu_stats(struct pcpu_secy_stats);
+	if (!macsec->stats)
+		goto destroy_gro_cells;
+
+	macsec->secy.tx_sc.stats =
+		netdev_alloc_pcpu_stats(struct pcpu_tx_sc_stats);
+	if (!macsec->secy.tx_sc.stats)
+		goto free_secy_stats;
+
+	macsec->secy.tx_sc.md_dst = metadata_dst_alloc(0, METADATA_MACSEC,
+						       GFP_KERNEL);
+	if (!macsec->secy.tx_sc.md_dst)
+		goto free_tx_sc_stats;
+	macsec->secy.tx_sc.md_dst->u.macsec_info.sci = macsec->secy.sci;
+
 	macsec_inherit_tso_max(dev);
 
 	dev->hw_features = real_dev->hw_features & MACSEC_OFFLOAD_FEATURES;
@@ -3551,8 +3567,6 @@ static int macsec_dev_init(struct net_device *dev)
 
 	macsec_set_head_tail_room(dev);
 
-	if (is_zero_ether_addr(dev->dev_addr))
-		eth_hw_addr_inherit(dev, real_dev);
 	if (is_zero_ether_addr(dev->broadcast))
 		memcpy(dev->broadcast, real_dev->broadcast, dev->addr_len);
 
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
@@ -4116,26 +4138,11 @@ static sci_t dev_to_sci(struct net_device *dev, __be16 port)
 	return make_sci(dev->dev_addr, port);
 }
 
-static int macsec_add_dev(struct net_device *dev, sci_t sci, u8 icv_len)
+static void macsec_init_secy(struct net_device *dev, sci_t sci, u8 icv_len)
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
 	if (sci == MACSEC_UNDEF_SCI)
 		sci = dev_to_sci(dev, MACSEC_PORT_ES);
 
@@ -4149,15 +4156,12 @@ static int macsec_add_dev(struct net_device *dev, sci_t sci, u8 icv_len)
 	secy->xpn = DEFAULT_XPN;
 
 	secy->sci = sci;
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
@@ -4220,6 +4224,24 @@ static int macsec_newlink(struct net_device *dev,
 	if (rx_handler && rx_handler != macsec_handle_frame)
 		return -EBUSY;
 
+	if (is_zero_ether_addr(dev->dev_addr))
+		eth_hw_addr_inherit(dev, real_dev);
+
+	if (data && data[IFLA_MACSEC_SCI])
+		sci = nla_get_sci(data[IFLA_MACSEC_SCI]);
+	else if (data && data[IFLA_MACSEC_PORT])
+		sci = dev_to_sci(dev, nla_get_be16(data[IFLA_MACSEC_PORT]));
+	else
+		sci = dev_to_sci(dev, MACSEC_PORT_ES);
+
+	/* Registration can notify listeners before returning. */
+	macsec_init_secy(dev, sci, icv_len);
+	if (data) {
+		err = macsec_changelink_common(dev, data);
+		if (err)
+			return err;
+	}
+
 	err = register_netdevice(dev);
 	if (err < 0)
 		return err;
@@ -4232,31 +4254,11 @@ static int macsec_newlink(struct net_device *dev,
 	if (err < 0)
 		goto unregister;
 
-	/* need to be already registered so that ->init has run and
-	 * the MAC addr is set
-	 */
-	if (data && data[IFLA_MACSEC_SCI])
-		sci = nla_get_sci(data[IFLA_MACSEC_SCI]);
-	else if (data && data[IFLA_MACSEC_PORT])
-		sci = dev_to_sci(dev, nla_get_be16(data[IFLA_MACSEC_PORT]));
-	else
-		sci = dev_to_sci(dev, MACSEC_PORT_ES);
-
 	if (rx_handler && sci_exists(real_dev, sci)) {
 		err = -EBUSY;
 		goto unlink;
 	}
 
-	err = macsec_add_dev(dev, sci, icv_len);
-	if (err)
-		goto unlink;
-
-	if (data) {
-		err = macsec_changelink_common(dev, data);
-		if (err)
-			goto del_dev;
-	}
-
 	/* If h/w offloading is available, propagate to the device */
 	if (macsec_is_offloaded(macsec)) {
 		const struct macsec_ops *ops;

---
base-commit: 78445023439506ebd83b86d40b1e428a3b309d4a
change-id: 20260911-fix-macsec-net-ff3bc5e7ab0a

Best regards,
-- 
Haseeb Malik <haseebulhaq55@gmail.com>

