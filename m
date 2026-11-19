From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 16:49:56 +0000
Subject: [PATCH] mfd: syscon: Put the clock after regmap_exit()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-syscon-clk-uaf-v1-1-dc4a4c1be353@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQqDMAyA4VeRnA2YQgfuVcRD7ZIt26jSqGyI7
 77qjt/h/zcwzsoG12qDzKuajqmA6griI6Q7o96KwTXuQkQt2tfimDC+X7gEQS/ifMuNBPJQoim
 z6Occdv3ftgxPjvNxgX3/AasTtmlyAAAA
X-Change-ID: 20261119-syscon-clk-uaf-5ff259e0fa15
To: Lee Jones <lee@kernel.org>, Arnd Bergmann <arnd@arndb.de>
Cc: Fabrice Gasnier <fabrice.gasnier@foss.st.com>, 
 Jeremy Kerr <jk@codeconstruct.com.au>, mfd@lists.linux.dev, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795106996; l=2258;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Xle/0X0eA0Wa8LPqfRsJuOjguZ9Uh3tFLZYrD/TPVc0=;
 b=CSfb7vPXlkbnKosHL34ELamSXGEOplysb5QTiVCvPbHPMuJkNOoLYHgzqU5XwlnEDa9kflzrR
 tEPKbFI7j9vBF0OOASG/uy9G7lt0p7E2xUVIEsYLHbr2QX63JuvTAI5
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the error path, of_syscon_register() puts the clock before
regmap_exit(), which then unprepares the freed clock. This happens
when the reset lookup fails, e.g. with -EPROBE_DEFER.

Put the clock after regmap_exit().

Fixes: a00406b71c5f ("mfd: syscon: Add optional clock support")
Fixes: 7d1e3bd94828 ("mfd: syscon: Allow reset control for syscon devices")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/r/179493691305.3136.16311404541139130213@kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
A related regmap patch ("regmap: mmio: Don't attach the clock if
clk_prepare() fails") is sent separately; neither depends on the other.

Tested on an Orange Pi 5 (RK3588S), 7.3 with KASAN, together with the
regmap patch: with a forced reset lookup failure, a use-after-free in
clk_unprepare() is reported without the two patches and nothing with both.

Developed with Claude (Anthropic), which wrote the code and the commit
message. I reviewed every change.
---
 drivers/mfd/syscon.c | 9 ++++-----
 1 file changed, 4 insertions(+), 5 deletions(-)

diff --git a/drivers/mfd/syscon.c b/drivers/mfd/syscon.c
index 21a7fcdd2737..3ff4e024542b 100644
--- a/drivers/mfd/syscon.c
+++ b/drivers/mfd/syscon.c
@@ -132,13 +132,13 @@ static struct syscon *of_syscon_register(struct device_node *np, bool check_res)
 		} else {
 			ret = regmap_mmio_attach_clk(regmap, clk);
 			if (ret)
-				goto err_attach_clk;
+				goto err_clk;
 		}
 
 		reset = of_reset_control_get_optional_exclusive(np, NULL);
 		if (IS_ERR(reset)) {
 			ret = PTR_ERR(reset);
-			goto err_attach_clk;
+			goto err_clk;
 		}
 
 		ret = reset_control_deassert(reset);
@@ -155,11 +155,10 @@ static struct syscon *of_syscon_register(struct device_node *np, bool check_res)
 
 err_reset:
 	reset_control_put(reset);
-err_attach_clk:
-	if (!IS_ERR(clk))
-		clk_put(clk);
 err_clk:
 	regmap_exit(regmap);
+	if (!IS_ERR(clk))
+		clk_put(clk);
 err_regmap:
 	iounmap(base);
 	return ERR_PTR(ret);

---
base-commit: e5bcc8e02e570e3eee46d4cebefd552cc7c9e843
change-id: 20261119-syscon-clk-uaf-5ff259e0fa15

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

