From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Date: Fri, 13 Feb 2026 00:15:21 +0000
Subject: [PATCH v11 6/7] i2c: xiic: use numbered adapter registration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260213-i2c-xiic-v11-6-5d18aea11bde@nexthop.ai>
References: <20260213-i2c-xiic-v11-0-5d18aea11bde@nexthop.ai>
In-Reply-To: <20260213-i2c-xiic-v11-0-5d18aea11bde@nexthop.ai>
To: Michal Simek <michal.simek@amd.com>, Andi Shyti <andi.shyti@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Andy Shevchenko <andriy.shevchenko@intel.com>, 
 linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770941721; l=1381;
 i=abdurrahman@nexthop.ai; s=20260119; h=from:subject:message-id;
 bh=OcfhhTnF0WtrdPeWNqGBAVD1c0SVBN7KhRbWFtUKE0E=;
 b=x96Wn3uuPvc410bLRuXiGYkplzRWuLttTyJI9nXHfMJhzJq0/V8kNe6hltjxFJpDfsYODUu3l
 1BQHVyRnVcIC4Q7VgvNexWkyQetdFE+JV1WlmRrA5BzmvIrAve16DsT
X-Developer-Key: i=abdurrahman@nexthop.ai; a=ed25519;
 pk=S+ysnf+NwMcBdHBlyKIUEAtaFGSIhQwcJcgcXhq0osg=
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/20260119 with auth_id=608
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Switch from i2c_add_adapter() to i2c_add_numbered_adapter() to enable
platforms to specify fixed I2C bus numbers via the platform device ID.

This allows systems to maintain consistent bus numbering across reboots.
On platforms where the device ID is PLATFORM_DEVID_NONE (the default),
the adapter falls back to dynamic allocation, preserving backward
compatibility.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
 drivers/i2c/busses/i2c-xiic.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/i2c/busses/i2c-xiic.c b/drivers/i2c/busses/i2c-xiic.c
index 373c00a93034..2ad75325154c 100644
--- a/drivers/i2c/busses/i2c-xiic.c
+++ b/drivers/i2c/busses/i2c-xiic.c
@@ -1450,6 +1450,7 @@ static int xiic_i2c_probe(struct platform_device *pdev)
 	/* hook up driver to tree */
 	platform_set_drvdata(pdev, i2c);
 	i2c->adap = xiic_adapter;
+	i2c->adap.nr = pdev->id;
 	i2c_set_adapdata(&i2c->adap, i2c);
 	i2c->adap.dev.parent = dev;
 	device_set_node(&i2c->adap.dev, dev_fwnode(dev));
@@ -1506,7 +1507,7 @@ static int xiic_i2c_probe(struct platform_device *pdev)
 		return dev_err_probe(dev, ret, "Cannot xiic_reinit\n");
 
 	/* add i2c adapter to i2c tree */
-	ret = i2c_add_adapter(&i2c->adap);
+	ret = i2c_add_numbered_adapter(&i2c->adap);
 	if (ret) {
 		xiic_deinit(i2c);
 		return ret;

-- 
2.52.0

