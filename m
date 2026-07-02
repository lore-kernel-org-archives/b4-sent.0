From: Christian Taedcke <christian.taedcke@weidmueller.com>
Date: Thu, 02 Jul 2026 17:28:03 +0200
Subject: [PATCH v2] dmaengine: nbpfaxi: Fix setting channel irqs in probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260702-upstreaming-nbpfaxi-v1-v2-1-e6d6b178a278@weidmueller.com>
X-B4-Tracking: v=1; b=H4sIAIKDRmoC/4WNQQqDMBREryJ/3ZQYqw1deY/iIsYf/UUTSdRax
 Ls32gMUZvNgZt4GAT1hgEeygceFAjkbQVwS0J2yLTJqIoPgouB3Ltg8hsmjGsi2zNajUSuxJWU
 8K26Y5bkyMoc4Hj0aWs/jZ/XjMNcv1NPxdjQ6CpPzn9O8pEfvryQmZaaRqKTMuEZVvpGaYca+R
 3/VboBq3/cvNKXPpdQAAAA=
X-Change-ID: 20260702-upstreaming-nbpfaxi-v1-0364e355af85
To: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>, 
 Dan Carpenter <error27@gmail.com>, christian.taedcke-oss@weidmueller.com
Cc: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 Christian Taedcke <christian.taedcke@weidmueller.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783006089; l=2082;
 i=christian.taedcke@weidmueller.com; s=20260702; h=from:subject:message-id;
 bh=IzUQu+E8VTZ8ZfkMwN9i9MqRhpTxuocHqQC40gcbdj4=;
 b=zXjAubGaROb2J3AtoN9zBnEjeOfeexMILJ4jDci7kkqlVT59SDtPLUATpTo7oS7kiAbIJhFR6
 QYEo87v7d0QD9wqXvRA8sU//UrioR6OPMm7DxrE2WXYlC+UkmDbcC6I
X-Developer-Key: i=christian.taedcke@weidmueller.com; a=ed25519;
 pk=fVCoBhFV3uMogA2nxIOU/rynNY+O2TDJgWvWjR06TrQ=
X-Endpoint-Received: by B4 Relay for christian.taedcke@weidmueller.com/20260702 with auth_id=847
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When one irq is used for errors and each channel gets a dedicated irq,
the total number of irqs is num_channels + 1. If the error irq is not
the last entry in irqbuf[] but an earlier one, the loop assigning
per-channel irqs terminates one iteration too early and the last
channel is left without an irq.

Iterate over all collected irqs instead of num_channels so the
error-irq skip does not shorten the effective channel count.

Fixes: 188c6ba1dd92 ("dmaengine: nbpfaxi: Fix memory corruption in probe()")
Cc: stable@vger.kernel.org
Signed-off-by: Christian Taedcke <christian.taedcke@weidmueller.com>
---
Changes in v2:
- Advance chan only when assigning a real irq to fix out-of-bounds
  memory access.
- Remove now redundant ARRAY_SIZE(irqbuf) check.
- Link to v1: https://patch.msgid.link/20260702-upstreaming-nbpfaxi-v1-v1-1-fd8ea8830cea@weidmueller.com

To: christian.taedcke-oss@weidmueller.com
To: Vinod Koul <vkoul@kernel.org>
To: Frank Li <Frank.Li@kernel.org>
To: Dan Carpenter <error27@gmail.com>
Cc: dmaengine@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
---
 drivers/dma/nbpfaxi.c | 8 +++-----
 1 file changed, 3 insertions(+), 5 deletions(-)

diff --git a/drivers/dma/nbpfaxi.c b/drivers/dma/nbpfaxi.c
index 05d7321629cc..bcfab62a71d7 100644
--- a/drivers/dma/nbpfaxi.c
+++ b/drivers/dma/nbpfaxi.c
@@ -1374,14 +1374,12 @@ static int nbpf_probe(struct platform_device *pdev)
 		if (irqs == num_channels + 1) {
 			struct nbpf_channel *chan;
 
-			for (i = 0, chan = nbpf->chan; i < num_channels;
-			     i++, chan++) {
+			for (i = 0, chan = nbpf->chan; i < irqs; i++) {
 				/* Skip the error IRQ */
 				if (irqbuf[i] == eirq)
-					i++;
-				if (i >= ARRAY_SIZE(irqbuf))
-					return -EINVAL;
+					continue;
 				chan->irq = irqbuf[i];
+				chan++;
 			}
 		} else {
 			/* 2 IRQs and more than one channel */

---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260702-upstreaming-nbpfaxi-v1-0364e355af85

Best regards,
--  
Christian Taedcke <christian.taedcke@weidmueller.com>

