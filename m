From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Wed, 11 Nov 2026 17:00:53 -0600
Subject: [PATCH v3] staging: octeon: clean up RX groups on request_irq()
 failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261111-octeon-rx-fixes-v3-1-a0f0dc40460f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNwQqDMBBEf0X23C1JWo321P8oHkJcdaEaSSRYx
 H/v1nuPb4Y3s0OiyJTgUewQKXPiMAvcLgX40c0DIXfCYJSptFYWg18pzBg37HmjhN29s5W0Ze0
 bEGuJdBYivVrhkdMa4uc8yPqX/t/KGhX2pTO6UdbXrn8Ok+P31YcJ2uM4voSf2D+uAAAA
X-Change-ID: 20261107-octeon-rx-fixes-d4d7620258c9
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794438054; l=2648;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=feZBSqgjCCOTQMrEkcv/uvbFiG3VcgYBGhrXWs8srLQ=;
 b=dclUB8kWbnACr8T1uS6cXq5hVmi5AKo9LW48Mi0iRMaNRx7OG9x8+K/OTmUHXaLeVBd0PbgzI
 G9P6yol3+wcDKmOkPy8yrhoZhIgCDmlb9lJvfxV/PCVhrDppGnME5OU
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If request_irq() fails in cvm_oct_rx_initialize(), the function returns
early without removing the current NAPI context or freeing the IRQs and
NAPI instances from earlier iterations.

Clean up the failed NAPI context and release the previously registered
RX groups in the error path.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
Oscar Alejandro Sánchez Lucero (1):
  staging: octeon: clean up RX groups on request_irq() failure
---
Changes in v3:
- Drop the void pointer arithmetic patch.
- Clarify commit message and validate MIPS64 cross-compilation.
---
 drivers/staging/octeon/ethernet-rx.c | 24 ++++++++++++++++++++----
 1 file changed, 20 insertions(+), 4 deletions(-)

diff --git a/drivers/staging/octeon/ethernet-rx.c b/drivers/staging/octeon/ethernet-rx.c
index 5be43bbf6a1d..f3d2a764d920 100644
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

---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261107-octeon-rx-fixes-d4d7620258c9

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

