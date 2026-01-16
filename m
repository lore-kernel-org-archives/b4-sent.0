From: Fredrik Markstrom <fredrik.markstrom@est.tech>
Date: Fri, 16 Jan 2026 15:29:42 +0100
Subject: [PATCH v3] i3c: dw: Initialize spinlock to avoid upsetting lockdep
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260116-i3c_dw_initialize_spinlock-v3-1-cf707b6ed75f@est.tech>
X-B4-Tracking: v=1; b=H4sIAFVLamkC/43NSw6DIBSF4a0YxqURVKQddR9NYwCv9aYGDRD6M
 O696MhR0+F/Bt+ZiQeH4Mk5m4mDiB5Hm6I4ZMT0yt6BYpua8JyLnLGKYmGa9tmgxYBqwA80fkI
 7jOZBW1lLzriSpdAkAZODDl8bfr2l7tGH0b23r8jW9S82MsqoPplKd0pq4OUFfDgGMD1Z1cj3k
 vgp8SRBJXRZsE4zWe+kZVm+ZFfuCw0BAAA=
X-Change-ID: 20260115-i3c_dw_initialize_spinlock-d878212a846b
To: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Frank Li <Frank.Li@nxp.com>, Joel Stanley <joel@jms.id.au>, 
 Jeremy Kerr <jk@codeconstruct.com.au>
Cc: linux-i3c@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jani Nurminen <jani.nurminen@windriver.com>, 
 Fredrik Markstrom <fredrik.markstrom@est.tech>, 
 Ivar Holmqvist <ivar.holmqvist@est.tech>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768573783; l=1556;
 i=fredrik.markstrom@est.tech; s=20260113; h=from:subject:message-id;
 bh=/KOdTUSpOybjYrl+4vtlouA6tN65XqPMh7VsKfQMXIM=;
 b=8Hmq4QhdT8feOv8Uo8CnwWHiMPO2HDk8Yz3pp+jxafGGiodUoLEkQhHqpJJh5qRhiEqDzp7Qf
 7g1S3zE+n80CNvqys33fMPbEi7l4re8bL33/UKN6PrgBhn+QTloUQY4
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
Changes in v3:
- EDITME: describe what is new in this series revision.
- EDITME: use bulletpoints and terse descriptions.
- Link to v2: https://lore.kernel.org/r/20260116-i3c_dw_initialize_spinlock-v2-1-e56b431fb187@est.tech

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

