From: Yusheng Zheng <yunwei356@gmail.com>
Date: Wed, 23 Sep 2026 07:12:19 +0000
Subject: [PATCH RFC net-next] net: thunderbolt: Allow per-device opt-in Tx
 E2E flow control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-tbnet-tx-e2e-ethtool-v11-v1-1-33a2ca1318f1@gmail.com>
X-B4-Tracking: v=1; b=H4sIANJ7s2oC/zWNQQrCMBREr1L+2o9tApW6FTyAW3GR1NEENJHkU
 wKldzcRnN2bYWZWykgemY7dSgmLzz6GCsOuo9mZ8AT7e2VSvRr7SWkWGyAshaHAECcxvngZBp6
 g1WGEqdJU65+Ehy+/6StdzqfmtWpAEbpVsCaDbTJhdu3hn+3fxgfati+OE7C7mwAAAA==
X-Change-ID: 20260923-tbnet-tx-e2e-ethtool-v11-9e3276eaaaa3
To: westeri@kernel.org, netdev@vger.kernel.org
Cc: YehezkelShB@gmail.com, andrew+netdev@lunn.ch, davem@davemloft.net, 
 edumazet@google.com, kuba@kernel.org, pabeni@redhat.com, 
 linux-kernel@vger.kernel.org, Yusheng Zheng <yunwei356@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790147538; l=5750;
 i=yunwei356@gmail.com; s=20260923; h=from:subject:message-id;
 bh=WCFfs7uRHtqJO4Rc0AENdaACTCDy+hKD/RkIgWiOEVQ=;
 b=Cn5vcUpyIXqFjr/PPzd+QMHLwCOiwqUII1a2980P2ccOHV8PJU0PrpO60sPw9LGxwGKUUvNv0
 /2ofEs/p9gnCiumFa7WN3UhNx/CpkvKNxWh44g7rY+6I7z9AFu1fPJ0
X-Developer-Key: i=yunwei356@gmail.com; a=ed25519;
 pk=q8tCkO/6rm59ztJyK05MIyeCgQrTPpMG7Sw0ZV7qqFo=
X-Endpoint-Received: by B4 Relay for yunwei356@gmail.com/20260923 with auth_id=1050
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit a8065af3346e ("net: thunderbolt: Enable end-to-end flow control
also in transmit") enabled E2E flow control on Tx rings. It was reverted
after an ASMedia ASM4242 accepted the configuration without returning
credits, leaving its Tx ring wedged. A separate report described similar
Tx completion wedges with multiple native E2E rings on AMD Strix Halo.
The revert kept Rx E2E and suggested a Tx opt-in for known-good
controllers.

On two Intel Meteor Lake-P NHI (8086:7ec2) hosts, the exact patch built
against their running 7.3-rc3 kernel was tested in a same-boot A/B/A run.
Each arm used a ten-second, four-stream iperf3 transfer. For lab to g485,
Tx E2E on, off, then on again produced 15.43, 15.76, and 15.18 Gbit/s,
with 0, 29113, and 0 retransmissions. G485 Rx errors rose by 5097 during
the off arm and did not rise during either on arm. In the reverse
direction,
throughput was about 19.41 Gbit/s in all three arms, with 0, 181, and 0
retransmissions; lab Rx errors rose by 14 only during the off arm.

The link was brought down and up to change the flag, so link training was
not held fixed. The result supports an integrity improvement on this pair,
not a general throughput gain or proof for other controllers. Both hosts
were returned to their distribution module after testing.

Add a per-netdev ethtool private flag named tx-e2e. It defaults to off and
can only change while the interface is down. Enabling it requires the
existing e2e module parameter. At open, the Tx ring uses E2E only if the
peer advertises TBNET_E2E. This bit proves protocol support, not working
credit return. Administrators must opt in only on controller pairs known
to return credits; a bad controller can stall Tx until the flag is
disabled.

Link: https://lore.kernel.org/netdev/20260727123002.25225-1-fy15309206903@gmail.com/
Signed-off-by: Yusheng Zheng <yunwei356@gmail.com>
---
RFC: Is a per-netdev ethtool private flag the appropriate opt-in for
controller pairs that return Tx E2E credits? TBNET_E2E from the peer
advertises protocol support, but cannot prove that its controller
returns credits. The flag defaults off and changes only while down.

The exact source built with W=1 against both hosts' 7.3-rc3 headers.
An A/B/A test on two Intel 8086:7ec2 hosts is described in the patch.
A net-next allmodconfig W=1 build was attempted but stopped on GCC 15
Werror diagnostics in unrelated files.
---
 drivers/net/thunderbolt/main.c | 60 ++++++++++++++++++++++++++++++++++++++++--
 1 file changed, 58 insertions(+), 2 deletions(-)

diff --git a/drivers/net/thunderbolt/main.c b/drivers/net/thunderbolt/main.c
index d9fb587a62c5e13b6cb8b4397e0cd31c076cec7b..b17ab8e15c1f3fea926aa95eb074a0f60123dfba 100644
--- a/drivers/net/thunderbolt/main.c
+++ b/drivers/net/thunderbolt/main.c
@@ -160,6 +160,7 @@ struct tbnet_ring {
  * @login_sent: ThunderboltIP login message successfully sent
  * @login_received: ThunderboltIP login message received from the remote
  *		    host
+ * @tx_e2e: Enable end-to-end flow control on the Tx ring
  * @local_transmit_path: HopID we are using to send out packets
  * @remote_transmit_path: HopID the other end is using to send packets to us
  * @connection_lock: Lock serializing access to @login_sent,
@@ -190,6 +191,7 @@ struct tbnet {
 	atomic_t command_id;
 	bool login_sent;
 	bool login_received;
+	bool tx_e2e;
 	int local_transmit_path;
 	int remote_transmit_path;
 	struct mutex connection_lock;
@@ -947,8 +949,12 @@ static int tbnet_open(struct net_device *dev)
 
 	netif_carrier_off(dev);
 
-	ring = tb_ring_alloc_tx(xd->tb->nhi, -1, TBNET_RING_SIZE,
-				RING_FLAG_FRAME);
+	flags = RING_FLAG_FRAME;
+	/* The peer bit advertises E2E protocol support. */
+	if (net->tx_e2e && tbnet_e2e && net->svc->prtcstns & TBNET_E2E)
+		flags |= RING_FLAG_E2E;
+
+	ring = tb_ring_alloc_tx(xd->tb->nhi, -1, TBNET_RING_SIZE, flags);
 	if (!ring) {
 		netdev_err(dev, "failed to allocate Tx ring\n");
 		return -ENOMEM;
@@ -1336,8 +1342,58 @@ static int tbnet_get_link_ksettings(struct net_device *dev,
 	return 0;
 }
 
+static const char tbnet_priv_flags[][ETH_GSTRING_LEN] = {
+#define TBNET_PRIV_FLAG_TX_E2E	BIT(0)
+	"tx-e2e",
+};
+
+static void tbnet_get_strings(struct net_device *dev, u32 stringset, u8 *data)
+{
+	if (stringset == ETH_SS_PRIV_FLAGS)
+		memcpy(data, tbnet_priv_flags, sizeof(tbnet_priv_flags));
+}
+
+static int tbnet_get_sset_count(struct net_device *dev, int sset)
+{
+	if (sset == ETH_SS_PRIV_FLAGS)
+		return ARRAY_SIZE(tbnet_priv_flags);
+
+	return -EOPNOTSUPP;
+}
+
+static u32 tbnet_get_priv_flags(struct net_device *dev)
+{
+	const struct tbnet *net = netdev_priv(dev);
+
+	return net->tx_e2e ? TBNET_PRIV_FLAG_TX_E2E : 0;
+}
+
+static int tbnet_set_priv_flags(struct net_device *dev, u32 flags)
+{
+	struct tbnet *net = netdev_priv(dev);
+	bool tx_e2e;
+
+	if (flags & ~TBNET_PRIV_FLAG_TX_E2E)
+		return -EINVAL;
+
+	tx_e2e = flags & TBNET_PRIV_FLAG_TX_E2E;
+	if (net->tx_e2e == tx_e2e)
+		return 0;
+	if (netif_running(dev))
+		return -EBUSY;
+	if (tx_e2e && !tbnet_e2e)
+		return -EOPNOTSUPP;
+
+	net->tx_e2e = tx_e2e;
+	return 0;
+}
+
 static const struct ethtool_ops tbnet_ethtool_ops = {
 	.get_link_ksettings = tbnet_get_link_ksettings,
+	.get_strings = tbnet_get_strings,
+	.get_sset_count = tbnet_get_sset_count,
+	.get_priv_flags = tbnet_get_priv_flags,
+	.set_priv_flags = tbnet_set_priv_flags,
 };
 
 static void tbnet_generate_mac(struct net_device *dev)

---
base-commit: 944ae66642b726bd6b25ae71b1e9ff88a0e0bdb0
change-id: 20260923-tbnet-tx-e2e-ethtool-v11-9e3276eaaaa3

Best regards,
-- 
Yusheng Zheng <yunwei356@gmail.com>

