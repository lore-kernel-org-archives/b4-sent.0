From: =?utf-8?q?Dawid_Wro=CC=81bel?= <me@dawidwrobel.com>
Date: Wed, 29 Jul 2026 21:38:13 +0200
Subject: [PATCH 2/2] ASoC: codecs: lpass-wsa-macro: Fix enum kcontrol
 accesses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260729-worktree-lpass-tx-macro-enum-fix-v1-2-0cf02c681332@dawidwrobel.com>
References: <20260729-worktree-lpass-tx-macro-enum-fix-v1-0-0cf02c681332@dawidwrobel.com>
In-Reply-To: <20260729-worktree-lpass-tx-macro-enum-fix-v1-0-0cf02c681332@dawidwrobel.com>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Pierre-Louis Bossart <pierre-louis.bossart@linux.dev>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Dawid_Wro=CC=81bel?= <me@dawidwrobel.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1974; i=me@dawidwrobel.com;
 h=from:subject:message-id; bh=8Yk0u1wDnW2l7FgMe28BRHKq1O/VXudd7zwK2CDuI+E=;
 b=owGbwMvMwCV2qrTGfeXVd28ZT6slMWRlha1f8+9Y1M9bkx3iBSck8DQovol7mz5hv23w/2qxq
 em3BDJCOkpZGMS4GGTFFFn00oL2WAW//P7uxe9wmDmsTCBDGLg4BWAiyVkMfwV5mTOE9l9+7bBN
 5ahhzttP823awi6b5Phri+w626K2vouRYXfQhK2ecyqq/Y9O3r2r98X8b8ZCnO1imekbLp/sdng
 0hxkA
X-Developer-Key: i=me@dawidwrobel.com; a=openpgp;
 fpr=B64A778E0E64049A70C831C8B7B81FA12B282A92
X-Endpoint-Received: by B4 Relay for me@dawidwrobel.com/default with auth_id=901
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The "EAR SPKR PA Gain" control is enumerated, but
wsa_macro_ear_spkr_pa_gain_get() and _put() access its value
through ucontrol->value.integer.value[0] (a long) instead of
ucontrol->value.enumerated.item[0] (an unsigned int).

This same pattern was fixed in the sibling drivers by
commit bcfe5f76cc40 ("ASoC: codecs: rx-macro: fix accessing array
out of bounds for enum type") and
commit 0ea5eff7c606 ("ASoC: codecs: va-macro: fix accessing array
out of bounds for enum type"), but wsa-macro was missed.

On 64-bit kernels built with CONFIG_SND_CTL_DEBUG, the elem value
sanity check catches the 4 bytes written past the enumerated item
and every read of this control fails with -EINVAL (access overflow).

Fixes: 809bcbcecebf ("ASoC: codecs: lpass-wsa-macro: Add support to WSA Macro")
Assisted-by: Claude:claude-fable-5
Signed-off-by: Dawid Wróbel <me@dawidwrobel.com>
---
 sound/soc/codecs/lpass-wsa-macro.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/sound/soc/codecs/lpass-wsa-macro.c b/sound/soc/codecs/lpass-wsa-macro.c
index 5ad0448af649..c88d13c0770b 100644
--- a/sound/soc/codecs/lpass-wsa-macro.c
+++ b/sound/soc/codecs/lpass-wsa-macro.c
@@ -2064,7 +2064,7 @@ static int wsa_macro_ear_spkr_pa_gain_get(struct snd_kcontrol *kcontrol,
 	struct snd_soc_component *component = snd_kcontrol_chip(kcontrol);
 	struct wsa_macro *wsa = snd_soc_component_get_drvdata(component);
 
-	ucontrol->value.integer.value[0] = wsa->ear_spkr_gain;
+	ucontrol->value.enumerated.item[0] = wsa->ear_spkr_gain;
 
 	return 0;
 }
@@ -2075,7 +2075,7 @@ static int wsa_macro_ear_spkr_pa_gain_put(struct snd_kcontrol *kcontrol,
 	struct snd_soc_component *component = snd_kcontrol_chip(kcontrol);
 	struct wsa_macro *wsa = snd_soc_component_get_drvdata(component);
 
-	wsa->ear_spkr_gain =  ucontrol->value.integer.value[0];
+	wsa->ear_spkr_gain =  ucontrol->value.enumerated.item[0];
 
 	return 0;
 }

-- 
2.55.0

