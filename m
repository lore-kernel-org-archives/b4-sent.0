From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 18 Aug 2023 01:04:00 +0800
Subject: [PATCH RESEND 1/5] clk: export clk_register_mux_table()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230818-clk-fix-v1-1-49ec18f820bf@outlook.com>
References: <20230818-clk-fix-v1-0-49ec18f820bf@outlook.com>
In-Reply-To: <20230818-clk-fix-v1-0-49ec18f820bf@outlook.com>
To: Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1692291852; l=922;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=rrxWAZujevzzupl/nb4QWkR3QDVpqMIWdYkkWfQ6VWg=;
 b=p+Dym4mN6QSYD5cD/WWkx0ItGmcKQP+RF00a0c3G0z85VcPDKFNNGExqXyUKTqsghT5lyVEnk
 3MVA6fdSqeYC2xQVXWMzVzalgygVemwDIgfl/78ukSb/vsE6TGxpJVZ
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It's already implemented in clk-mux.c, export it in the header file.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 include/linux/clk-provider.h | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/include/linux/clk-provider.h b/include/linux/clk-provider.h
index b8acacd49e..801404480b 100644
--- a/include/linux/clk-provider.h
+++ b/include/linux/clk-provider.h
@@ -247,6 +247,12 @@ struct clk *clk_register_mux(struct device *dev, const char *name,
 		void __iomem *reg, u8 shift, u8 width,
 		u8 clk_mux_flags);
 
+struct clk *clk_register_mux_table(struct device *dev, const char *name,
+				   const char * const *parent_names, u8 num_parents,
+				   unsigned long flags,
+				   void __iomem *reg, u8 shift, u32 mask,
+				   u8 clk_mux_flags, u32 *table);
+
 struct clk *clk_register_fixed_rate(struct device *dev, const char *name,
 				    ulong rate);
 

-- 
2.34.1

