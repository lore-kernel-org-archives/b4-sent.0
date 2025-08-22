From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Fri, 22 Aug 2025 18:28:33 +0800
Subject: [PATCH] ASoC: codecs: idt821034: fix wrong log in
 idt821034_chip_direction_output()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250822-idt821034-v1-1-e2bfffbde56f@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAFBGqGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDCyMjILfEwsjQwNhE1yDJNDnJwizJINnSTAmovqAoNS2zAmxWdGxtLQA
 pAZE0WwAAAA==
X-Change-ID: 20250822-idt821034-0b5cb86b0c96
To: Herve Codina <herve.codina@bootlin.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 guanwentao@uniontech.com, niecheng1@uniontech.com, zhanjun@uniontech.com, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755858517; l=1022;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=Xf7JFZXRbt8rXAX/IFwN/P7Ba3v6XdLGbf2wZX2q3kI=;
 b=utMVbNOaZjz16DXuia93Q7alE05P+SVaph8G790DbgkFgWzfz6oObdvp6v+qBHq16mbFeEGLp
 kPtPjee41xpAEHHkEpSeIBuVuIH8Ij2y3+4IgS0Z4TyyvsTUSalebt9
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Change `dir in` to `dir out`

Suggested-by: Jun Zhan <zhanjun@uniontech.com>
Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 sound/soc/codecs/idt821034.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/sound/soc/codecs/idt821034.c b/sound/soc/codecs/idt821034.c
index 6738cf21983b0dc58e162cbfaacaedb5edaaa245..a03d4e5e7d144195622ea0cbf6b6c6ba95642aa7 100644
--- a/sound/soc/codecs/idt821034.c
+++ b/sound/soc/codecs/idt821034.c
@@ -1067,7 +1067,7 @@ static int idt821034_chip_direction_output(struct gpio_chip *c, unsigned int off
 
 	ret = idt821034_set_slic_conf(idt821034, ch, slic_conf);
 	if (ret) {
-		dev_err(&idt821034->spi->dev, "dir in gpio %d (%u, 0x%x) failed (%d)\n",
+		dev_err(&idt821034->spi->dev, "dir out gpio %d (%u, 0x%x) failed (%d)\n",
 			offset, ch, mask, ret);
 	}
 

---
base-commit: 3957a5720157264dcc41415fbec7c51c4000fc2d
change-id: 20250822-idt821034-0b5cb86b0c96

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

