From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Wed, 04 Sep 2024 14:41:07 +0300
Subject: [PATCH] clk: fixed-rate: add
 devm_clk_hw_register_fixed_rate_parent_data()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240904-devm_clk_hw_register_fixed_rate_parent_data-v1-1-7f14d6b456e5@maquefel.me>
X-B4-Tracking: v=1; b=H4sIAFJH2GYC/xWNUQqDMBAFryL73UCSBsRepZQlmKcubVPZBFsQ7
 974NwPDezsVqKDQrdtJsUmRT27iLh2NS8wzjKTm5K0PdrDBJGxvHl9PXr6smKVUKE/yQ2KNFbx
 GRa6cYo0m+dC7q3VDA2qLq+Isz7f74zj+9tGLEX0AAAA=
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nikita Shubin <nikita.shubin@maquefel.me>
X-Mailer: b4 0.15-dev-99b12
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725450072; l=1857;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=J7DnDW2A1MJFcbrAhVPLzVkKMJjwXrfE3ffVHEB0sZk=;
 b=6R2yziTvOZcOMtb4T1iRVn+0YljewW1VpSDEBwPBRoKPOwJuM9m5JVIHPVlr+OiLsyX+vUztfo8P
 Hbn+Gd+YA8FU/lpKFKd0cUCeN3tlYwgkIFo3hFFdju+tLwI8Mo+J
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devm_clk_hw_register_fixed_rate_parent_data(), devres-managed helper
to register fixed-rate clock with parent_data.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
Hello Stephen!

Sending devm version of clk_hw_register_fixed_rate_parent_data(),
as promised in:

https://lore.kernel.org/lkml/79cb209c6c5a14ae4d6a015f714c58d4.sboyd@kernel.org/
---
 include/linux/clk-provider.h | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/include/linux/clk-provider.h b/include/linux/clk-provider.h
index 4a537260f655..7e43caabb54b 100644
--- a/include/linux/clk-provider.h
+++ b/include/linux/clk-provider.h
@@ -393,6 +393,20 @@ struct clk *clk_register_fixed_rate(struct device *dev, const char *name,
 #define devm_clk_hw_register_fixed_rate(dev, name, parent_name, flags, fixed_rate)  \
 	__clk_hw_register_fixed_rate((dev), NULL, (name), (parent_name), NULL, \
 				     NULL, (flags), (fixed_rate), 0, 0, true)
+/**
+ * devm_clk_hw_register_fixed_rate_parent_data - register fixed-rate clock with
+ * the clock framework
+ * @dev: device that is registering this clock
+ * @name: name of this clock
+ * @parent_data: parent clk data
+ * @flags: framework-specific flags
+ * @fixed_rate: non-adjustable clock rate
+ */
+#define devm_clk_hw_register_fixed_rate_parent_data(dev, name, parent_data, flags, \
+						    fixed_rate)			   \
+	__clk_hw_register_fixed_rate((dev), NULL, (name), NULL, NULL,		   \
+				     (parent_data), (flags), (fixed_rate), 0,	   \
+				     0, true)
 /**
  * clk_hw_register_fixed_rate_parent_hw - register fixed-rate clock with
  * the clock framework

---
base-commit: 88fac17500f4ea49c7bac136cf1b27e7b9980075
change-id: 20240904-devm_clk_hw_register_fixed_rate_parent_data-d24713019d24

Best regards,
-- 
Nikita Shubin <nikita.shubin@maquefel.me>

