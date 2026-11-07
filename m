From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Sat, 07 Nov 2026 01:23:20 -0600
Subject: [PATCH] staging: octeon: disable PKO before device removal in
 probe error path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261107-b4-octeon-pko-disable-fix-v1-1-4e54658fe34c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvyJ7biE1ivpKdNDcailUNCKI/p50n
 IGZBzIlpgyDeCDRxZmDLyArAfNm/ErIrjCoWrVS1h3aBsN8UvAY94COs7EH4cI3ttbprl9IqV5
 D6WOiov/3OL3vB4BIYq9rAAAA
X-Change-ID: 20261107-b4-octeon-pko-disable-fix-6bd379fe2293
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794036201; l=1196;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=b3Y2ZMJCrAoNlfMwA4dOrqbA/Tfy/ykkFc+b2losdKw=;
 b=/L3VOJAE8nIX9C52Qe5AJ9uDS6HP2vkFj/DStKXHsPW2ZKyaLUed1dslfz0Tb0DCYI6eBbGBu
 fU9/FZdydDiCPZzlM3Hln4Bh0hfS5yr5ADuf9I7iCQGNpLYWDHAQbag
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cvm_oct_remove() calls cvmx_pko_disable() before removing devices and
shutting down PKO, ensuring packet output is halted while transmit
queues are torn down. However, the err_tx error path in cvm_oct_probe()
omits cvmx_pko_disable().

Add cvmx_pko_disable() to the probe error path to match the teardown
sequence in cvm_oct_remove().

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
 drivers/staging/octeon/ethernet.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/staging/octeon/ethernet.c b/drivers/staging/octeon/ethernet.c
index 42ec4b8324a8..c77678cb351f 100644
--- a/drivers/staging/octeon/ethernet.c
+++ b/drivers/staging/octeon/ethernet.c
@@ -959,6 +959,8 @@ static int cvm_oct_probe(struct platform_device *pdev)
 
 	atomic_inc_return(&cvm_oct_poll_queue_stopping);
 
+	cvmx_pko_disable();
+
 	/* Free the ethernet devices */
 	for (int port = 0; port < TOTAL_NUMBER_OF_PORTS; port++)
 		cvm_oct_remove_device(port);

---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261107-b4-octeon-pko-disable-fix-6bd379fe2293

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

