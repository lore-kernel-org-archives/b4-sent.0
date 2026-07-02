From: Christian Taedcke <christian.taedcke@weidmueller.com>
Date: Thu, 02 Jul 2026 15:43:29 +0200
Subject: [PATCH] dmaengine: nbpfaxi: Fix setting channel irqs in probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260702-upstreaming-nbpfaxi-v1-v1-1-fd8ea8830cea@weidmueller.com>
X-B4-Tracking: v=1; b=H4sIAAFrRmoC/yXMQQqDMBBA0avIrB2IsbHiVcRF1ImdgjFkVATx7
 qZ2+Rb/nyAUmQSa7IRIOwsvPqHIMxg+1k+EPCaDVrpSb6VxC7JGsjP7CX0fnD0Y9wJVWb2oNMa
 62kCKQyTHxzNuu79l6780rL8bXNcN7C8/RnoAAAA=
X-Change-ID: 20260702-upstreaming-nbpfaxi-v1-0364e355af85
To: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>, 
 Dan Carpenter <error27@gmail.com>, christian.taedcke-oss@weidmueller.com
Cc: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 Christian Taedcke <christian.taedcke@weidmueller.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782999813; l=1388;
 i=christian.taedcke@weidmueller.com; s=20260702; h=from:subject:message-id;
 bh=Y9B/MscRS+aViEQu67zlX3/v5KCJOOqQmYwRkuMIXkk=;
 b=TSvP0rZyf+DIpaVyWev2dPFYoKXBBM9HKVYYLQQ/m26InhmavFJeRlorKWP9ariFOgOeoXKdP
 jaI36yxRwSsCRZb3bRB0yOyasZQhjQv9fUkHfP2dM+/Fe18iLRjoSVZ
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
 drivers/dma/nbpfaxi.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/dma/nbpfaxi.c b/drivers/dma/nbpfaxi.c
index 05d7321629cc..74ff7bd979e2 100644
--- a/drivers/dma/nbpfaxi.c
+++ b/drivers/dma/nbpfaxi.c
@@ -1374,7 +1374,7 @@ static int nbpf_probe(struct platform_device *pdev)
 		if (irqs == num_channels + 1) {
 			struct nbpf_channel *chan;
 
-			for (i = 0, chan = nbpf->chan; i < num_channels;
+			for (i = 0, chan = nbpf->chan; i < irqs;
 			     i++, chan++) {
 				/* Skip the error IRQ */
 				if (irqbuf[i] == eirq)

---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260702-upstreaming-nbpfaxi-v1-0364e355af85

Best regards,
--  
Christian Taedcke <christian.taedcke@weidmueller.com>

