From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Date: Fri, 23 Jan 2026 08:02:46 +0000
Subject: [PATCH v3 3/5] i2c: xiic: remove duplicate error message
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260123-i2c-xiic-v3-3-eb7cd4254dfb@nexthop.ai>
References: <20260123-i2c-xiic-v3-0-eb7cd4254dfb@nexthop.ai>
In-Reply-To: <20260123-i2c-xiic-v3-0-eb7cd4254dfb@nexthop.ai>
To: Michal Simek <michal.simek@amd.com>, Andi Shyti <andi.shyti@kernel.org>
Cc: Andy Shevchenko <andriy.shevchenko@intel.com>, 
 linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769155384; l=651;
 i=abdurrahman@nexthop.ai; s=20260119; h=from:subject:message-id;
 bh=8+foX4oDtm5Uf+NftOW1CSk/aI5wtgDdkEiHVL5041E=;
 b=npVAlHweINmY0ziepQn7v7CkJ6Z4uRPbzWZINnPl2eVl5qzOMUYQXmJq17nhmPsl1DCkMUbA/
 CQXJFwhdHIyCQAvwsNUCr5F8odKG29+++McehkKAwVUFaTtl5PTuw4w
X-Developer-Key: i=abdurrahman@nexthop.ai; a=ed25519;
 pk=S+ysnf+NwMcBdHBlyKIUEAtaFGSIhQwcJcgcXhq0osg=
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/20260119 with auth_id=608
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The devm_request_threaded_irq() already prints an error message. Remove
the duplicate.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
 drivers/i2c/busses/i2c-xiic.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/i2c/busses/i2c-xiic.c b/drivers/i2c/busses/i2c-xiic.c
index 79643c27e75d..52d5c0c5c5c8 100644
--- a/drivers/i2c/busses/i2c-xiic.c
+++ b/drivers/i2c/busses/i2c-xiic.c
@@ -1491,7 +1491,6 @@ static int xiic_i2c_probe(struct platform_device *pdev)
 					pdev->name, i2c);
 
 	if (ret < 0) {
-		dev_err_probe(&pdev->dev, ret, "Cannot claim IRQ\n");
 		goto err_pm_disable;
 	}
 

-- 
2.52.0

