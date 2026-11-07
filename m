From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Sat, 07 Nov 2026 01:01:07 -0600
Subject: [PATCH] staging: octeon: fix OF node and fixed-link leaks on error
 and teardown
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261107-octeon-of-node-leak-fix-v1-1-25f591fb96c5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MwQqDMBAFf0X27EKSUpX+SvGQxKculmxJRATx3
 xt6nIGZiwqyoNCruSjjkCKaKti2obj6tIBlqkzOuM5a07PGHZpYZ046gT/wG89y8vB8mBCDd86
 Aav3NqPp/fo/3/QMV9u3jaQAAAA==
X-Change-ID: 20261107-octeon-of-node-leak-fix-8530bcba220e
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794034870; l=1973;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=lmYDQNlZZJOdlY+CzSqpaOcg4733Lmg13tRX2y8DVVU=;
 b=4PQtZGe1BAjHiXkhE2ZBb+baE/oIBNyD4lAnSWDosOR+srnvSD1w5GNvd2djG75R0wvXZFzSG
 Z361PSzf9eEDoW9C0qEpepKcAdfiztmT8X+e+2Q1j3rQ7KnagcWxqtG
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cvm_oct_node_for_port() returns a device_node with an incremented
refcount, and cvm_oct_probe() may register a fixed-link PHY on that
node via of_phy_register_fixed_link(). However, neither the probe
error paths nor cvm_oct_remove_device() release the node reference or
deregister the fixed-link PHY.

Call of_phy_deregister_fixed_link() when appropriate and balance
cvm_oct_node_for_port() with of_node_put() on probe failure and device
removal.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
 drivers/staging/octeon/ethernet.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/drivers/staging/octeon/ethernet.c b/drivers/staging/octeon/ethernet.c
index 42ec4b8324a8..13df64d3f498 100644
--- a/drivers/staging/octeon/ethernet.c
+++ b/drivers/staging/octeon/ethernet.c
@@ -114,6 +114,11 @@ static void cvm_oct_remove_device(int port)
 
 		cvm_oct_tx_shutdown_dev(dev);
 		unregister_netdev(dev);
+		if (priv->of_node) {
+			if (of_phy_is_fixed_link(priv->of_node))
+				of_phy_deregister_fixed_link(priv->of_node);
+			of_node_put(priv->of_node);
+		}
 		free_netdev(dev);
 		cvm_oct_device[port] = NULL;
 	}
@@ -919,10 +924,16 @@ static int cvm_oct_probe(struct platform_device *pdev)
 			}
 
 			if (!dev->netdev_ops) {
+				of_node_put(priv->of_node);
 				free_netdev(dev);
 			} else if (register_netdev(dev) < 0) {
 				netdev_err(dev, "Failed to register ethernet device for interface %d, port %d\n",
 					   interface, priv->port);
+				if (priv->of_node) {
+					if (of_phy_is_fixed_link(priv->of_node))
+						of_phy_deregister_fixed_link(priv->of_node);
+					of_node_put(priv->of_node);
+				}
 				free_netdev(dev);
 			} else {
 				cvm_oct_device[priv->port] = dev;

---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261107-octeon-of-node-leak-fix-8530bcba220e

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

