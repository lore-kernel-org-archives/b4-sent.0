From: Bharadwaj Raju <bharadwaj.raju@machinesoul.in>
Date: Wed, 14 Jan 2026 16:03:25 +0530
Subject: [PATCH v2 2/2] ASoC: codecs: aw88261: use dvdd-supply regulator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260114-aw88261-dvdd-v2-2-ef485b82a7a7@machinesoul.in>
References: <20260114-aw88261-dvdd-v2-0-ef485b82a7a7@machinesoul.in>
In-Reply-To: <20260114-aw88261-dvdd-v2-0-ef485b82a7a7@machinesoul.in>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Weidong Wang <wangweidong.a@awinic.com>
Cc: Bhushan Shah <bhushan.shah@machinesoul.in>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Bharadwaj Raju <bharadwaj.raju@machinesoul.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768386804; l=1058;
 i=bharadwaj.raju@machinesoul.in; s=20260111; h=from:subject:message-id;
 bh=5/VP3xlRbiTybkiC7ajPqUVJkHZa2zb+dXom5nXLPzg=;
 b=wKph1TQV7Hhg97we4Q4c6WN7gfcv9MZkCXzjOYMn/AxPgv5/tN4QcXtOZYz4gPW1YNg9cpASw
 e+gi+0xI4MbC6vZhneKxlHJ7R0ei0iT0A8GwykjM8w7nR7g+WX11Mfe
X-Developer-Key: i=bharadwaj.raju@machinesoul.in; a=ed25519;
 pk=0M1a+iMXDqasbx7bQL71NdtuutFXu+lVxsiSnEiyAIg=
X-Endpoint-Received: by B4 Relay for bharadwaj.raju@machinesoul.in/20260111 with auth_id=598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AW88261 needs the DVDD pin to be powered on to start up. Get and
enable the dvdd-supply regulator.

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

