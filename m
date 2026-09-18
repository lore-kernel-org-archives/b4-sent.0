From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Fri, 18 Sep 2026 16:57:18 +0800
Subject: [PATCH 03/21] media: i2c: it6625: default the debug module
 parameter to 0
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-upstream-it6625-follow-up-patch-v1-3-78d72d7886a5@ite.com.tw>
References: <20260918-upstream-it6625-follow-up-patch-v1-0-78d72d7886a5@ite.com.tw>
In-Reply-To: <20260918-upstream-it6625-follow-up-patch-v1-0-78d72d7886a5@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721837; l=753;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=4gDgLddPvEaApefdm/VXiVuCA+25zmyLXFpBDuZ557I=;
 b=Yb7vBS9u+fyUDCkPjWNic/5G/TIqKMye9wdZqZO5rdvuWGRbVA2OOTaTPxihG0Qy16rsCgtaT
 uTEqkSWiu5/BV7NFk7PqcOZCjQbpzZc9FSFh6flKbMWf/pMjp9+kyWn
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Printing all debug information by default is noisy for a normal boot;
default debug to 0 like the module parameter's own description implies.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index 5d267676606e340ad0ee5ad2b78e5acb50a32980..42bdcc3af326ceb6c529b8da35836c49c8c43643 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -29,7 +29,7 @@
 #include <media/v4l2-fwnode.h>
 #include <uapi/linux/it6625.h>
 
-static int debug = 3;
+static int debug;
 module_param(debug, int, 0644);
 MODULE_PARM_DESC(debug, "debug level (0-3)");
 

-- 
2.34.1

