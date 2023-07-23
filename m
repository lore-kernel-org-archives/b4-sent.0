From: Yang Xiwen <forbidden405@outlook.com>
Date: Mon, 24 Jul 2023 05:16:55 +0800
Subject: [PATCH 2/2] clk: ccf: invoke ops provided by clk directly
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230724-clk_fix-v1-2-283f5b427070@outlook.com>
References: <20230724-clk_fix-v1-0-283f5b427070@outlook.com>
In-Reply-To: <20230724-clk_fix-v1-0-283f5b427070@outlook.com>
To: Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1690147024; l=1144;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=JP4zaTIzokdks3s8U9GOplONTe4iUmPO05hIETDcfV4=;
 b=ld4jUfPxtIWc/PGWYcCTSbXh3bNoYh29aJVvpUpInCvfCPNGly9je63xC7pw2374Z83F3cKUG
 45balCrjtXBARpdkMxcO+7Yv1N5EUYA1iGLOovaZD31lFm3V51kgsLq
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Invoking clk_enable() or clk_disable() in clk->ops context causes a
recursion, results in a clock being enabled twice.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/clk.c | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/clk.c b/drivers/clk/clk.c
index a5a3461b66..bd455e44a4 100644
--- a/drivers/clk/clk.c
+++ b/drivers/clk/clk.c
@@ -10,7 +10,6 @@
 #include <clk.h>
 #include <clk-uclass.h>
 #include <log.h>
-#include <dm/device.h>
 #include <dm/uclass.h>
 #include <dm/lists.h>
 #include <dm/device-internal.h>
@@ -115,11 +114,18 @@ int ccf_clk_set_parent(struct clk *clk, struct clk *parent)
 static int ccf_clk_endisable(struct clk *clk, bool enable)
 {
 	struct clk *c;
+	const struct clk_ops *ops = clk_dev_ops(clk->dev);
 	int err = clk_get_by_id(clk->id, &c);
 
 	if (err)
 		return err;
-	return enable ? clk_enable(c) : clk_disable(c);
+
+	if (enable && ops->enable)
+		return ops->enable(c);
+	else if (!enable && ops->disable)
+		return ops->disable(c);
+
+	return 0;
 }
 
 int ccf_clk_enable(struct clk *clk)

-- 
2.34.1

