From: Cunhao Lu <1579567540@qq.com>
Date: Fri, 30 Oct 2026 17:43:59 +0800
Subject: [PATCH v5 3/4] clk: rockchip: Add composite clock macro with mux
 table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-add-board-ok3572-c-clk-v5-3-9a43403cb149@qq.com>
References: <20261030-add-board-ok3572-c-clk-v5-0-9a43403cb149@qq.com>
In-Reply-To: <20261030-add-board-ok3572-c-clk-v5-0-9a43403cb149@qq.com>
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Elaine Zhang <zhangqing@rock-chips.com>, 
 Richard Cochran <richardcochran@gmail.com>
Cc: Cunhao Lu <1579567540@qq.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 netdev@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793353906; l=1536;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=5um5DvzGZ7NXY6308q7TLtQUZ+TSSmWq3dE0E24Czn4=;
 b=VG4JhmherdSJQ6Wt+860xnxVklWfiy/pC3b4pbpLDrn6mJNkwwQugYH1k2IkD8oHuVsKCDcFG
 x2YZkUemy5tCAKCe0J7VT7xmLoBN3URaUOsDo66SyUMAfe74OUCnm+f
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Elaine Zhang <zhangqing@rock-chips.com>

Some Rockchip composite clocks use mux selector values that do not
match the order of their parent clocks.

Add COMPOSITE_MUXTBL to describe the parent-to-selector mapping along
with the divider and gate. The RK3572 audio clocks use this layout.

Signed-off-by: Elaine Zhang <zhangqing@rock-chips.com>
Signed-off-by: Cunhao Lu <1579567540@qq.com>

---
Changes in v4:
- Split this helper out of the RK3572 driver patch.
---
 drivers/clk/rockchip/clk.h | 22 ++++++++++++++++++++++
 1 file changed, 22 insertions(+)

diff --git a/drivers/clk/rockchip/clk.h b/drivers/clk/rockchip/clk.h
index dce4db3f67b0..bc3a1def679b 100644
--- a/drivers/clk/rockchip/clk.h
+++ b/drivers/clk/rockchip/clk.h
@@ -871,6 +871,28 @@ struct rockchip_clk_branch {
 		.gate_flags	= gf,				\
 	}
 
+#define COMPOSITE_MUXTBL(_id, cname, pnames, f, mo, ms, mw, mf,	\
+			 mt, ds, dw, df, go, gs, gf)		\
+	{							\
+		.id		= _id,				\
+		.branch_type	= branch_composite,		\
+		.name		= cname,			\
+		.parent_names	= pnames,			\
+		.num_parents	= ARRAY_SIZE(pnames),		\
+		.flags		= f,				\
+		.muxdiv_offset	= mo,				\
+		.mux_shift	= ms,				\
+		.mux_width	= mw,				\
+		.mux_flags	= mf,				\
+		.mux_table	= mt,				\
+		.div_shift	= ds,				\
+		.div_width	= dw,				\
+		.div_flags	= df,				\
+		.gate_offset	= go,				\
+		.gate_shift	= gs,				\
+		.gate_flags	= gf,				\
+	}
+
 #define COMPOSITE_DIV_OFFSET(_id, cname, pnames, f, mo, ms, mw,	\
 			     mf, do, ds, dw, df, go, gs, gf)	\
 	{							\

-- 
2.34.1

