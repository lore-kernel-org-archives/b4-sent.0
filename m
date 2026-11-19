From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 16:50:01 +0000
Subject: [PATCH] regmap: mmio: Don't attach the clock if clk_prepare()
 fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-regmap-mmio-attach-clk-v1-1-91291802ac53@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrDvQGNqiV5EuxmSio0YliVIQ7
 97YLt/i/wMiB+EIdXFA4F2iLHOGuhVgepo7RrHZUN7Lp1KqwsCdpxW9lwUpJTI9mmlEVz3Ivpz
 VmjTkeA3s5PMbN++/49YObNJ1g/P8AhNfZa16AAAA
X-Change-ID: 20261119-regmap-mmio-attach-clk-f95ad7fd33a3
To: Mark Brown <broonie@kernel.org>
Cc: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Johan Hovold <johan@kernel.org>, Maxime Ripard <mripard@kernel.org>, 
 linux-kernel@vger.kernel.org, driver-core@lists.linux.dev, 
 stable@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795107001; l=1957;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=i99wsC+7/XSg8MNOgqgqgUZ46RlYbMj6RkR/Vf2Of1c=;
 b=9jiDl8QoEqCknvUZMfHJ+ua9PFRbCuLKzsSUKI6x99WZcMsI0+i45tMlgFNggee5UeHYEJgsp
 6iRbXf9hNrcBfAAPty5w9VsnUBkl6THsynckgmxjhPdAbA0acQ3h+t1
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

regmap_mmio_attach_clk() stores the clock before preparing it. If
clk_prepare() fails, regmap_exit() later unprepares a clock that was
never prepared, and the caller may already have put it.

Only attach the clock once it is prepared.

Fixes: 31895662f9ba ("regmap: mmio: Add function to attach a clock")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/r/179493691305.3136.16311404541139130213@kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Found while fixing the error path of of_syscon_register(); that mfd patch
is sent separately and neither depends on the other.

Tested on an Orange Pi 5 (RK3588S), 7.3 with KASAN, together with the mfd
patch: with a forced clk_prepare() failure in of_syscon_register(), a
use-after-free in clk_unprepare() is reported without the two patches and
nothing with both. This patch was not run on its own.

Developed with Claude (Anthropic), which wrote the code and the commit
message. I reviewed every change.
---
 drivers/base/regmap/regmap-mmio.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/base/regmap/regmap-mmio.c b/drivers/base/regmap/regmap-mmio.c
index 1de2278fa572..6adbc950877c 100644
--- a/drivers/base/regmap/regmap-mmio.c
+++ b/drivers/base/regmap/regmap-mmio.c
@@ -590,11 +590,16 @@ EXPORT_SYMBOL_GPL(__devm_regmap_init_mmio_clk);
 int regmap_mmio_attach_clk(struct regmap *map, struct clk *clk)
 {
 	struct regmap_mmio_context *ctx = map->bus_context;
+	int ret;
+
+	ret = clk_prepare(clk);
+	if (ret)
+		return ret;
 
 	ctx->clk = clk;
 	ctx->attached_clk = true;
 
-	return clk_prepare(ctx->clk);
+	return 0;
 }
 EXPORT_SYMBOL_GPL(regmap_mmio_attach_clk);
 

---
base-commit: 50b3d8bb527b11384153c4ca854c8610f4a55649
change-id: 20261119-regmap-mmio-attach-clk-f95ad7fd33a3

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

