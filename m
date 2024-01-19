From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 19 Jan 2024 21:32:04 +0800
Subject: [PATCH RFC 1/2] clk: ccf: Export clk_register_mux_table() in
 linux/clk-provider.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240119-b4-hisi-clk-v1-1-0694a8a52283@outlook.com>
References: <20240119-b4-hisi-clk-v1-0-0694a8a52283@outlook.com>
In-Reply-To: <20240119-b4-hisi-clk-v1-0-0694a8a52283@outlook.com>
To: Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705671123; l=885;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=3h8ikq29d5+Bqo7gJ0S7vR42AqQoXFXCNTI5MuvSkgs=;
 b=/6ACQS6kYSq1zhMPG9E/7vylE5X3UAVXvWZArpgFc4GH6H6PH5HKXMcNPYY+cS3KnPWaTAPFn
 UVo+LAzkQVSCiNWKhp+K8ytHv0dz3JC8FxnmxTOSOBTmUa13Q+qAeKw
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This function is used by HiSilicon Clock Framework.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 include/linux/clk-provider.h | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/include/linux/clk-provider.h b/include/linux/clk-provider.h
index b8acacd49e..952439ad39 100644
--- a/include/linux/clk-provider.h
+++ b/include/linux/clk-provider.h
@@ -247,6 +247,12 @@ struct clk *clk_register_mux(struct device *dev, const char *name,
 		void __iomem *reg, u8 shift, u8 width,
 		u8 clk_mux_flags);
 
+struct clk *clk_register_mux_table(struct device *dev, const char *name,
+		const char * const *parent_names, u8 num_parents,
+		unsigned long flags,
+		void __iomem *reg, u8 shift, u32 mask,
+		u8 clk_mux_flags, u32 *table);
+
 struct clk *clk_register_fixed_rate(struct device *dev, const char *name,
 				    ulong rate);
 

-- 
2.43.0

