From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 27 Jun 2025 15:59:11 +0100
Subject: [PATCH RESEND v7 2/7] clk: clk-axi-clkgen: make sure to include
 mod_devicetable.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250627-dev-axi-clkgen-limits-v7-2-e4f3b1f76189@analog.com>
References: <20250627-dev-axi-clkgen-limits-v7-0-e4f3b1f76189@analog.com>
In-Reply-To: <20250627-dev-axi-clkgen-limits-v7-0-e4f3b1f76189@analog.com>
To: linux-clk@vger.kernel.org, linux-fpga@vger.kernel.org, 
 dmaengine@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 linux-iio@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-spi@vger.kernel.org
Cc: Stephen Boyd <sboyd@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Moritz Fischer <mdf@kernel.org>, Wu Hao <hao.wu@intel.com>, 
 Xu Yilun <yilun.xu@intel.com>, Tom Rix <trix@redhat.com>, 
 Vinod Koul <vkoul@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Trevor Gamblin <tgamblin@baylibre.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Mark Brown <broonie@kernel.org>, 
 Mike Turquette <mturquette@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751036364; l=711;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=MyQa116l4E9wDyCm1ZTrQoq6qju7oKOtUMHCY6i0bL8=;
 b=2tz7oTZMPTpdwccq3C4mYynkH8wyt/mU8mG8vfXZ7twDrZ5eUmC35jV6dn9UsBNjjpYAJPddt
 p3QC9opyrKCAWBUN6nIpLPGp6B8DVFEdO+wvsbebS81sVuXMBUmiNt6
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The mod_devicetable header is the one to be used for struct
of_device_id.

Reviewed-by: David Lechner <dlechner@baylibre.com>
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/clk/clk-axi-clkgen.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/clk/clk-axi-clkgen.c b/drivers/clk/clk-axi-clkgen.c
index 00bf799964c61a3efc042b0f3a9ec3bc8625c9da..2a95f9b220234a1245024a821c50e1eb9c104ac9 100644
--- a/drivers/clk/clk-axi-clkgen.c
+++ b/drivers/clk/clk-axi-clkgen.c
@@ -13,6 +13,7 @@
 #include <linux/io.h>
 #include <linux/of.h>
 #include <linux/module.h>
+#include <linux/mod_devicetable.h>
 #include <linux/err.h>
 
 #define AXI_CLKGEN_V2_REG_RESET		0x40

-- 
2.49.0

