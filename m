From: Chuan Liu <chuan.liu@amlogic.com>
Date: Sun, 29 Sep 2024 14:10:05 +0800
Subject: [PATCH 1/2] clk: Fix the CLK_IGNORE_UNUSED failure issue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240929-fix_glitch_free-v1-1-22f9c36b7edf@amlogic.com>
References: <20240929-fix_glitch_free-v1-0-22f9c36b7edf@amlogic.com>
In-Reply-To: <20240929-fix_glitch_free-v1-0-22f9c36b7edf@amlogic.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-amlogic@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727590225; l=3496;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=j5nGks4RjMSPPYGFi+WoyylasN/sh7VgSzlGbwQyCJI=;
 b=QtvHpMbFuOIo/UK7CYtXIo11eZTGd+CWmoLcQrFkTWX/ZNF71z6QjhvRubudSx/KOMxNYM3TQ
 rCW5pbw2T0bCkhikgDPU6TxTQ7bPJUSAs/vbPKX2cfp1JR8FR89SO4f
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the clk_disable_unused_subtree() function disables an unused clock,
if CLK_OPS_PARENT_ENABLE is configured on the clock,
clk_core_prepare_enable() and clk_core_disable_unprepare() are called
directly, and these two functions do not determine CLK_IGNORE_UNUSED,
This causes the clock to be disabled even if CLK_IGNORE_UNUSED is
configured when clk_core_disable_unprepare() is called.

Two new functions clk_disable_unprepare_unused() and
clk_prepare_enable_unused() are added to resolve the preceding
situation. The CLK_IGNORE_UNUSED judgment logic is added to these two
functions. To prevent clock configuration CLK_IGNORE_UNUSED from
possible failure.

Change-Id: I56943e17b86436254f07d9b8cdbc35599328d519
Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/clk.c | 67 +++++++++++++++++++++++++++++++++++++++++++++++++++++--
 1 file changed, 65 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/clk.c b/drivers/clk/clk.c
index 285ed1ad8a37..5d3316699b57 100644
--- a/drivers/clk/clk.c
+++ b/drivers/clk/clk.c
@@ -94,6 +94,7 @@ struct clk_core {
 	struct hlist_node	debug_node;
 #endif
 	struct kref		ref;
+	bool			ignore_enabled;
 };
 
 #define CREATE_TRACE_POINTS
@@ -1479,6 +1480,68 @@ static void __init clk_unprepare_unused_subtree(struct clk_core *core)
 	}
 }
 
+static void __init clk_disable_unprepare_unused(struct clk_core *core)
+{
+	unsigned long flags;
+
+	lockdep_assert_held(&prepare_lock);
+
+	if (!core)
+		return;
+
+	if ((core->enable_count == 0) && core->ops->disable &&
+	    !core->ignore_enabled) {
+		flags = clk_enable_lock();
+		core->ops->disable(core->hw);
+		clk_enable_unlock(flags);
+	}
+
+	if ((core->prepare_count == 0) && core->ops->unprepare &&
+	    !core->ignore_enabled)
+		core->ops->unprepare(core->hw);
+
+	core->ignore_enabled = false;
+
+	clk_disable_unprepare_unused(core->parent);
+}
+
+static int __init clk_prepare_enable_unused(struct clk_core *core)
+{
+	int ret = 0;
+	unsigned long flags;
+
+	lockdep_assert_held(&prepare_lock);
+
+	if (!core)
+		return 0;
+
+	ret = clk_prepare_enable_unused(core->parent);
+	if (ret)
+		return ret;
+
+	if ((core->flags & CLK_IGNORE_UNUSED) && clk_core_is_enabled(core))
+		core->ignore_enabled = true;
+
+	if ((core->prepare_count == 0) && core->ops->prepare) {
+		ret = core->ops->prepare(core->hw);
+		if (ret)
+			goto disable_unprepare;
+	}
+
+	if ((core->enable_count == 0) && core->ops->enable) {
+		flags = clk_enable_lock();
+		ret = core->ops->enable(core->hw);
+		clk_enable_unlock(flags);
+		if (ret)
+			goto disable_unprepare;
+	}
+
+	return 0;
+disable_unprepare:
+	clk_disable_unprepare_unused(core->parent);
+	return ret;
+}
+
 static void __init clk_disable_unused_subtree(struct clk_core *core)
 {
 	struct clk_core *child;
@@ -1490,7 +1553,7 @@ static void __init clk_disable_unused_subtree(struct clk_core *core)
 		clk_disable_unused_subtree(child);
 
 	if (core->flags & CLK_OPS_PARENT_ENABLE)
-		clk_core_prepare_enable(core->parent);
+		clk_prepare_enable_unused(core->parent);
 
 	flags = clk_enable_lock();
 
@@ -1517,7 +1580,7 @@ static void __init clk_disable_unused_subtree(struct clk_core *core)
 unlock_out:
 	clk_enable_unlock(flags);
 	if (core->flags & CLK_OPS_PARENT_ENABLE)
-		clk_core_disable_unprepare(core->parent);
+		clk_disable_unprepare_unused(core->parent);
 }
 
 static bool clk_ignore_unused __initdata;

-- 
2.42.0

