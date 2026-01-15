From: Fredrik Markstrom <fredrik.markstrom@est.tech>
Date: Thu, 15 Jan 2026 14:25:29 +0100
Subject: [PATCH] i3c: dw: Initialize spinlock to avoid upsetting lockdep
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260115-i3c_dw_initialize_spinlock-v1-1-b9c5bfa8be24@est.tech>
X-B4-Tracking: v=1; b=H4sIAMjqaGkC/x3M0QqDIBQG4FeJc52QtjXpVWKI6an9FBY6Koref
 bLL7+a7KHEEJ2qLiyJvSFhChiwLch8bRhbw2aQq1VRSPgVqZ/xuEPCFnXGySSvCvLhJeP3SSiq
 rH01POVgjDzj+efe+7x/06TN5bAAAAA==
X-Change-ID: 20260115-i3c_dw_initialize_spinlock-d878212a846b
To: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Frank Li <Frank.Li@nxp.com>, Joel Stanley <joel@jms.id.au>, 
 Jeremy Kerr <jk@codeconstruct.com.au>
Cc: linux-i3c@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jani Nurminen <jani.nurminen@windriver.com>, 
 Fredrik Markstrom <fredrik.markstrom@est.tech>, 
 Ivar Holmqvist <ivar.holmqvist@est.tech>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768483534; l=1074;
 i=fredrik.markstrom@est.tech; s=20260113; h=from:subject:message-id;
 bh=0LzRIFsM7K9scwfqEE9HL8ML7hRdUD7Lg/RNQupyH/Y=;
 b=ZyZv4QPTs2qw25vZgEfWWTYHfpd9cBYfv9kIhIaVFOJFf6fDLzf3optAFLaYZx/C/J75wqksl
 QvWl1wV6jOXAkPfTnUvglmyjAOQAOqWXcpzEU4BQ+6DJd+OHI/zv8j1
X-Developer-Key: i=fredrik.markstrom@est.tech; a=ed25519;
 pk=0a8IXHEgAX55JPS8VZfTf1sDp7q/oAOf459tDQd40Eg=
X-Endpoint-Received: by B4 Relay for fredrik.markstrom@est.tech/20260113 with auth_id=600
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes: e389b1d72a624 ("i3c: dw: Add support for in-band interrupts")
Suggested-by: Jani Nurminen <jani.nurminen@windriver.com>
Signed-off-by: Fredrik Markstrom <fredrik.markstrom@est.tech>
Reviewed-by: Ivar Holmqvist <ivar.holmqvist@est.tech>
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

