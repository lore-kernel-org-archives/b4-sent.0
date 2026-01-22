From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Date: Thu, 22 Jan 2026 08:32:32 +0000
Subject: [PATCH v2 2/2] i2c: xiic: make the clock optional
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260122-i2c-xiic-v2-2-134f5d743e8b@nexthop.ai>
References: <20260122-i2c-xiic-v2-0-134f5d743e8b@nexthop.ai>
In-Reply-To: <20260122-i2c-xiic-v2-0-134f5d743e8b@nexthop.ai>
To: Michal Simek <michal.simek@amd.com>, Andi Shyti <andi.shyti@kernel.org>
Cc: Andy Shevchenko <andriy.shevchenko@intel.com>, 
 linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769070755; l=1147;
 i=abdurrahman@nexthop.ai; s=20260119; h=from:subject:message-id;
 bh=30Y4elib2oXS0UgCTGXSQddfRG4H8frOGSLNdFvW0G8=;
 b=CuQl/jaFtohkiawpscgRaSfDh2zFoUAaQuD8v9qu3C6qO1n1SZkhluEHqHAaMg63WZ1k0TuCj
 hh0YTdPwwufAH7lEYU6hJCjs0ZmN4/0UP91yD28VLrFcVOAge1JCGsd
X-Developer-Key: i=abdurrahman@nexthop.ai; a=ed25519;
 pk=S+ysnf+NwMcBdHBlyKIUEAtaFGSIhQwcJcgcXhq0osg=
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/20260119 with auth_id=608
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The xiic driver is designed to operate without explicit clock configuration
when clocks are not specified in the firmware. This functionality is
already implemented in xiic_setclk(), which performs an early return when
either i2c_clk or input_clk are zero:

This condition is satisfied when clocks are missing, as clk_get_rate(NULL)
returns zero, allowing the driver to rely on hardware-configured timing.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
 drivers/i2c/busses/i2c-xiic.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/i2c/busses/i2c-xiic.c b/drivers/i2c/busses/i2c-xiic.c
index 2ca736cbf688..3d86b2077d6b 100644
--- a/drivers/i2c/busses/i2c-xiic.c
+++ b/drivers/i2c/busses/i2c-xiic.c
@@ -1459,7 +1459,7 @@ static int xiic_i2c_probe(struct platform_device *pdev)
 	mutex_init(&i2c->lock);
 	spin_lock_init(&i2c->atomic_lock);
 
-	i2c->clk = devm_clk_get_enabled(dev, NULL);
+	i2c->clk = devm_clk_get_optional_enabled(dev, NULL);
 	if (IS_ERR(i2c->clk))
 		return dev_err_probe(dev, PTR_ERR(i2c->clk),
 				     "failed to enable input clock.\n");

-- 
2.52.0

