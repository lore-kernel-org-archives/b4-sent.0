From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Sun, 08 Nov 2026 05:49:01 -0600
Subject: [PATCH 2/3] staging: octeon: convert from ndo_get_stats to
 ndo_get_stats64
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261108-octeon-init-pipeline-v1-v1-2-eb2c6c956279@gmail.com>
References: <20261108-octeon-init-pipeline-v1-v1-0-eb2c6c956279@gmail.com>
In-Reply-To: <20261108-octeon-init-pipeline-v1-v1-0-eb2c6c956279@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794138540; l=5570;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=ZufJWbIWbCDXlIoq6too8A8+bhO7h13T111FxAvX1JU=;
 b=Qc+sGguk1iiCvCWxIsO+Fe28Tw+h3eeqKA5cCDoakwwdEmF/tySlv0q4eCsycE4ReXUe1mhJY
 EPutbKncRLhDOKSSni5yzxcqxWY1GsVAq4+NQpbmcpTi8FQNbRMKn98
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
index c77678cb351f..8f9dd87752d7 100644
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

-- 
2.56.0

