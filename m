From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 18 Aug 2023 01:04:03 +0800
Subject: [PATCH RESEND 4/5] clk: promote clk_dev_ops to
 linux/clk-provider.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230818-clk-fix-v1-4-49ec18f820bf@outlook.com>
References: <20230818-clk-fix-v1-0-49ec18f820bf@outlook.com>
In-Reply-To: <20230818-clk-fix-v1-0-49ec18f820bf@outlook.com>
To: Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1692291852; l=1308;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=AsXbGKWGRqE3lMjTv3H8xZIwt4yI2mwPFQ61gXMGbNI=;
 b=fayyID6emo5avyU30zRUPRyYSoRpenqpatkddd/geJBHfYiNS1S3MRgy1EU9KzCSHiR9zzLlw
 V7lGGLJ5nz+BpXY8ooDmagzV4YaqXhtVobgboCSqGJNavmH+urkNLZq
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

So that it can be used by others.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/clk-uclass.c     | 5 -----
 include/linux/clk-provider.h | 5 +++++
 2 files changed, 5 insertions(+), 5 deletions(-)

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
diff --git a/include/linux/clk-provider.h b/include/linux/clk-provider.h
index 801404480b..dfafb4cc9d 100644
--- a/include/linux/clk-provider.h
+++ b/include/linux/clk-provider.h
@@ -21,6 +21,11 @@ static inline void clk_dm(ulong id, struct clk *clk)
 		clk->id = id;
 }
 
+static inline const struct clk_ops *clk_dev_ops(struct udevice *dev)
+{
+	return (const struct clk_ops *)dev->driver->ops;
+}
+
 /*
  * flags used across common struct clk.  these flags should only affect the
  * top-level framework.  custom flags for dealing with hardware specifics

-- 
2.34.1

