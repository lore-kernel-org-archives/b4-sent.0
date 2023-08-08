From: Yang Xiwen <forbidden405@outlook.com>
Date: Wed, 09 Aug 2023 00:37:43 +0800
Subject: [PATCH 3/5] clk: also handle ENOENT in *_optional functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230809-clk-fix-v1-3-808dbae54e5e@outlook.com>
References: <20230809-clk-fix-v1-0-808dbae54e5e@outlook.com>
In-Reply-To: <20230809-clk-fix-v1-0-808dbae54e5e@outlook.com>
To: Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1691512665; l=1405;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=Ya3s56yb/uYzBObmNpjkiNoe6oNIwyGOQ0sokgx66Jo=;
 b=jI0J0n3agJg5Lgv8zhuC864GEF2t4EuoxuyzXNA+ajXOf8h3Zx/TnuduQmkaQLsE+/2jCfqfg
 epBtBJO8PVNAC2xtn2Uu/cy7cBAS6G9tPmkLaR68NX3F/lEsddOVC9v
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the device does not specify any clocks in device tree, these
functions will return PTR_ERR(-ENOENT). This is not the intended
behavior and does not comply with linux kernel CCF. Fix that by
returning NULL under such circumstances instead.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 include/clk.h | 8 +++++---
 1 file changed, 5 insertions(+), 3 deletions(-)

diff --git a/include/clk.h b/include/clk.h
index d91285235f..f95da0838d 100644
--- a/include/clk.h
+++ b/include/clk.h
@@ -223,9 +223,11 @@ struct clk *devm_clk_get(struct udevice *dev, const char *id);
 static inline struct clk *devm_clk_get_optional(struct udevice *dev,
 						const char *id)
 {
+	int ret;
 	struct clk *clk = devm_clk_get(dev, id);
 
-	if (PTR_ERR(clk) == -ENODATA)
+	ret = PTR_ERR(clk);
+	if (ret == -ENODATA || ret == -ENOENT)
 		return NULL;
 
 	return clk;
@@ -335,7 +337,7 @@ static inline int clk_get_by_name_optional(struct udevice *dev,
 	int ret;
 
 	ret = clk_get_by_name(dev, name, clk);
-	if (ret == -ENODATA)
+	if (ret == -ENODATA || ret == -ENOENT)
 		return 0;
 
 	return ret;
@@ -359,7 +361,7 @@ static inline int clk_get_by_name_nodev_optional(ofnode node, const char *name,
 	int ret;
 
 	ret = clk_get_by_name_nodev(node, name, clk);
-	if (ret == -ENODATA)
+	if (ret == -ENODATA || ret == -ENOENT)
 		return 0;
 
 	return ret;

-- 
2.34.1

