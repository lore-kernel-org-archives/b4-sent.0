From: Sven Peter <sven@kernel.org>
Date: Sun, 19 Jul 2026 15:00:32 +0200
Subject: [PATCH] mfd: macsmc: Fix key count endianness annotation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260719-b4-macsmc-be32-fix-v1-1-c7b1936307fa@kernel.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBCF4avIrB0wUaL2KuIik47tCNqSURHEu
 5vW5ffg/QcoR2GFR3ZA5E1UPnOCyTMIbz+/GOWZDLawrqhNi1Th5INOAYlLi4Ps6MqaGyLjWus
 hHb+R0/yPdv1tXWnksPxKcJ4XwjqYl3YAAAA=
X-Change-ID: 20260719-b4-macsmc-be32-fix-637e8bb1692a
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Lee Jones <lee@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, kernel test robot <lkp@intel.com>, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1756; i=sven@kernel.org;
 h=from:subject:message-id; bh=IpCdIvtqrUwzVFJ1/y1oYQ0klko2f12CuHINIX6XHp0=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ1bMqYp2pYikT13FLYG8HiX/uY447mATeXFkerccB8NL5
 zcbVzzvKGVhEONikBVTZNm+3970ycM3gks3XXoPM4eVCWQIAxenAEzkZSgjw68OU/fSLdsbN6bc
 1tWeMfFvoIe3y+LLupXNc0KeBC/KPczwm11+6qTM9Zd3FcutOsh6dt9GpTnTlqpbT/p7J8vgx8z
 J4rwA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SMC firmware returns the value of the #KEY key in big-endian unlike most
other keys. Reading it through apple_smc_read_u32() into a plain u32
and then converting with be32_to_cpu() makes sparse complain:

  drivers/mfd/macsmc.c:462:26: sparse: cast to restricted __be32

Read the raw value into a __be32 using apple_smc_read() instead.

Fixes: e038d985c982 ("mfd: Add Apple Silicon System Management Controller")
Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/oe-kbuild-all/202607181046.OANjIoqR-lkp@intel.com/
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/mfd/macsmc.c | 8 +++++---
 1 file changed, 5 insertions(+), 3 deletions(-)

diff --git a/drivers/mfd/macsmc.c b/drivers/mfd/macsmc.c
index 358feec2d088..514cba7dc897 100644
--- a/drivers/mfd/macsmc.c
+++ b/drivers/mfd/macsmc.c
@@ -410,7 +410,7 @@ static int apple_smc_probe(struct platform_device *pdev)
 {
 	struct device *dev = &pdev->dev;
 	struct apple_smc *smc;
-	u32 count;
+	__be32 count;
 	int ret;
 
 	smc = devm_kzalloc(dev, sizeof(*smc), GFP_KERNEL);
@@ -461,8 +461,10 @@ static int apple_smc_probe(struct platform_device *pdev)
 	dev_set_drvdata(&pdev->dev, smc);
 	BLOCKING_INIT_NOTIFIER_HEAD(&smc->event_handlers);
 
-	ret = apple_smc_read_u32(smc, SMC_KEY(#KEY), &count);
-	if (ret)
+	ret = apple_smc_read(smc, SMC_KEY(#KEY), &count, sizeof(count));
+	if (ret >= 0 && ret != sizeof(count))
+		ret = -EINVAL;
+	if (ret < 0)
 		return dev_err_probe(smc->dev, ret, "Failed to get key count");
 	smc->key_count = be32_to_cpu(count);
 

---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260719-b4-macsmc-be32-fix-637e8bb1692a

Best regards,
--  
Sven Peter <sven@kernel.org>

