From: Suyuan Wang <shyckless@gmail.com>
Date: Tue, 24 Nov 2026 05:02:06 +0000
Subject: [PATCH] ASoC: arizona: Disable jack detection when the component
 is removed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-arizona-jack-remove-v1-1-11d8ec426a41@gmail.com>
X-B4-Tracking: v=1; b=H4sIAE4aBWsC/yXMQQ6CMBBA0auQWTuJLWIoVzEsSjvoYGzJFAiBc
 HeLLt/i/x0SCVOCpthBaOHEMWSoSwHuZcOTkH026Ku+K6VvaIW3GCwO1r1R6BMXws6Yuipd5Y2
 vIZejUM/r7/po/05zN5CbzhUcxxdFtCX+dwAAAA==
X-Change-ID: 20261124-arizona-jack-remove-b99853c5d9d8
To: broonie@kernel.org, lgirdwood@gmail.com
Cc: linux-sound@vger.kernel.org, hansg@kernel.org, 
 patches@opensource.cirrus.com, ckeepax@opensource.cirrus.com, 
 tiwai@suse.com, linux-kernel@vger.kernel.org, perex@perex.cz
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795496526; l=4168;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=Oaisq3p6rMX4Q4Ds45HjON9EqUYd1zTuwXtIopcCDBc=;
 b=W/TJdv9E2ClGOA9zfIwOOmaePJa8iiYkWfjXwl00iovCeloLkIo8L9WHN/i0JBQjSRFQHxFxN
 UxddUZBWLmGAx9GkkY5JZH+GC4rePJXUIZlWLhg0MMwGpK0+WOaGzWr
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

The wm5102, wm5110, wm8997 and wm8998 codecs start jack detection when
the machine driver calls snd_soc_component_set_jack().
arizona_jack_enable_jack_detect() then requests the jack, MICDET and
HPDET interrupts of the arizona MFD with the codec's struct arizona_priv
as the cookie, and keeps the snd_soc_jack pointer in info->jack. Only
set_jack(NULL) frees these interrupts and cancels the detection works.

Nothing calls set_jack(NULL) on teardown. The component_remove
callbacks don't, and neither does bytcr_wm5102, the only machine driver
that sets a jack on these codecs. The interrupts belong to the MFD, so
they stay registered after the card or the codec goes away:

- When the card is unbound, the snd_soc_jack in the machine driver's
  private data is freed, but jack detection stays active and can still
  report events to it.
- When the codec is unbound, its private data, which contains struct
  arizona_priv, is freed while the interrupts still use it as cookie.

A later headphone plug or unplug can then run the handlers, or the
works they queue, on freed memory.

Before commit 37dbabf14ff6 ("ASoC: arizona: Make the wm5102, wm5110,
wm8997 and wm8998 drivers use the new jack library"), jack detection
was done by the extcon-arizona driver, which freed these interrupts and
cancelled the works in its own remove callback.

Disable jack detection in the component_remove callbacks. The component
is removed both when the card and when the codec is unbound, and
disabling does nothing if no jack is set. When the card is bound again,
the machine driver sets the jack again.

Found with a static analysis tool and checked by hand.

Fixes: 37dbabf14ff6 ("ASoC: arizona: Make the wm5102, wm5110, wm8997 and wm8998 drivers use the new jack library")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested on x86_64 (W=1, no new warnings). I don't have hardware
with these codecs.
---
 sound/soc/codecs/wm5102.c | 2 ++
 sound/soc/codecs/wm5110.c | 2 ++
 sound/soc/codecs/wm8997.c | 2 ++
 sound/soc/codecs/wm8998.c | 2 ++
 4 files changed, 8 insertions(+)

diff --git a/sound/soc/codecs/wm5102.c b/sound/soc/codecs/wm5102.c
index 762e81979cb8..43df7cb46b59 100644
--- a/sound/soc/codecs/wm5102.c
+++ b/sound/soc/codecs/wm5102.c
@@ -1982,6 +1982,8 @@ static void wm5102_component_remove(struct snd_soc_component *component)
 {
 	struct wm5102_priv *priv = snd_soc_component_get_drvdata(component);
 
+	arizona_jack_set_jack(component, NULL, NULL);
+
 	wm_adsp2_component_remove(&priv->core.adsp[0], component);
 
 	priv->core.arizona->dapm = NULL;
diff --git a/sound/soc/codecs/wm5110.c b/sound/soc/codecs/wm5110.c
index faa85d88a489..c772f4380ae7 100644
--- a/sound/soc/codecs/wm5110.c
+++ b/sound/soc/codecs/wm5110.c
@@ -2340,6 +2340,8 @@ static void wm5110_component_remove(struct snd_soc_component *component)
 	struct wm5110_priv *priv = snd_soc_component_get_drvdata(component);
 	int i;
 
+	arizona_jack_set_jack(component, NULL, NULL);
+
 	for (i = 0; i < WM5110_NUM_ADSP; ++i)
 		wm_adsp2_component_remove(&priv->core.adsp[i], component);
 
diff --git a/sound/soc/codecs/wm8997.c b/sound/soc/codecs/wm8997.c
index f041dfc905a4..aa9f23ddd997 100644
--- a/sound/soc/codecs/wm8997.c
+++ b/sound/soc/codecs/wm8997.c
@@ -1077,6 +1077,8 @@ static void wm8997_component_remove(struct snd_soc_component *component)
 {
 	struct wm8997_priv *priv = snd_soc_component_get_drvdata(component);
 
+	arizona_jack_set_jack(component, NULL, NULL);
+
 	priv->core.arizona->dapm = NULL;
 }
 
diff --git a/sound/soc/codecs/wm8998.c b/sound/soc/codecs/wm8998.c
index 1158e9ca40a1..47adbcd80e07 100644
--- a/sound/soc/codecs/wm8998.c
+++ b/sound/soc/codecs/wm8998.c
@@ -1301,6 +1301,8 @@ static void wm8998_component_remove(struct snd_soc_component *component)
 {
 	struct wm8998_priv *priv = snd_soc_component_get_drvdata(component);
 
+	arizona_jack_set_jack(component, NULL, NULL);
+
 	priv->core.arizona->dapm = NULL;
 }
 



