From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 18 Aug 2023 01:04:04 +0800
Subject: [PATCH RESEND 5/5] clk: ccf: call clock provided ops directly for
 endisable()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230818-clk-fix-v1-5-49ec18f820bf@outlook.com>
References: <20230818-clk-fix-v1-0-49ec18f820bf@outlook.com>
In-Reply-To: <20230818-clk-fix-v1-0-49ec18f820bf@outlook.com>
To: Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1692291852; l=1348;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=TgVT16K9zaLUEOhpgO1T2uH2QBfAht6D9ePnHRxlfEs=;
 b=DgxbdUdSnGi1NsOABYobcfpgqoPIRuaxcRMH33Z9D5YGn1+EOVWzdrQuvdGCaY5J1AAJkZjEp
 VZlKJsqB6xkBGJvGyStWO4qGzsdikE7DMIUOcA9GVbTjKcVk7YwKmyn
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

