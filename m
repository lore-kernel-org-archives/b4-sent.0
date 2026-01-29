From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Date: Thu, 29 Jan 2026 21:43:18 +0000
Subject: [PATCH v7 6/6] i2c xiic: cosmetic: use resource format specifier
 in debug log
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260129-i2c-xiic-v7-6-727e434897ef@nexthop.ai>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769723005; l=796;
 i=abdurrahman@nexthop.ai; s=20260119; h=from:subject:message-id;
 bh=AyCNoRBKLYKfBPlFJJJUJ1HZ4ulZ88H5iw5TKWG8oFw=;
 b=uQhYS1vit0sv+bhMHnHmHsL2lmmclZrijbdaPDHxYdtFj5dfVi4YedI9NYD+Z/SyM+YsYV4vz
 IZ6i3jzydC0AASM1+x6xkBVi5X/v2/P+CWVis0tU9y2DhXTR5v7qGMU
X-Developer-Key: i=abdurrahman@nexthop.ai; a=ed25519;
 pk=S+ysnf+NwMcBdHBlyKIUEAtaFGSIhQwcJcgcXhq0osg=
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/20260119 with auth_id=608
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use standard resource format specifier %pR in debug log.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
 drivers/i2c/busses/i2c-xiic.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/i2c/busses/i2c-xiic.c b/drivers/i2c/busses/i2c-xiic.c
index 37a15065db60..b24b7a7bab8c 100644
--- a/drivers/i2c/busses/i2c-xiic.c
+++ b/drivers/i2c/busses/i2c-xiic.c
@@ -1520,8 +1520,8 @@ static int xiic_i2c_probe(struct platform_device *pdev)
 			i2c_new_client_device(&i2c->adap, pdata->devices + i);
 	}
 
-	dev_dbg(dev, "mmio %08lx irq %d scl clock frequency %d\n",
-		(unsigned long)res->start, irq, i2c->i2c_clk);
+	dev_dbg(dev, "mmio %pR irq %d scl clock frequency %d\n",
+		res, irq, i2c->i2c_clk);
 
 	return ret;
 }

-- 
2.52.0

