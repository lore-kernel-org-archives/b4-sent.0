From: Yang Xiwen <forbidden405@outlook.com>
Date: Tue, 25 Jul 2023 01:32:12 +0800
Subject: [PATCH] clk: also return NULL for -ENOENT in devm_clk_get_optional
 functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230725-clk-fix-inc-v1-1-576264387af6@outlook.com>
X-B4-Tracking: v=1; b=H4sIAJu1vmQC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI2MDcyNT3eScbN20zArdzLxkXUsD48REA1MTA3NjSyWgjoKiVKAU2LTo2Np
 aAK0dz8ldAAAA
To: Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1690219932; l=1302;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=ZvfvGvaJnk9my+mtRSD7Rnu5/VqTO/doGeVmScrqSkQ=;
 b=Q4bijrBC12ZtbsFUxS1kQ7QsBTDbWCY+PlO+lDJWXqGruwpyQU0/JZyi76lS4w2+ECQ5i69lj
 iaR9UspOFn1Dr/2SnIM6t3ViQWfx1/4hkUc2bKp+/soLVzpVZnhuCEP
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As described by the doc.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Handle both ENODATA and ENOENT.
---
 include/clk.h | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)

diff --git a/include/clk.h b/include/clk.h
index d91285235f..c9aa2360e1 100644
--- a/include/clk.h
+++ b/include/clk.h
@@ -224,8 +224,9 @@ static inline struct clk *devm_clk_get_optional(struct udevice *dev,
 						const char *id)
 {
 	struct clk *clk = devm_clk_get(dev, id);
+	int ret = PTR_ERR(clk);
 
-	if (PTR_ERR(clk) == -ENODATA)
+	if (ret == -ENODATA || ret == -ENOENT)
 		return NULL;
 
 	return clk;
@@ -335,7 +336,7 @@ static inline int clk_get_by_name_optional(struct udevice *dev,
 	int ret;
 
 	ret = clk_get_by_name(dev, name, clk);
-	if (ret == -ENODATA)
+	if (ret == -ENODATA || ret == -ENOENT)
 		return 0;
 
 	return ret;
@@ -359,7 +360,7 @@ static inline int clk_get_by_name_nodev_optional(ofnode node, const char *name,
 	int ret;
 
 	ret = clk_get_by_name_nodev(node, name, clk);
-	if (ret == -ENODATA)
+	if (ret == -ENODATA || ret == -ENOENT)
 		return 0;
 
 	return ret;

---
base-commit: 580eb31199be8a822e62f20965854a242f895d03
change-id: 20230725-clk-fix-inc-903aa0540739

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

