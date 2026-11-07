From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Sat, 07 Nov 2026 05:06:45 -0600
Subject: [PATCH 2/2] staging: octeon: fix error handling rollback in
 cvm_oct_rx_initialize()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261107-octeon-rx-fixes-v1-2-f5a21907c8af@gmail.com>
References: <20261107-octeon-rx-fixes-v1-0-f5a21907c8af@gmail.com>
In-Reply-To: <20261107-octeon-rx-fixes-v1-0-f5a21907c8af@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794049605; l=2298;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=TPVbSHB3sHyDA3wF8lgqnMhqPBLjm9lvag5J66ajxlk=;
 b=Pr+17C2d7l3bdUmXPRmXQk1ufblFAJ6K7LA8dW8gtRVw6EHgJrdUBdIFZIZIwhSmK/GjSZirW
 a4mOzJAZ9y1COZ6fLHWjLRB9FW33C4HIVtCCMNPhy+j6txQ7xy7yEhu
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If request_irq() fails during the loop in cvm_oct_rx_initialize(),
the function returns immediately without disabling and deleting the
current NAPI context or cleaning up the previously initialized RX
groups.

Add an error unwind path to disable/delete the failed NAPI instance
and tear down all previously registered RX groups in reverse order.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
 drivers/staging/octeon/ethernet-rx.c | 24 ++++++++++++++++++++----
 1 file changed, 20 insertions(+), 4 deletions(-)

diff --git a/drivers/staging/octeon/ethernet-rx.c b/drivers/staging/octeon/ethernet-rx.c
index b0463759be39..61593283ddef 100644
--- a/drivers/staging/octeon/ethernet-rx.c
+++ b/drivers/staging/octeon/ethernet-rx.c
@@ -449,7 +449,7 @@ void cvm_oct_poll_controller(struct net_device *dev)
 
 int cvm_oct_rx_initialize(struct platform_device *pdev)
 {
-	int i;
+	int i, ret;
 	struct net_device *dev_for_napi = NULL;
 	struct octeon_ethernet_platform *plat = platform_get_drvdata(pdev);
 	struct oct_rx_group *rx_group = plat->rx_group;
@@ -467,8 +467,6 @@ int cvm_oct_rx_initialize(struct platform_device *pdev)
 	}
 
 	for (i = 0; i < ARRAY_SIZE(plat->rx_group); i++) {
-		int ret;
-
 		if (!(pow_receive_groups & BIT(i)))
 			continue;
 
@@ -485,7 +483,9 @@ int cvm_oct_rx_initialize(struct platform_device *pdev)
 				  "Ethernet", &rx_group[i].napi);
 		if (ret) {
 			dev_err(&pdev->dev, "Could not acquire Ethernet IRQ %d\n", rx_group[i].irq);
-			return ret;
+			napi_disable(&rx_group[i].napi);
+			netif_napi_del(&rx_group[i].napi);
+			goto err_rollback;
 		}
 
 		disable_irq_nosync(rx_group[i].irq);
@@ -524,6 +524,22 @@ int cvm_oct_rx_initialize(struct platform_device *pdev)
 	}
 	atomic_inc(&oct_rx_ready);
 	return 0;
+
+err_rollback:
+	while (--i >= 0) {
+		if (!(pow_receive_groups & BIT(i)))
+			continue;
+
+		if (OCTEON_IS_MODEL(OCTEON_CN68XX))
+			cvmx_write_csr(CVMX_SSO_WQ_INT_THRX(i), 0);
+		else
+			cvmx_write_csr(CVMX_POW_WQ_INT_THRX(i), 0);
+
+		napi_disable(&rx_group[i].napi);
+		free_irq(rx_group[i].irq, &rx_group[i].napi);
+		netif_napi_del(&rx_group[i].napi);
+	}
+	return ret;
 }
 
 void cvm_oct_rx_shutdown(struct platform_device *pdev)

-- 
2.56.0

