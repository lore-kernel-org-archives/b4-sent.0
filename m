From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Thu, 13 Mar 2025 15:14:44 +0000
Subject: [PATCH v2 2/6] clk: clk-axi-clkgen: make sure to include
 mod_devicetable.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250313-dev-axi-clkgen-limits-v2-2-173ae2ad6311@analog.com>
References: <20250313-dev-axi-clkgen-limits-v2-0-173ae2ad6311@analog.com>
In-Reply-To: <20250313-dev-axi-clkgen-limits-v2-0-173ae2ad6311@analog.com>
To: linux-clk@vger.kernel.org, linux-fpga@vger.kernel.org
Cc: Stephen Boyd <sboyd@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Moritz Fischer <mdf@kernel.org>, Wu Hao <hao.wu@intel.com>, 
 Xu Yilun <yilun.xu@intel.com>, Tom Rix <trix@redhat.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741878886; l=659;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=BGGCp0B/QWIWTXslxwf7dXWZP54vUsku9BYioWyTJhQ=;
 b=0pDqjr74YVLZgY0k3lL2nGqwvPJ+rMhG/DTcr09WvNX+swc91tKW+DRs5gSn2qLNBooMH2yA9
 ck3EeXD5nZ0DOeY7QQhVQCgtUiNOOxJWR9MwiBIkCS8BXaYkHdMDW/8
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The mod_devicetable header is the one to be used for struct
of_device_id.

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
2.48.1

