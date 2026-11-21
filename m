From: Suyuan Wang <shyckless@gmail.com>
Date: Sat, 21 Nov 2026 10:45:12 +0000
Subject: [PATCH] clk: renesas: rzg2l: Don't mark a coupled clock enabled if
 enabling fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-rzg2l-coupled-clk-v1-1-c38c8299c176@gmail.com>
X-B4-Tracking: v=1; b=H4sIADh2AWsC/yXMTQqDMBBA4avIrDtg4k+gVyld6GTUsUElURHFu
 5vq8lu8d0BgLxzgnRzgeZUg4xChXglQVw0to9ho0KkuldIK/d5qhzQuk2OL5H5YUmMKm5rM5Ay
 xmzw3st3Pz/dxWOqeaf6P4DwvpwpJMnUAAAA=
X-Change-ID: 20261121-rzg2l-coupled-clk-6cf75d07374e
To: sboyd@kernel.org, geert+renesas@glider.be
Cc: linux-renesas-soc@vger.kernel.org, biju.das.jz@bp.renesas.com, 
 linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 jbrunet+clk@baylibre.com, bmasney+clk@redhat.com, 
 prabhakar.mahadev-lad.rj@bp.renesas.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795257912; l=2447;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=3y15QbBzV0RnkTxoTog+ECpsMR9NS7LppzilDPoTG4k=;
 b=rBqqHHjt9+erqhzDjInR2FFJQu+aaY9fmkYHpZb5dHmxnwctDJWsFGz6zgxPgOIp3Fq5F0a2B
 G8yjBTFWrESCs7jEMOcOAQwdPIlUM0WYIb1FlUMr3Hprq1eCWbt+baM
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

For coupled clocks, rzg2l_mod_clock_enable() sets clock->enabled before
it touches the hardware, so that the sibling can see it:

	clock->enabled = true;
	...
	return rzg2l_mod_clock_endisable(hw, true);

If rzg2l_mod_clock_endisable() then fails, for example because polling
the CLK_MON bit times out, the flag stays set. The clock core does not
count the clock as enabled or call its disable callback when enabling
fails, so nothing clears the flag for this failed enable.

A later enable of the sibling then sees the stale flag and returns
success without enabling or checking the hardware. Disabling that
sibling skips the shared clock bit as well, because the failed clock
still looks enabled.

Clear the flag again when enabling fails.

Found with a static analysis tool and checked by hand.

Fixes: 32897e6fff19 ("clk: renesas: rzg2l: Add support to handle coupled clocks")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested on arm64 with clang (W=1, no new warnings). I don't have an RZ/G2L board.
---
 drivers/clk/renesas/rzg2l-cpg.c | 15 ++++++++++++---
 1 file changed, 12 insertions(+), 3 deletions(-)

diff --git a/drivers/clk/renesas/rzg2l-cpg.c b/drivers/clk/renesas/rzg2l-cpg.c
index dc2bcbab18f1..18c4ed362295 100644
--- a/drivers/clk/renesas/rzg2l-cpg.c
+++ b/drivers/clk/renesas/rzg2l-cpg.c
@@ -2080,10 +2080,11 @@ static int rzg2l_mod_clock_endisable(struct clk_hw *hw, bool enable)
 static int rzg2l_mod_clock_enable(struct clk_hw *hw)
 {
 	struct mod_clock *clock = to_mod_clock(hw);
+	struct rzg2l_cpg_priv *priv = clock->priv;
+	unsigned long flags;
+	int ret;
 
 	if (clock->sibling) {
-		struct rzg2l_cpg_priv *priv = clock->priv;
-		unsigned long flags;
 		bool enabled;
 
 		spin_lock_irqsave(&priv->rmw_lock, flags);
@@ -2094,7 +2095,15 @@ static int rzg2l_mod_clock_enable(struct clk_hw *hw)
 			return 0;
 	}
 
-	return rzg2l_mod_clock_endisable(hw, true);
+	ret = rzg2l_mod_clock_endisable(hw, true);
+	if (ret && clock->sibling) {
+		/* the clock core will not disable it, so don't count it */
+		spin_lock_irqsave(&priv->rmw_lock, flags);
+		clock->enabled = false;
+		spin_unlock_irqrestore(&priv->rmw_lock, flags);
+	}
+
+	return ret;
 }
 
 static void rzg2l_mod_clock_disable(struct clk_hw *hw)



