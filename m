From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Tue, 10 Nov 2026 07:28:25 -0600
Subject: [PATCH v3] staging: octeon: fix OF node and fixed-link leaks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261110-octeon-of-node-leak-fix-v3-1-9cdd7e1d48fa@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6CMBBFr0Jm7Zi2pCiuvIdhUcoUGqFjWkI0p
 He3cgGX7yX//R0SRU8JbtUOkTafPIcC9akCO5kwEvqhMCihGinFBdmuxAHZYeCBcCbzROffeNW
 16G1vlBIEZf2KVPRRfnSFJ59Wjp/jaJM/+7+5SZSotNOtdH3bWH0fF+Pns+UFupzzF8XjBrS+A
 AAA
X-Change-ID: 20261107-octeon-of-node-leak-fix-8530bcba220e
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794317305; l=1834;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=jl1zaHvHGKs1nPczUORm41xcESZsx9ReVkyvB9xAjJ8=;
 b=wcq4qyYEf6+zZd6aBylkQJrPRqr6AWFbWWGX6sThGne0nm2+1AkoNb+krQ4VFyS0rh54QeCWz
 vVnVMZmaWxkDbrQfEthwB27z4oaDKvpe+HA7u19OHwv0vHx3yQXO28T
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Deregister fixed link and put OF node on probe failure and device removal
to prevent memory leaks.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
Oscar Alejandro Sánchez Lucero (1):
  staging: octeon: fix OF node and fixed-link leaks on error and teardown
---
Changes in v3:
- Rebase into mainline and perform cross compilation validation for MIPS64.
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

