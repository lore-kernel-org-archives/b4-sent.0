From: Yu-Che Hsieh <yc_hsieh@aspeedtech.com>
Date: Mon, 29 Jun 2026 14:48:59 +0800
Subject: [PATCH 2/4] ipmi: bt-bmc: Track open state per device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260629-aspeed-bt-bmc-multichannel-v1-2-fc23ee337f7a@aspeedtech.com>
References: <20260629-aspeed-bt-bmc-multichannel-v1-0-fc23ee337f7a@aspeedtech.com>
In-Reply-To: <20260629-aspeed-bt-bmc-multichannel-v1-0-fc23ee337f7a@aspeedtech.com>
To: Corey Minyard <corey@minyard.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: openipmi-developer@lists.sourceforge.net, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, Yu-Che Hsieh <yc_hsieh@aspeedtech.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782715772; l=1964;
 i=yc_hsieh@aspeedtech.com; s=20260629; h=from:subject:message-id;
 bh=kkcdpH7g4gFHRExA7T4VUvsyg0bKpkuItRJGEI3xPJA=;
 b=yHQTY1jCvmxKBbcWqHMlIZQ8QIbmxk/w14R13q3bhtuzMgZpj11PsEVwfZCzFGlKhBzXd+Lfs
 TSHkqXBCUHbCjiz3yJ7vSAa2XwHJor+R157niWVbLj+PCVz3VziveqT
X-Developer-Key: i=yc_hsieh@aspeedtech.com; a=ed25519;
 pk=kLxUeF7g6teciq79it9N3tYNgp3yCspZ+AHlYSnZ0gs=
X-Endpoint-Received: by B4 Relay for yc_hsieh@aspeedtech.com/20260629 with auth_id=844
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver uses a global open count to allow only one userspace client

to open the BT device at a time. This works for a single device, but

also prevents independent BT device instances from being opened

concurrently.

Move the open count into struct bt_bmc so each device instance tracks

its own open state. This preserves the single-open behavior per device

while allowing multiple BT devices to operate independently.

Signed-off-by: Yu-Che Hsieh <yc_hsieh@aspeedtech.com>
---
 drivers/char/ipmi/bt-bmc.c | 11 ++++++-----
 1 file changed, 6 insertions(+), 5 deletions(-)

diff --git a/drivers/char/ipmi/bt-bmc.c b/drivers/char/ipmi/bt-bmc.c
index f3c67272502f..486ecc0b6815 100644
--- a/drivers/char/ipmi/bt-bmc.c
+++ b/drivers/char/ipmi/bt-bmc.c
@@ -64,10 +64,9 @@ struct bt_bmc {
 	wait_queue_head_t	queue;
 	struct timer_list	poll_timer;
 	struct mutex		mutex;
+	atomic_t		open_count;
 };
 
-static atomic_t open_count = ATOMIC_INIT(0);
-
 static u8 bt_inb(struct bt_bmc *bt_bmc, int reg)
 {
 	return readb(bt_bmc->base + reg);
@@ -152,12 +151,12 @@ static int bt_bmc_open(struct inode *inode, struct file *file)
 {
 	struct bt_bmc *bt_bmc = file_bt_bmc(file);
 
-	if (atomic_inc_return(&open_count) == 1) {
+	if (atomic_inc_return(&bt_bmc->open_count) == 1) {
 		clr_b_busy(bt_bmc);
 		return 0;
 	}
 
-	atomic_dec(&open_count);
+	atomic_dec(&bt_bmc->open_count);
 	return -EBUSY;
 }
 
@@ -313,7 +312,7 @@ static int bt_bmc_release(struct inode *inode, struct file *file)
 {
 	struct bt_bmc *bt_bmc = file_bt_bmc(file);
 
-	atomic_dec(&open_count);
+	atomic_dec(&bt_bmc->open_count);
 	set_b_busy(bt_bmc);
 	return 0;
 }
@@ -425,6 +424,8 @@ static int bt_bmc_probe(struct platform_device *pdev)
 	if (IS_ERR(bt_bmc->base))
 		return PTR_ERR(bt_bmc->base);
 
+	atomic_set(&bt_bmc->open_count, 0);
+
 	mutex_init(&bt_bmc->mutex);
 	init_waitqueue_head(&bt_bmc->queue);
 

-- 
2.34.1

