From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Wed, 15 Jan 2025 19:03:10 +0800
Subject: [PATCH 4/4] ASoC: ac97: Add DT support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250115-loongson1-ac97-v1-4-2087b04dcd7f@gmail.com>
References: <20250115-loongson1-ac97-v1-0-2087b04dcd7f@gmail.com>
In-Reply-To: <20250115-loongson1-ac97-v1-0-2087b04dcd7f@gmail.com>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: linux-mips@vger.kernel.org, linux-sound@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Keguang Zhang <keguang.zhang@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736938989; l=1140;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=zOmvkdjOxEXNVbs0rnSsZ3qVKBPQtGNTr4XJg6yjJq8=;
 b=P3yzqblD2o8EvaKdf1XdWZyErWlDtmcrozd2JItjI9VlRkcQ6Oc8T6bKAVD98NtFYo83e7Xtd
 3jrW3XshfJrBQxWVVYLgzb04iqushcMCQMrnCIEyRr5PkD7l0+kJLgP
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an of_match_table with 'realtek,alc203' to provide
DT support for the AC97 generic codec driver.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 sound/soc/codecs/ac97.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/sound/soc/codecs/ac97.c b/sound/soc/codecs/ac97.c
index 0e013edfe63d..d8444a083af2 100644
--- a/sound/soc/codecs/ac97.c
+++ b/sound/soc/codecs/ac97.c
@@ -13,6 +13,7 @@
 #include <linux/kernel.h>
 #include <linux/device.h>
 #include <linux/module.h>
+#include <linux/of.h>
 #include <sound/core.h>
 #include <sound/pcm.h>
 #include <sound/ac97_codec.h>
@@ -127,9 +128,18 @@ static int ac97_probe(struct platform_device *pdev)
 			&soc_component_dev_ac97, &ac97_dai, 1);
 }
 
+#ifdef CONFIG_OF
+static const struct of_device_id ac97_codec_of_match[] = {
+	{ .compatible = "realtek,alc203", },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, ac97_codec_of_match);
+#endif
+
 static struct platform_driver ac97_codec_driver = {
 	.driver = {
 		.name = "ac97-codec",
+		.of_match_table = of_match_ptr(ac97_codec_of_match),
 	},
 
 	.probe = ac97_probe,

-- 
2.43.0

