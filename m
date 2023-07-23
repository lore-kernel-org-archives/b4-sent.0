From: Yang Xiwen <forbidden405@outlook.com>
Date: Mon, 24 Jul 2023 05:16:54 +0800
Subject: [PATCH 1/2] clk: move clk_get_ops() to a common header
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230724-clk_fix-v1-1-283f5b427070@outlook.com>
References: <20230724-clk_fix-v1-0-283f5b427070@outlook.com>
In-Reply-To: <20230724-clk_fix-v1-0-283f5b427070@outlook.com>
To: Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1690147024; l=1786;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=gqsm5+i6j843YHJZqqbmxri0YIZSUslipmx3K/Wqh6Y=;
 b=wyzTIhRCHyaUIPjU1dKM7rEVw8pRPjd8T4EsPXkar7aNwV8Wr88FMPYWy6BoYSESiXM/R7KZs
 An29/YvgxN7B6NRmhuw5Bs7x308FO+/wz+uS3LiMxj2ywyArz16I+cD
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This allows it to be used by other source files.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/clk-uclass.c |  5 -----
 include/clk.h            | 17 +++++++++++++++++
 2 files changed, 17 insertions(+), 5 deletions(-)

diff --git a/drivers/clk/clk-uclass.c b/drivers/clk/clk-uclass.c
index dc3e9d6a26..5cc80e5e39 100644
--- a/drivers/clk/clk-uclass.c
+++ b/drivers/clk/clk-uclass.c
@@ -25,11 +25,6 @@
 #include <linux/clk-provider.h>
 #include <linux/err.h>
 
-static inline const struct clk_ops *clk_dev_ops(struct udevice *dev)
-{
-	return (const struct clk_ops *)dev->driver->ops;
-}
-
 struct clk *dev_get_clk_ptr(struct udevice *dev)
 {
 	return (struct clk *)dev_get_uclass_priv(dev);
diff --git a/include/clk.h b/include/clk.h
index d91285235f..bd3617e1e0 100644
--- a/include/clk.h
+++ b/include/clk.h
@@ -8,6 +8,7 @@
 #ifndef _CLK_H_
 #define _CLK_H_
 
+#include <dm/device.h>
 #include <dm/ofnode.h>
 #include <linux/err.h>
 #include <linux/errno.h>
@@ -258,6 +259,17 @@ int clk_release_all(struct clk *clk, int count);
  */
 void devm_clk_put(struct udevice *dev, struct clk *clk);
 
+/**
+ * clk_dev_ops - get ops of a clock
+ * @dev: clock device
+ *
+ * Return: ops of the clk
+ */
+static inline const struct clk_ops *clk_dev_ops(struct udevice *dev)
+{
+	return (const struct clk_ops *)dev->driver->ops;
+}
+
 #else
 
 static inline int clk_get_by_phandle(struct udevice *dev, const
@@ -315,6 +327,11 @@ static inline int clk_release_all(struct clk *clk, int count)
 static inline void devm_clk_put(struct udevice *dev, struct clk *clk)
 {
 }
+
+static inline const struct clk_ops *clk_dev_ops(struct udevice *dev)
+{
+	return ERR_PTR(-ENOSYS);
+}
 #endif
 
 /**

-- 
2.34.1

