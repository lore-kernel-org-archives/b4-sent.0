From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Sat, 07 Nov 2026 20:07:57 -0600
Subject: [PATCH 3/4] staging: octeon: fix race condition and log macro in
 ethernet-rgmii.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261107-octeon-phy-series-v2-v1-3-d7ab0b4b3f17@gmail.com>
References: <20261107-octeon-phy-series-v2-v1-0-d7ab0b4b3f17@gmail.com>
In-Reply-To: <20261107-octeon-phy-series-v2-v1-0-d7ab0b4b3f17@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794103676; l=2398;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=c7IDkn8SsaMFf7JTubke6cF4FA0eUXNFWJMVYKLJlz0=;
 b=ejVMpeDFts9z8ypXvJWKWYaHqkpq0YIfv9Q8umP+IaHJxqu4hUOEtrazb1kEeFyz+ApFr1osg
 J3t7W19oEB9DaUS22iRxqcRrK3GyDtTuLs4/JzZcabMvUMd+/esigxA
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix a race condition in cvm_oct_check_preamble_errors() by moving the
read assignment of priv->link_info inside the global_register_lock
protected critical section. This prevents unsynchronized read-accesses
concurring with status mutations from concurrent polling contexts.

Additionally, modernize the message output by replacing the obsolete
printk_ratelimited() call with netdev_notice_ratelimited().

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
 drivers/staging/octeon/ethernet-rgmii.c | 12 +++++-------
 1 file changed, 5 insertions(+), 7 deletions(-)

diff --git a/drivers/staging/octeon/ethernet-rgmii.c b/drivers/staging/octeon/ethernet-rgmii.c
index 0c4fac31540a..a9a245b5580a 100644
--- a/drivers/staging/octeon/ethernet-rgmii.c
+++ b/drivers/staging/octeon/ethernet-rgmii.c
@@ -9,8 +9,6 @@
 #include <linux/netdevice.h>
 #include <linux/interrupt.h>
 #include <linux/phy.h>
-#include <linux/ratelimit.h>
-#include <net/dst.h>
 
 #include "octeon-ethernet.h"
 #include "ethernet-defines.h"
@@ -56,14 +54,14 @@ static void cvm_oct_check_preamble_errors(struct net_device *dev)
 	union cvmx_helper_link_info link_info;
 	unsigned long flags;
 
-	link_info.u64 = priv->link_info;
-
 	/*
 	 * Take the global register lock since we are going to
 	 * touch registers that affect more than one port.
 	 */
 	spin_lock_irqsave(&global_register_lock, flags);
 
+	link_info.u64 = priv->link_info;
+
 	if (link_info.s.speed == 10 && priv->last_speed == 10) {
 		/*
 		 * Read the GMXX_RXX_INT_REG[PCTERR] bit and see if we are
@@ -74,7 +72,7 @@ static void cvm_oct_check_preamble_errors(struct net_device *dev)
 		union cvmx_gmxx_rxx_int_reg gmxx_rxx_int_reg;
 
 		gmxx_rxx_int_reg.u64 = cvmx_read_csr(CVMX_GMXX_RXX_INT_REG
-							(index, interface));
+		(index, interface));
 		if (gmxx_rxx_int_reg.s.pcterr) {
 			/*
 			 * We are getting preamble errors at 10Mbps. Most
@@ -83,8 +81,8 @@ static void cvm_oct_check_preamble_errors(struct net_device *dev)
 			 * disable preamble checking and do it in software.
 			 */
 			cvm_oct_set_hw_preamble(priv, false);
-			printk_ratelimited("%s: Using 10Mbps with software preamble removal\n",
-					   dev->name);
+			net_notice_ratelimited("%s: Using 10Mbps with software preamble removal\n",
+					       dev->name);
 		}
 	} else {
 		/*

-- 
2.56.0

