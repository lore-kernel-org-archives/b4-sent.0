From: Christian DREHER <christian.dreher@nanoxplore.com>
Date: Tue, 28 Apr 2026 20:04:05 +0200
Subject: [PATCH 1/4] net: macb: include arch/clk.h only when necessary
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-net-macb-support-for-feature-lite-instances-v1-1-480e4cecac01@nanoxplore.com>
References: <20260428-net-macb-support-for-feature-lite-instances-v1-0-480e4cecac01@nanoxplore.com>
In-Reply-To: <20260428-net-macb-support-for-feature-lite-instances-v1-0-480e4cecac01@nanoxplore.com>
To: u-boot@lists.denx.de
Cc: Jerome Forissier <jerome.forissier@arm.com>, 
 Tom Rini <trini@konsulko.com>, 
 Christian DREHER <christian.dreher@nanoxplore.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777399485; l=896;
 i=christian.dreher@nanoxplore.com; s=20260428; h=from:subject:message-id;
 bh=9046TvejUO8RMUiT/+l/BjcleTvgUspN77fLbvIWyHo=;
 b=IJSfQyXJkvFnkIH0kzd8+4ie2ynOFlSgadn4sk02V71eP1p+VdyA8GxJDBJOTwAXV8xouGNlL
 YpB8/00lMe5ATSuuI1fBh4kzC9S8b2DN/3O3GJTw7FdZX1/M1mKwmbH
X-Developer-Key: i=christian.dreher@nanoxplore.com; a=ed25519;
 pk=id7EcKmXLV2xNgNiCIcsPjkoMQHM/qxTYqEqMhidSAU=
X-Endpoint-Received: by B4 Relay for christian.dreher@nanoxplore.com/20260428 with auth_id=760
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It does not exist in my setup (an on-going arm64 SoC), and removing
it does not cause any missing declaration, but some code called when
CONFIG_CLK is missing calls get_macb_pclk_rate, which is only defined
in arch/arm/mach-at91/include/mach/clk.h

Signed-off-by: Christian DREHER <christian.dreher@nanoxplore.com>
---
 drivers/net/macb.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/net/macb.c b/drivers/net/macb.c
index cbf5f605518..719aef39a3f 100644
--- a/drivers/net/macb.c
+++ b/drivers/net/macb.c
@@ -38,9 +38,13 @@
 #include <linux/mii.h>
 #include <asm/io.h>
 #include <linux/dma-mapping.h>
-#include <asm/arch/clk.h>
 #include <linux/errno.h>
 
+/* Without CLK, we rely on the arch definition */
+#if !defined(CONFIG_CLK)
+#include <asm/arch/clk.h>
+#endif
+
 #include "macb.h"
 
 DECLARE_GLOBAL_DATA_PTR;

-- 
2.47.3

