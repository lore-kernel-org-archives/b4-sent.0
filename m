From: Kimi Chen <kimi.zy.chen@fii-foxconn.com>
Date: Thu, 06 Nov 2025 11:28:57 +0800
Subject: [PATCH] ARM: dts: aspeed: clemente: add gpio line name to io
 expander
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251106-dts-add-gpio-to-io-expander-v1-1-b4765c092ebe@fii-foxconn.com>
X-B4-Tracking: v=1; b=H4sIAPgVDGkC/x3MMQqAMAxA0atIZgO2WgevIg6hiTVLW1oRQby7x
 eXDW/4DVYpKhaV7oMilVVNsMH0H/qAYBJWbwQ7WGTPMyGdFYsaQNeGZsFXuTJGlIE1+tN7vbia
 CdshFdr3/+7q97weaqovrbQAAAA==
X-Change-ID: 20251106-dts-add-gpio-to-io-expander-a4c32ccf56aa
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 george.kw.lee@fii-foxconn.com, Kimi Chen <kimi.zy.chen@fii-foxconn.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762399744; l=1184;
 i=kimi.zy.chen@fii-foxconn.com; s=20251105; h=from:subject:message-id;
 bh=AqtmtuP+jr8hv72i4Nsvgu+5GWsxpYdSguFgfPJMrrg=;
 b=gWTwCX2zWlQlFmQ63qT3cV1Pcm+eKRpXeZgl3/1S5mJQoeNAfaz9EI1I+tUftf1a7t2j1hDTo
 eWJkfoeyTbcD7nRo1MdQ4AHqWcYF0SRWvsqNNqGdct6+z+VvOuuCC5b
X-Developer-Key: i=kimi.zy.chen@fii-foxconn.com; a=ed25519;
 pk=3zHetsW/3CYYIgQlYV9dqSS7aW7aZXLUaIvc+OKr3NM=
X-Endpoint-Received: by B4 Relay for kimi.zy.chen@fii-foxconn.com/20251105 with auth_id=559
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The chassis power cycle process requires a forced shutdown before
cutting off the standby power. Therefore, SCM CPLD adds a hard shutdown
host function and triggers it via the IO expander in Clemente platform.

Thus, a new GPIO line named "hard_shutdown_host" is added to the
PCA9555 IO expander at line 10 to notify the CPLD to execute the hard
shutdown host function.

Signed-off-by: Kimi Chen <kimi.zy.chen@fii-foxconn.com>
---
 arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-clemente.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-clemente.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-clemente.dts
index 450446913e36..0eafd8ea04ac 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-clemente.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-clemente.dts
@@ -983,7 +983,7 @@ io_expander4: gpio@4f {
 			"",
 			"",
 			"",
-			"",
+			"hard_shutdown_host",
 			"",
 			"",
 			"",

---
base-commit: 6953afcd81a2cc73784e3dd23faa0a1aaf97441a
change-id: 20251106-dts-add-gpio-to-io-expander-a4c32ccf56aa

Best regards,
-- 
Kimi Chen <kimi.zy.chen@fii-foxconn.com>

