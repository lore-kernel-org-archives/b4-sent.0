From: Shmuel Leib Melamud <smelamud@redhat.com>
Date: Wed, 11 Jun 2025 03:25:51 +0300
Subject: [PATCH v4 1/2] clk: renesas: Handle CLK_TYPE_GEN4_MDSEL in
 gen3_clk_get_rate64()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250611-us-renesas-watchdog-v4-1-24f1da3e0dc9@redhat.com>
References: <20250611-us-renesas-watchdog-v4-0-24f1da3e0dc9@redhat.com>
In-Reply-To: <20250611-us-renesas-watchdog-v4-0-24f1da3e0dc9@redhat.com>
To: Nobuhiro Iwamatsu <iwamatsu@nigauri.org>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>, 
 Tom Rini <trini@konsulko.com>, Stefan Roese <sr@denx.de>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>
Cc: u-boot@lists.denx.de, Shmuel Leib Melamud <smelamud@redhat.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749601573; l=1472;
 i=smelamud@redhat.com; s=20250530; h=from:subject:message-id;
 bh=4oFxvFp4W6ljnPsK+XQfAQZ4LOcEGyVg+i/xjN5S4EQ=;
 b=YIzcOcoDXFWluWdAPFiXwxHRCaXC7CJBHqNrGAvZnyckKCby1mEgPOfLBh5xBYvuWNU2nUahi
 qEb35DdIuKKCrDGyTu9lGsTiCrYPJhjdU/GrPnXktv0VIB6846BvjGf
X-Developer-Key: i=smelamud@redhat.com; a=ed25519;
 pk=B1DFtpdxDPQudtnqMHSFRRSJziu3zB49J6oZUBo0qI8=
X-Endpoint-Received: by B4 Relay for smelamud@redhat.com/20250530 with auth_id=418
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support of CLK_TYPE_GEN4_MDSEL clock type to gen3_clk_get_rate64()
function. In particular, this type of clock is used by Renesas R-Car
Gen4 watchdog. It operates similarly to CLK_TYPE_GEN3_MDSEL clock.

Signed-off-by: Shmuel Leib Melamud <smelamud@redhat.com>
Reviewed-by: Mattijs Korpershoek <mkorpershoek@kernel.org>
Reviewed-by: Marek Vasut <marek.vasut+renesas@mailbox.org>
---
 drivers/clk/renesas/clk-rcar-gen3.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/renesas/clk-rcar-gen3.c b/drivers/clk/renesas/clk-rcar-gen3.c
index 375cc4a4930873ad0d5509c19ad04a0ea5545aa0..5745acf4023c9114f6fa13b5e4baa306c5b57d33 100644
--- a/drivers/clk/renesas/clk-rcar-gen3.c
+++ b/drivers/clk/renesas/clk-rcar-gen3.c
@@ -68,7 +68,7 @@ static int gen3_clk_get_parent(struct gen3_clk_priv *priv, struct clk *clk,
 		if (ret)
 			return ret;
 
-		if (core->type == CLK_TYPE_GEN3_MDSEL) {
+		if (core->type == CLK_TYPE_GEN3_MDSEL || core->type == CLK_TYPE_GEN4_MDSEL) {
 			shift = priv->cpg_mode & BIT(core->offset) ? 0 : 16;
 			parent->dev = clk->dev;
 			parent->id = core->parent >> shift;
@@ -318,6 +318,8 @@ static u64 gen3_clk_get_rate64(struct clk *clk)
 						"FIXED");
 
 	case CLK_TYPE_GEN3_MDSEL:
+		fallthrough;
+	case CLK_TYPE_GEN4_MDSEL:
 		shift = priv->cpg_mode & BIT(core->offset) ? 0 : 16;
 		div = (core->div >> shift) & 0xffff;
 		rate = gen3_clk_get_rate64(&parent) / div;

-- 
2.49.0

