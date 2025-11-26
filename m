From: Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
Date: Wed, 26 Nov 2025 08:08:09 +0100
Subject: [PATCH v4 1/2] hwrng: imx-rngc: Use optional clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251126-b4-m5441x-add-rng-support-v4-1-5309548c9555@yoseli.org>
References: <20251126-b4-m5441x-add-rng-support-v4-0-5309548c9555@yoseli.org>
In-Reply-To: <20251126-b4-m5441x-add-rng-support-v4-0-5309548c9555@yoseli.org>
To: Greg Ungerer <gerg@linux-m68k.org>, 
 Geert Uytterhoeven <geert@linux-m68k.org>, 
 Olivia Mackall <olivia@selenic.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: linux-m68k@lists.linux-m68k.org, linux-kernel@vger.kernel.org, 
 linux-crypto@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, 
 Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764140889; l=974;
 i=jeanmichel.hautbois@yoseli.org; s=20240925; h=from:subject:message-id;
 bh=6yowbDUcruSfT+pB3Hc8Rr8mGdRNN9tkk1YhS+Cu13k=;
 b=fi8KOrh8x9MJfniLee28k496XKjc9mUk+IoZmDHr0DpuL04GI71pXFWvmFsY/KGQjSwyFbnxq
 E+ffkN+R57RDfwfb6dh9Wr/mo9+on+eini+nsUKg/RpJ9EDd3k1D+Tu
X-Developer-Key: i=jeanmichel.hautbois@yoseli.org; a=ed25519;
 pk=MsMTVmoV69wLIlSkHlFoACIMVNQFyvJzvsJSQsn/kq4=
X-Endpoint-Received: by B4 Relay for jeanmichel.hautbois@yoseli.org/20240925 with auth_id=570
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Change devm_clk_get() to devm_clk_get_optional() to support platforms
where the RNG clock is always enabled and not exposed via the clock
framework (such as ColdFire MCF54418).

Reviewed-by: Frank Li <Frank.Li@nxp.com>
Signed-off-by: Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
---
 drivers/char/hw_random/imx-rngc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/char/hw_random/imx-rngc.c b/drivers/char/hw_random/imx-rngc.c
index 241664a9b5d9..d6a847e48339 100644
--- a/drivers/char/hw_random/imx-rngc.c
+++ b/drivers/char/hw_random/imx-rngc.c
@@ -259,7 +259,7 @@ static int __init imx_rngc_probe(struct platform_device *pdev)
 	if (IS_ERR(rngc->base))
 		return PTR_ERR(rngc->base);
 
-	rngc->clk = devm_clk_get(&pdev->dev, NULL);
+	rngc->clk = devm_clk_get_optional(&pdev->dev, NULL);
 	if (IS_ERR(rngc->clk))
 		return dev_err_probe(&pdev->dev, PTR_ERR(rngc->clk), "Cannot get rng_clk\n");
 

-- 
2.39.5

