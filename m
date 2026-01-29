From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Date: Thu, 29 Jan 2026 21:43:13 +0000
Subject: [PATCH v7 1/6] i2c: xiic: skip input clock setup on non-OF systems
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260129-i2c-xiic-v7-1-727e434897ef@nexthop.ai>
References: <20260129-i2c-xiic-v7-0-727e434897ef@nexthop.ai>
In-Reply-To: <20260129-i2c-xiic-v7-0-727e434897ef@nexthop.ai>
To: Michal Simek <michal.simek@amd.com>, Andi Shyti <andi.shyti@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Andy Shevchenko <andriy.shevchenko@intel.com>, 
 linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769723005; l=1542;
 i=abdurrahman@nexthop.ai; s=20260119; h=from:subject:message-id;
 bh=6voIA/a0l46cOc5ueYDVp8U+gfCNRwVU2ZoxgHh2Stc=;
 b=uBwWwmjKsmN67KJ/S9Ua6hanWw+GJQYf5zu/W4/drXYAPDqOkwughktr2P0AaBqADRvqAnCOm
 V4MRkqI0US1BbcTMGp7vo1PHJU6tME9zl1ePwNyn+YoiJHIm62Y0GzG
X-Developer-Key: i=abdurrahman@nexthop.ai; a=ed25519;
 pk=S+ysnf+NwMcBdHBlyKIUEAtaFGSIhQwcJcgcXhq0osg=
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/20260119 with auth_id=608
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The xiic driver supports operation without explicit clock configuration
when clocks cannot be specified via firmware, such as on ACPI-based
systems. This behavior is implemented in xiic_setclk(), which returns
early when either i2c_clk or input_clk are zero.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
 drivers/i2c/busses/i2c-xiic.c | 11 +++++++----
 1 file changed, 7 insertions(+), 4 deletions(-)

diff --git a/drivers/i2c/busses/i2c-xiic.c b/drivers/i2c/busses/i2c-xiic.c
index 28015d77599d..912a94d4d080 100644
--- a/drivers/i2c/busses/i2c-xiic.c
+++ b/drivers/i2c/busses/i2c-xiic.c
@@ -1423,6 +1423,7 @@ MODULE_DEVICE_TABLE(of, xiic_of_match);
 
 static int xiic_i2c_probe(struct platform_device *pdev)
 {
+	struct device *dev = &pdev->dev;
 	struct xiic_i2c *i2c;
 	struct xiic_i2c_platform_data *pdata;
 	const struct of_device_id *match;
@@ -1464,10 +1465,12 @@ static int xiic_i2c_probe(struct platform_device *pdev)
 	mutex_init(&i2c->lock);
 	spin_lock_init(&i2c->atomic_lock);
 
-	i2c->clk = devm_clk_get_enabled(&pdev->dev, NULL);
-	if (IS_ERR(i2c->clk))
-		return dev_err_probe(&pdev->dev, PTR_ERR(i2c->clk),
-				     "failed to enable input clock.\n");
+	if (is_of_node(dev->fwnode)) {
+		i2c->clk = devm_clk_get_enabled(dev, NULL);
+		if (IS_ERR(i2c->clk))
+			return dev_err_probe(&pdev->dev, PTR_ERR(i2c->clk),
+					"failed to enable input clock.\n");
+	}
 
 	i2c->dev = &pdev->dev;
 	pm_runtime_set_autosuspend_delay(i2c->dev, XIIC_PM_TIMEOUT);

-- 
2.52.0

