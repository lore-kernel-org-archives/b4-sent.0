From: Yang Xiwen <forbidden405@outlook.com>
Date: Wed, 09 Aug 2023 00:37:45 +0800
Subject: [PATCH 5/5] clk: ccf: call clock provided ops directly for
 endisable()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230809-clk-fix-v1-5-808dbae54e5e@outlook.com>
References: <20230809-clk-fix-v1-0-808dbae54e5e@outlook.com>
In-Reply-To: <20230809-clk-fix-v1-0-808dbae54e5e@outlook.com>
To: Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1691512665; l=1348;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=TgVT16K9zaLUEOhpgO1T2uH2QBfAht6D9ePnHRxlfEs=;
 b=X5u8S82b2qkOVaK0FbcGr2PVW77CoBePAEf0krF0Nxn+o/IMwTP7DXjMgAJiy7TmX4Gi3gDcj
 e2EliIIySV4AZXDAZ9cGvjn51jAqqYKvMTAuoFvfJSwSSmcKF2q0YFD
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Calling into CCF framework will cause a clock being enabled twice
instead of once (clk->enable_count becomes 2 rather than 1), thus making
it hard to disable (needs to call clk_disable() twice).
Fix that by calling clock provided ops directly.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/clk.c | 12 +++++++++++-
 1 file changed, 11 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/clk.c b/drivers/clk/clk.c
index a38daaac0c..00d082c46f 100644
--- a/drivers/clk/clk.c
+++ b/drivers/clk/clk.c
@@ -14,6 +14,7 @@
 #include <dm/uclass.h>
 #include <dm/lists.h>
 #include <dm/device-internal.h>
+#include <linux/clk-provider.h>
 
 int clk_register(struct clk *clk, const char *drv_name,
 		 const char *name, const char *parent_name)
@@ -115,11 +116,20 @@ int ccf_clk_set_parent(struct clk *clk, struct clk *parent)
 static int ccf_clk_endisable(struct clk *clk, bool enable)
 {
 	struct clk *c;
+	const struct clk_ops *ops;
 	int err = clk_get_by_id(clk->id, &c);
 
 	if (err)
 		return err;
-	return enable ? clk_enable(c) : clk_disable(c);
+	else
+		ops = clk_dev_ops(c->dev);
+
+	if (enable && ops->enable)
+		return ops->enable(c);
+	else if (!enable && ops->disable)
+		return ops->disable(c);
+
+	return -ENOSYS;
 }
 
 int ccf_clk_enable(struct clk *clk)

-- 
2.34.1

