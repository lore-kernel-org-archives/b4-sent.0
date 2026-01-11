From: Bharadwaj Raju <bharadwaj.raju@machinesoul.in>
Date: Sun, 11 Jan 2026 15:40:30 +0530
Subject: [PATCH 1/2] ASoC: codecs: aw88261: use dvdd-supply regulator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260111-aw88261-dvdd-v1-1-83fa0850d561@machinesoul.in>
References: <20260111-aw88261-dvdd-v1-0-83fa0850d561@machinesoul.in>
In-Reply-To: <20260111-aw88261-dvdd-v1-0-83fa0850d561@machinesoul.in>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Weidong Wang <wangweidong.a@awinic.com>
Cc: Bhushan Shah <bhushan.shah@machinesoul.in>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Bharadwaj Raju <bharadwaj.raju@machinesoul.in>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768126255; l=992;
 i=bharadwaj.raju@machinesoul.in; s=20260111; h=from:subject:message-id;
 bh=xIr52IlUNDq+dta2pfCJcyJY6ZnUYlCMSdXp4Olf60M=;
 b=c1yMno2pfazzXCrs++QFgsrEiPgRWjMBn823hwA8g5YITANQ61vSxsKmiEK9oZuFnk+sBgohN
 F79ExVHv0h3DJ88wuzxAfddpBnKtU9x12W9FulbKM25UYH/N3Qm3ZrU
X-Developer-Key: i=bharadwaj.raju@machinesoul.in; a=ed25519;
 pk=0M1a+iMXDqasbx7bQL71NdtuutFXu+lVxsiSnEiyAIg=
X-Endpoint-Received: by B4 Relay for bharadwaj.raju@machinesoul.in/20260111 with auth_id=598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the dvdd regulator on startup.

Signed-off-by: Bharadwaj Raju <bharadwaj.raju@machinesoul.in>
---
 sound/soc/codecs/aw88261.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/sound/soc/codecs/aw88261.c b/sound/soc/codecs/aw88261.c
index 6bd6e7ffd1aa..9a2d167cf809 100644
--- a/sound/soc/codecs/aw88261.c
+++ b/sound/soc/codecs/aw88261.c
@@ -11,6 +11,7 @@
 #include <linux/i2c.h>
 #include <linux/firmware.h>
 #include <linux/regmap.h>
+#include <linux/regulator/consumer.h>
 #include <sound/soc.h>
 #include "aw88261.h"
 #include "aw88395/aw88395_data_type.h"
@@ -1295,6 +1296,10 @@ static int aw88261_init(struct aw88261 **aw88261, struct i2c_client *i2c, struct
 	unsigned int chip_id;
 	int ret;
 
+	ret = devm_regulator_get_enable(&i2c->dev, "dvdd");
+	if (ret)
+		return dev_err_probe(&i2c->dev, ret, "Failed to enable dvdd supply\n");
+
 	/* read chip id */
 	ret = regmap_read(regmap, AW88261_ID_REG, &chip_id);
 	if (ret) {

-- 
2.43.0

