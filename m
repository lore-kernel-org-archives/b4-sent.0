From: Yang Xiwen <forbidden405@outlook.com>
Date: Thu, 22 Feb 2024 00:41:08 +0800
Subject: [PATCH v3 5/8] clk: hisilicon: fix include path for
 crg-hi3798cv200
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240222-clk-mv200-v3-5-f30795b50318@outlook.com>
References: <20240222-clk-mv200-v3-0-f30795b50318@outlook.com>
In-Reply-To: <20240222-clk-mv200-v3-0-f30795b50318@outlook.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: David Yang <mmyangfl@gmail.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708533664; l=857;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=mym+b8HCE92ettwNUwgVrGSN23Zmo9f3k4P4EePsjQY=;
 b=HLw89V3skgYuIgXNObji690aUCG4vCg3pPngAlQUefQDRmWgy3nuR0CeMUiJFsI9E0pdBvCbv
 MAJ4hURdBW4CPWHSz+j7FQKY1CknWA3vYvXXyzz+IPsuxVfVLcABYoT
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

histb-clock.h is now deprecated. Include hisilicon,hi3798cv200-crg.h and
hisilicon-sysctrl.h directly instead.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/hisilicon/crg-hi3798cv200.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/hisilicon/crg-hi3798cv200.c b/drivers/clk/hisilicon/crg-hi3798cv200.c
index f651b197e45a..3e26a8f6df36 100644
--- a/drivers/clk/hisilicon/crg-hi3798cv200.c
+++ b/drivers/clk/hisilicon/crg-hi3798cv200.c
@@ -5,7 +5,8 @@
  * Copyright (c) 2016 HiSilicon Technologies Co., Ltd.
  */
 
-#include <dt-bindings/clock/histb-clock.h>
+#include <dt-bindings/clock/hisilicon,hi3798cv200-crg.h>
+#include <dt-bindings/clock/hisilicon,hi3798cv200-sysctrl.h>
 #include <linux/clk-provider.h>
 #include <linux/module.h>
 #include <linux/of.h>

-- 
2.43.0

