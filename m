From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Sat, 07 Nov 2026 02:13:51 -0600
Subject: [PATCH] staging: octeon: convert from ndo_get_stats to
 ndo_get_stats64
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261107-octeon-get-stats64-v1-1-94cdedd8e9f6@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MTQqAIBBA4avErBvI7Ie6SrSwHGs2Go5EIN09a
 fkt3ssgFJkE5ipDpJuFgy9QdQX7afxByLYY2qYdlGpGDHui4PGghJJMkqFDPVltOjdtTvVQwiu
 S4+efLuv7fnJlqaZkAAAA
X-Change-ID: 20261107-octeon-get-stats64-39d3a4f9bf15
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794039231; l=5749;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=930QtnvR+WyHyNhL3+z3ix4Trio4JE/UI2vQH0/G6+I=;
 b=Qq8eUm8nI7O48uCTmo+hq1hLVmpOTKwmflK/g5TrenJCfHgJB3m08+eJwnKjmgpyN5O9tovDd
 fZyPcYqn6FaAzpVbN22AezCFHwElo2/5CU5/isHyW6G4ohRZW41kPgY
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Migrate the network device operations from the legacy ndo_get_stats
callback to ndo_get_stats64, populating the caller-provided
rtnl_link_stats64 structure via netdev_stats_to_stats64().

Update cvm_oct_periodic_worker() and cvm_oct_common_init() to avoid
calling the removed ndo_get_stats pointer directly.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
 drivers/staging/octeon/ethernet.c | 33 +++++++++++++++++----------------
 1 file changed, 17 insertions(+), 16 deletions(-)

diff --git a/drivers/staging/octeon/ethernet.c b/drivers/staging/octeon/ethernet.c
index 42ec4b8324a8..c61b1ad3f9b3 100644
--- a/drivers/staging/octeon/ethernet.c
+++ b/drivers/staging/octeon/ethernet.c
@@ -141,12 +141,12 @@ static void cvm_oct_periodic_worker(struct work_struct *work)
 	struct octeon_ethernet *priv = container_of(work,
 						    struct octeon_ethernet,
 						    port_periodic_work.work);
+	struct rtnl_link_stats64 stats;
 
 	if (priv->poll)
 		priv->poll(cvm_oct_device[priv->port]);
 
-	cvm_oct_device[priv->port]->netdev_ops->ndo_get_stats
-						(cvm_oct_device[priv->port]);
+	dev_get_stats(cvm_oct_device[priv->port], &stats);
 
 	if (!atomic_read(&cvm_oct_poll_queue_stopping))
 		schedule_delayed_work(&priv->port_periodic_work, HZ);
@@ -208,12 +208,12 @@ int cvm_oct_free_work(void *work_queue_entry)
 EXPORT_SYMBOL(cvm_oct_free_work);
 
 /**
- * cvm_oct_common_get_stats - get the low level ethernet statistics
- * @dev:    Device to get the statistics from
- *
- * Returns Pointer to the statistics
+ * cvm_oct_common_get_stats64 - get the low level ethernet statistics
+ * @dev:     Device to get the statistics from
+ * @storage: Pointer to stats64 structure to populate
  */
-static struct net_device_stats *cvm_oct_common_get_stats(struct net_device *dev)
+static void cvm_oct_common_get_stats64(struct net_device *dev,
+				       struct rtnl_link_stats64 *storage)
 {
 	struct cvmx_pip_port_status rx_status;
 	struct cvmx_pko_port_status tx_status;
@@ -239,7 +239,7 @@ static struct net_device_stats *cvm_oct_common_get_stats(struct net_device *dev)
 		dev->stats.rx_dropped += rx_status.dropped_packets;
 	}
 
-	return &dev->stats;
+	netdev_stats_to_stats64(storage, &dev->stats);
 }
 
 /**
@@ -421,6 +421,7 @@ static int cvm_oct_common_set_mac_address(struct net_device *dev, void *addr)
 int cvm_oct_common_init(struct net_device *dev)
 {
 	struct octeon_ethernet *priv = netdev_priv(dev);
+	struct rtnl_link_stats64 stats;
 	int ret;
 
 	ret = of_get_ethdev_address(priv->of_node, dev);
@@ -449,8 +450,8 @@ int cvm_oct_common_init(struct net_device *dev)
 	 * Zero out stats for port so we won't mistakenly show
 	 * counters from the bootloader.
 	 */
-	memset(dev->netdev_ops->ndo_get_stats(dev), 0,
-	       sizeof(struct net_device_stats));
+	cvm_oct_common_get_stats64(dev, &stats);
+	memset(&dev->stats, 0, sizeof(dev->stats));
 
 	if (dev->netdev_ops->ndo_stop)
 		dev->netdev_ops->ndo_stop(dev);
@@ -540,7 +541,7 @@ static const struct net_device_ops cvm_oct_npi_netdev_ops = {
 	.ndo_set_mac_address	= cvm_oct_common_set_mac_address,
 	.ndo_eth_ioctl		= cvm_oct_ioctl,
 	.ndo_change_mtu		= cvm_oct_common_change_mtu,
-	.ndo_get_stats		= cvm_oct_common_get_stats,
+	.ndo_get_stats64	= cvm_oct_common_get_stats64,
 #ifdef CONFIG_NET_POLL_CONTROLLER
 	.ndo_poll_controller	= cvm_oct_poll_controller,
 #endif
@@ -556,7 +557,7 @@ static const struct net_device_ops cvm_oct_xaui_netdev_ops = {
 	.ndo_set_mac_address	= cvm_oct_common_set_mac_address,
 	.ndo_eth_ioctl		= cvm_oct_ioctl,
 	.ndo_change_mtu		= cvm_oct_common_change_mtu,
-	.ndo_get_stats		= cvm_oct_common_get_stats,
+	.ndo_get_stats64	= cvm_oct_common_get_stats64,
 #ifdef CONFIG_NET_POLL_CONTROLLER
 	.ndo_poll_controller	= cvm_oct_poll_controller,
 #endif
@@ -572,7 +573,7 @@ static const struct net_device_ops cvm_oct_sgmii_netdev_ops = {
 	.ndo_set_mac_address	= cvm_oct_common_set_mac_address,
 	.ndo_eth_ioctl		= cvm_oct_ioctl,
 	.ndo_change_mtu		= cvm_oct_common_change_mtu,
-	.ndo_get_stats		= cvm_oct_common_get_stats,
+	.ndo_get_stats64	= cvm_oct_common_get_stats64,
 #ifdef CONFIG_NET_POLL_CONTROLLER
 	.ndo_poll_controller	= cvm_oct_poll_controller,
 #endif
@@ -586,7 +587,7 @@ static const struct net_device_ops cvm_oct_spi_netdev_ops = {
 	.ndo_set_mac_address	= cvm_oct_common_set_mac_address,
 	.ndo_eth_ioctl		= cvm_oct_ioctl,
 	.ndo_change_mtu		= cvm_oct_common_change_mtu,
-	.ndo_get_stats		= cvm_oct_common_get_stats,
+	.ndo_get_stats64	= cvm_oct_common_get_stats64,
 #ifdef CONFIG_NET_POLL_CONTROLLER
 	.ndo_poll_controller	= cvm_oct_poll_controller,
 #endif
@@ -602,7 +603,7 @@ static const struct net_device_ops cvm_oct_rgmii_netdev_ops = {
 	.ndo_set_mac_address	= cvm_oct_common_set_mac_address,
 	.ndo_eth_ioctl		= cvm_oct_ioctl,
 	.ndo_change_mtu		= cvm_oct_common_change_mtu,
-	.ndo_get_stats		= cvm_oct_common_get_stats,
+	.ndo_get_stats64	= cvm_oct_common_get_stats64,
 #ifdef CONFIG_NET_POLL_CONTROLLER
 	.ndo_poll_controller	= cvm_oct_poll_controller,
 #endif
@@ -615,7 +616,7 @@ static const struct net_device_ops cvm_oct_pow_netdev_ops = {
 	.ndo_set_mac_address	= cvm_oct_common_set_mac_address,
 	.ndo_eth_ioctl		= cvm_oct_ioctl,
 	.ndo_change_mtu		= cvm_oct_common_change_mtu,
-	.ndo_get_stats		= cvm_oct_common_get_stats,
+	.ndo_get_stats64	= cvm_oct_common_get_stats64,
 #ifdef CONFIG_NET_POLL_CONTROLLER
 	.ndo_poll_controller	= cvm_oct_poll_controller,
 #endif

---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261107-octeon-get-stats64-39d3a4f9bf15

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

