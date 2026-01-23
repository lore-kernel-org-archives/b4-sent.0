From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Date: Fri, 23 Jan 2026 16:34:17 +0000
Subject: [PATCH v4 4/5] i2c: xiic: remove duplicate error message
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260123-i2c-xiic-v4-4-4a3eba3510ce@nexthop.ai>
References: <20260123-i2c-xiic-v4-0-4a3eba3510ce@nexthop.ai>
In-Reply-To: <20260123-i2c-xiic-v4-0-4a3eba3510ce@nexthop.ai>
To: Michal Simek <michal.simek@amd.com>, Andi Shyti <andi.shyti@kernel.org>
Cc: Andy Shevchenko <andriy.shevchenko@intel.com>, 
 linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769186056; l=832;
 i=abdurrahman@nexthop.ai; s=20260119; h=from:subject:message-id;
 bh=BSG/SlNQJILNTQbChjjZzK6BX9LQhT0R0SiLAYGmwP0=;
 b=t0BNbvH3/YpRUwikr6asJyBLXrzq6x9Q0JfwDHrCRBlEXFsYW4E2uVF2n7yiAIgM599aax/1O
 FVC8s6Uy88lDmkb899+kUDIqiIDSZBIXbpqxwOhNkM58eUdSwizZ3Or
X-Developer-Key: i=abdurrahman@nexthop.ai; a=ed25519;
 pk=S+ysnf+NwMcBdHBlyKIUEAtaFGSIhQwcJcgcXhq0osg=
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/20260119 with auth_id=608
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The devm_request_threaded_irq() already prints an error message. Remove
the duplicate.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
 drivers/i2c/busses/i2c-xiic.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/drivers/i2c/busses/i2c-xiic.c b/drivers/i2c/busses/i2c-xiic.c
index 6d47c9972719..800a27413978 100644
--- a/drivers/i2c/busses/i2c-xiic.c
+++ b/drivers/i2c/busses/i2c-xiic.c
@@ -1491,10 +1491,8 @@ static int xiic_i2c_probe(struct platform_device *pdev)
 	ret = devm_request_threaded_irq(dev, irq, NULL, xiic_process,
 					IRQF_ONESHOT, pdev->name, i2c);
 
-	if (ret < 0) {
-		dev_err_probe(dev, ret, "Cannot claim IRQ\n");
+	if (ret < 0)
 		return ret;
-	}
 
 	i2c->singlemaster =
 		of_property_read_bool(dev->of_node, "single-master");

-- 
2.52.0

