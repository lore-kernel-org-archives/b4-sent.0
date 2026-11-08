From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Sun, 08 Nov 2026 05:49:00 -0600
Subject: [PATCH 1/3] staging: octeon: disable PKO before device removal in
 probe error path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261108-octeon-init-pipeline-v1-v1-1-eb2c6c956279@gmail.com>
References: <20261108-octeon-init-pipeline-v1-v1-0-eb2c6c956279@gmail.com>
In-Reply-To: <20261108-octeon-init-pipeline-v1-v1-0-eb2c6c956279@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794138540; l=1010;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=bnCCa80lVs0HLakBz4verCJAnPDyaR10DCOqQwojMpc=;
 b=1WJJRfeSlB7bz0aFgNI9j2iRZTdXEJ7ml2KCln7NMRdzVv6gDrzBu7MaqYVkWFHW2l72cjjHJ
 nxCgPTxFmtXBsLus3+0YqfV1YtI0Xv2MIOaqsYABoAsrLm7uuaKXcL3
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

-- 
2.56.0

