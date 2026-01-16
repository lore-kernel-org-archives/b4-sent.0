From: Fredrik Markstrom <fredrik.markstrom@est.tech>
Date: Fri, 16 Jan 2026 09:41:36 +0100
Subject: [PATCH v2] i3c: dw: Initialize spinlock to avoid upsetting lockdep
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260116-i3c_dw_initialize_spinlock-v2-1-e56b431fb187@est.tech>
X-B4-Tracking: v=1; b=H4sIAL/5aWkC/43NSw6DIBSF4a2YOy6NULXUUffRGAN4LTc1aIDYh
 2Hvpa6gw+8M/rNBQE8YoC028LhSoNlliEMBxip3R0ZDNohSNCXnNaOT6YdnT44iqYk+2IeF3DS
 bBxvkWQoulKwaDTmweBzptcdvXbalEGf/3r9W/lv/yq6ccaYvptajkhpFdcUQjxGNhS6l9AVZN
 omgwwAAAA==
X-Change-ID: 20260115-i3c_dw_initialize_spinlock-d878212a846b
To: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Frank Li <Frank.Li@nxp.com>, Joel Stanley <joel@jms.id.au>, 
 Jeremy Kerr <jk@codeconstruct.com.au>
Cc: linux-i3c@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jani Nurminen <jani.nurminen@windriver.com>, 
 Fredrik Markstrom <fredrik.markstrom@est.tech>, 
 Ivar Holmqvist <ivar.holmqvist@est.tech>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768552904; l=1325;
 i=fredrik.markstrom@est.tech; s=20260113; h=from:subject:message-id;
 bh=cn3RST4SNo9jSm6US+uLLzCCBGl+hGYy8MD0NCviD5E=;
 b=7n3KMgnjoyny8fHUpEHSdn477HdTh0vUeLPVakWON8Sd4DuiJURHbcLX2a4CO+wz4cPaYnIFR
 ce7LVed8zdPAE3+tBGSOQYK3Ytj0x4n+DILNioIAeyqY1GehSnxY3t6
X-Developer-Key: i=fredrik.markstrom@est.tech; a=ed25519;
 pk=0a8IXHEgAX55JPS8VZfTf1sDp7q/oAOf459tDQd40Eg=
X-Endpoint-Received: by B4 Relay for fredrik.markstrom@est.tech/20260113 with auth_id=600
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The devs_lock spinlock introduced when adding support for ibi:s was
never initialized.

Fixes: e389b1d72a624 ("i3c: dw: Add support for in-band interrupts")
Suggested-by: Jani Nurminen <jani.nurminen@windriver.com>
Signed-off-by: Fredrik Markstrom <fredrik.markstrom@est.tech>
Reviewed-by: Ivar Holmqvist <ivar.holmqvist@est.tech>
---
Changes in v2:
- Added context in commit message
- Link to v1: https://lore.kernel.org/r/20260115-i3c_dw_initialize_spinlock-v1-1-b9c5bfa8be24@est.tech
---
 drivers/i3c/master/dw-i3c-master.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/i3c/master/dw-i3c-master.c b/drivers/i3c/master/dw-i3c-master.c
index 889e2ed5bc83..d5b070404056 100644
--- a/drivers/i3c/master/dw-i3c-master.c
+++ b/drivers/i3c/master/dw-i3c-master.c
@@ -1570,6 +1570,8 @@ int dw_i3c_common_probe(struct dw_i3c_master *master,
 	spin_lock_init(&master->xferqueue.lock);
 	INIT_LIST_HEAD(&master->xferqueue.list);
 
+	spin_lock_init(&master->devs_lock);
+
 	writel(INTR_ALL, master->regs + INTR_STATUS);
 	irq = platform_get_irq(pdev, 0);
 	ret = devm_request_irq(&pdev->dev, irq,

---
base-commit: 0f61b1860cc3f52aef9036d7235ed1f017632193
change-id: 20260115-i3c_dw_initialize_spinlock-d878212a846b

Best regards,
-- 
Fredrik Markstrom <fredrik.markstrom@est.tech>

