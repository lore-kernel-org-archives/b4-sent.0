From: Xilin Wu <wuxilin123@gmail.com>
Date: Sat, 05 Aug 2023 19:23:35 +0800
Subject: [PATCH] media: rc: ir-spi: Correct regulator name
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230805-ir-spi-v1-1-33af4a556139@gmail.com>
X-B4-Tracking: v=1; b=H4sIADYxzmQC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI2MDCwNT3cwi3eKCTF1jE3PjZNM0IGVmogRUXFCUmpZZATYoOra2FgDzgm5
 UWAAAAA==
To: Sean Young <sean@mess.org>, Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xilin Wu <wuxilin123@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1691234622; l=927;
 i=wuxilin123@gmail.com; s=20230805; h=from:subject:message-id;
 bh=+DkvKMI3r/F0yMEERA2wc0VwRO9F51Sgxxn9bTGF1zY=;
 b=BbC1D3biwOPvuRARvE7eVazY2c5pGzMwarU0ZE2bB7HXUn7mFqo97HHVYSIm9uvGwABB96jB0
 fQXhqbBV//pAH72/mrgujnR0wnvxKgz/IUkxTRTEQcJh2bElZBiXX6U
X-Developer-Key: i=wuxilin123@gmail.com; a=ed25519;
 pk=OZIrHT2qWm7yEdp5fsVR7GsFx1wxciIii20H06Ud088=
X-Endpoint-Received: by B4 Relay for wuxilin123@gmail.com/20230805 with auth_id=73
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver wrongly assumes regulator is called "irda_regulator"
instead of "power".

Change it to "power" to match device tree binding.

Signed-off-by: Xilin Wu <wuxilin123@gmail.com>
---
 drivers/media/rc/ir-spi.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/media/rc/ir-spi.c b/drivers/media/rc/ir-spi.c
index bbc81bed4f90..a447bb36100d 100644
--- a/drivers/media/rc/ir-spi.c
+++ b/drivers/media/rc/ir-spi.c
@@ -119,7 +119,7 @@ static int ir_spi_probe(struct spi_device *spi)
 	if (!idata)
 		return -ENOMEM;
 
-	idata->regulator = devm_regulator_get(&spi->dev, "irda_regulator");
+	idata->regulator = devm_regulator_get(&spi->dev, "power");
 	if (IS_ERR(idata->regulator))
 		return PTR_ERR(idata->regulator);
 

---
base-commit: 024ff300db33968c133435a146d51ac22db27374
change-id: 20230805-ir-spi-3473c5f34764

Best regards,
-- 
Xilin Wu <wuxilin123@gmail.com>

