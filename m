From: Yang Xiwen <forbidden405@outlook.com>
Date: Thu, 01 Jan 2026 03:52:49 +0800
Subject: [PATCH v2 3/5] clk: use clk_get_parent() helper in
 clk_en(dis)able()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260101-clk-reparent-v2-3-3eb42b78c7f1@outlook.com>
References: <20260101-clk-reparent-v2-0-3eb42b78c7f1@outlook.com>
In-Reply-To: <20260101-clk-reparent-v2-0-3eb42b78c7f1@outlook.com>
To: Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767210769; l=1887;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=Pih0KZJb5On0c56A8s6D/fXYUeiaLJVvtspf94laL3g=;
 b=qfaJFyO6eCRYjDrcQc67qR0d6bDdNh5haLiTQeFoFYYtx49hb1PS2cjoXtumEPv1s0h/Ilkti
 HpC8KYPtG8NBQFRe+rudpkN2+Mfmr9tzDOb55pKRMyNIjaJHI0qWn6s
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update clk_enable() and clk_disable() to use clk_get_parent() instead of
manually accessing clk->dev->parent.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/clk-uclass.c | 26 +++++++++++++++-----------
 1 file changed, 15 insertions(+), 11 deletions(-)

diff --git a/drivers/clk/clk-uclass.c b/drivers/clk/clk-uclass.c
index bd18de972bb9..bfad71e7af70 100644
--- a/drivers/clk/clk-uclass.c
+++ b/drivers/clk/clk-uclass.c
@@ -656,7 +656,7 @@ int clk_set_parent(struct clk *clk, struct clk *parent)
 int clk_enable(struct clk *clk)
 {
 	const struct clk_ops *ops;
-	struct clk *clkp = NULL;
+	struct clk *clkp = NULL, *clk_parent;
 	int ret;
 
 	debug("%s(clk=%p name=%s)\n", __func__, clk, clk->dev->name);
@@ -672,9 +672,10 @@ int clk_enable(struct clk *clk)
 				clkp->enable_count++;
 				return 0;
 			}
-			if (clkp->dev->parent &&
-			    device_get_uclass_id(clkp->dev->parent) == UCLASS_CLK) {
-				ret = clk_enable(dev_get_clk_ptr(clkp->dev->parent));
+
+			clk_parent = clk_get_parent(clkp);
+			if (!IS_ERR_OR_NULL(clk_parent)) {
+				ret = clk_enable(clk_parent);
 				if (ret) {
 					printf("Enable %s failed\n",
 					       clkp->dev->parent->name);
@@ -747,13 +748,16 @@ int clk_disable(struct clk *clk)
 				return ret;
 		}
 
-		if (clkp && clkp->dev->parent &&
-		    device_get_uclass_id(clkp->dev->parent) == UCLASS_CLK) {
-			ret = clk_disable(dev_get_clk_ptr(clkp->dev->parent));
-			if (ret) {
-				printf("Disable %s failed\n",
-				       clkp->dev->parent->name);
-				return ret;
+		if (clkp) {
+			struct clk *clk_parent = clk_get_parent(clkp);
+
+			if (!IS_ERR_OR_NULL(clk_parent)) {
+				ret = clk_disable(clk_parent);
+				if (ret) {
+					printf("Disable %s failed\n",
+					       clkp->dev->parent->name);
+					return ret;
+				}
 			}
 		}
 	} else {

-- 
2.43.0

