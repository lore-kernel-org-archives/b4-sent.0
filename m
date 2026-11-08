From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Sun, 08 Nov 2026 06:19:54 -0600
Subject: [PATCH] staging: octeon: remove unnecessary parentheses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261108-octeon-parentheses-cleanup-v1-v1-1-5cb0e33e408b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqDMBAF0KvIrDvgGFtKr1K6COlXB8okZKwI4
 t0bunybd5CjKpwe3UEVm7pma5BLR2mJNoP13UxDP9xE+jvntCIbl1hh6wKHc/og2rfwJpxkCiF
 c4ygCakepmHT//8/Xef4AbAZM8G8AAAA=
X-Change-ID: 20261108-octeon-parentheses-cleanup-v1-c1f3335a411e
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794140395; l=2579;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=45TA3tH14jQOLZIxqvC60w5pZsW++bfpzW50OY9RC5Q=;
 b=SVzMOdmrV9F9P1MobY4hqTP0n3zxuwDxmgvSwtFQe55wZOpDKdnzqjd0TgqUayMxGn5KGoi4g
 K2S4HrzjC4xCfypSWcacGUaABQlbyQoQhHAm/4HtgakmFQWzv+ocaU9
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove unnecessary parentheses around conditional expressions in
ethernet.c to satisfy checkpatch.pl --strict warnings.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
This single patch cleans up minor checkpatch.pl styling warnings within the core 
ethernet logic of the Cavium Octeon staging driver.

1. Remove redundant parentheses around conditional checks inside 
   cvm_oct_common_change_mtu, cvm_oct_common_set_multicast_list, and 
   cvm_oct_set_mac_filter.

Oscar Alejandro Sánchez Lucero (1):
  staging: octeon: remove unnecessary parentheses
---
 drivers/staging/octeon/ethernet.c | 18 +++++++++---------
 1 file changed, 9 insertions(+), 9 deletions(-)

diff --git a/drivers/staging/octeon/ethernet.c b/drivers/staging/octeon/ethernet.c
index 42ec4b8324a8..f374fdf8f7a9 100644
--- a/drivers/staging/octeon/ethernet.c
+++ b/drivers/staging/octeon/ethernet.c
@@ -262,9 +262,9 @@ static int cvm_oct_common_change_mtu(struct net_device *dev, int new_mtu)
 
 	dev->mtu = new_mtu;
 
-	if ((interface < 2) &&
-	    (cvmx_helper_interface_get_mode(interface) !=
-		CVMX_HELPER_INTERFACE_MODE_SPI)) {
+	if (interface < 2 &&
+	    cvmx_helper_interface_get_mode(interface) !=
+		CVMX_HELPER_INTERFACE_MODE_SPI) {
 		int index = INDEX(priv->port);
 		/* Add ethernet header and FCS, and VLAN if configured. */
 		int max_packet = new_mtu + mtu_overhead;
@@ -308,9 +308,9 @@ static void cvm_oct_common_set_multicast_list(struct net_device *dev)
 	struct octeon_ethernet *priv = netdev_priv(dev);
 	int interface = INTERFACE(priv->port);
 
-	if ((interface < 2) &&
-	    (cvmx_helper_interface_get_mode(interface) !=
-		CVMX_HELPER_INTERFACE_MODE_SPI)) {
+	if (interface < 2 &&
+	    cvmx_helper_interface_get_mode(interface) !=
+		CVMX_HELPER_INTERFACE_MODE_SPI) {
 		union cvmx_gmxx_rxx_adr_ctl control;
 		int index = INDEX(priv->port);
 
@@ -360,9 +360,9 @@ static int cvm_oct_set_mac_filter(struct net_device *dev)
 	union cvmx_gmxx_prtx_cfg gmx_cfg;
 	int interface = INTERFACE(priv->port);
 
-	if ((interface < 2) &&
-	    (cvmx_helper_interface_get_mode(interface) !=
-		CVMX_HELPER_INTERFACE_MODE_SPI)) {
+	if (interface < 2 &&
+	    cvmx_helper_interface_get_mode(interface) !=
+		CVMX_HELPER_INTERFACE_MODE_SPI) {
 		int i;
 		const u8 *ptr = dev->dev_addr;
 		u64 mac = 0;

---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261108-octeon-parentheses-cleanup-v1-c1f3335a411e

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

