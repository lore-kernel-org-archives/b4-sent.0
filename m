From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Wed, 11 Nov 2026 21:48:32 -0600
Subject: [PATCH v4 1/2] staging: octeon: disable PKO before device removal
 in probe error path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261111-octeon-init-pipeline-v1-v4-1-5b4f8e613ae1@gmail.com>
References: <20261111-octeon-init-pipeline-v1-v4-0-5b4f8e613ae1@gmail.com>
In-Reply-To: <20261111-octeon-init-pipeline-v1-v4-0-5b4f8e613ae1@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794455321; l=895;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=VKtuoP+mIA1EKBGbewR+SjFHAmuHlZPHPWfuOFozPpc=;
 b=F1Mnp1QMroNoVn8WzCbauFa49XqfvyXkl0iE1Y5QLr0PV+0/Qws99GuZRBZcml1OTMSXafk8y
 y3rX/5VUCFbCMQ5JR5IHS5sga9AUuX2MX63rAY/a/CC+BIvDIWEClzO
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cvm_oct_remove() calls cvmx_pko_disable() before removing devices and
shutting down PKO. The err_tx error path in cvm_oct_probe() omits this
call.

Add cvmx_pko_disable() to the probe error path to match cvm_oct_remove().

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

