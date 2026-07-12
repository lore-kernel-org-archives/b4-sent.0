From: Miles Krause <mileskrause5200@gmail.com>
Date: Sat, 11 Jul 2026 22:56:14 -0400
Subject: [PATCH] memory: jz4780-nemc: Use dev_err_probe() for clock error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260711-jz4780-nemc-dev-err-probe-v1-1-afb6f6a82752@gmail.com>
X-B4-Tracking: v=1; b=H4sIAE0CU2oC/yXMQQ6CMBBG4auQWTtJS0TQqxgXTPurQ2IhUyRGw
 t2tuvwW762UYYpMp2olw6JZx1TgdxWFe59uYI3FVLv64FrveXjv285xwiNwxMIw48lGAccYmuY
 onUjvqfST4aqv3/t8+Ts/ZUCYv0Patg9fu3LBfQAAAA==
X-Change-ID: 20260711-jz4780-nemc-dev-err-probe-ddc559b8bba1
To: Paul Cercueil <paul@crapouillou.net>, 
 Krzysztof Kozlowski <krzk@kernel.org>
Cc: linux-mips@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Miles Krause <mileskrause5200@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783824975; l=1329;
 i=mileskrause5200@gmail.com; s=20260710; h=from:subject:message-id;
 bh=AGXKyAp8ExZItIFAOU025OlxKNPfZ4JXCxmTSMbLIcw=;
 b=SDDaywFXq9ZUBuE9d/dzRpi6j2R3tWaDdqA5QU+YnuLmwC3kKXNmSMh86RV1486tDk+AV38ra
 UYpwCdm8frkDyAv7nMmDfrl/I5oeINAZDoBm41DRXcT/Nrv7fHubaU2
X-Developer-Key: i=mileskrause5200@gmail.com; a=ed25519;
 pk=QNhNjcQarqig3ColJBIEr3DYfWM1PHpP7z+6thxWXaU=
X-Endpoint-Received: by B4 Relay for mileskrause5200@gmail.com/20260710 with auth_id=861
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use dev_err_probe() to simplify clock acquisition error handling and
avoid logging probe deferral as an error.

No functional change.

Signed-off-by: Miles Krause <mileskrause5200@gmail.com>
---
Built with:

make O=out W=1 drivers/memory/jz4780-nemc.o

To: Paul Cercueil <paul@crapouillou.net>
To: Krzysztof Kozlowski <krzk@kernel.org>
Cc: linux-mips@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
---
 drivers/memory/jz4780-nemc.c | 7 +++----
 1 file changed, 3 insertions(+), 4 deletions(-)

diff --git a/drivers/memory/jz4780-nemc.c b/drivers/memory/jz4780-nemc.c
index 1a8161514d03..1bf17057cbf5 100644
--- a/drivers/memory/jz4780-nemc.c
+++ b/drivers/memory/jz4780-nemc.c
@@ -313,10 +313,9 @@ static int jz4780_nemc_probe(struct platform_device *pdev)
 	writel(0, nemc->base + NEMC_NFCSR);
 
 	nemc->clk = devm_clk_get(dev, NULL);
-	if (IS_ERR(nemc->clk)) {
-		dev_err(dev, "failed to get clock\n");
-		return PTR_ERR(nemc->clk);
-	}
+	if (IS_ERR(nemc->clk))
+		return dev_err_probe(dev, PTR_ERR(nemc->clk),
+				     "failed to get clock\n");
 
 	ret = clk_prepare_enable(nemc->clk);
 	if (ret) {

---
base-commit: 8111c7f3723f414b7f655a3880775cbbd0e9de8e
change-id: 20260711-jz4780-nemc-dev-err-probe-ddc559b8bba1

Best regards,
--  
Miles Krause <mileskrause5200@gmail.com>

