From: HuskerMinion <mocker-mug-unwoven@duck.com>
Subject: [PATCH 0/2] ASoC: mediatek: mt8183: Two AFE fixes
Date: Fri, 16 Oct 2026 02:14:00 -0600
Message-Id: <20261016-mt8183-afe-fixes-v1-0-f0db51e0c073@duck.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMjc0WoC/yXM0QqCQBCF4VeRuW5gR7fQXiW60PVsjaDFjkUg+
 +5udflx+M9GhqQwOlcbJbzV9LEUyKGicO+XG1jHYqpdfRInR57XVtqG+wiO+oFx54HOS2ji6Kh
 kz4TfUKrL9W97DRPC+v2hnHfmLnv1dAAAAA==
X-Change-ID: 20261015-mt8183-afe-fixes-94ee941c3fd0
To: Mark Brown <broonie@kernel.org>, Liam Girdwood <lgirdwood@gmail.com>
Cc: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 linux-sound@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, HuskerMinion <mocker-mug-unwoven@duck.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792138468; l=1641;
 i=mocker-mug-unwoven@duck.com; s=20261016; h=from:subject:message-id;
 bh=TIwHNW4PKjIUENLKJlEq6MQ/g15eZ57FFIrXUXpNPNY=;
 b=0srufWCkTX4PIs/durVAuh0yWhA93Eqq1o4UAZfY1ZVUtyTvHkL7wVZY/k4qH8l0xfn9SYVb9
 NpxhO4RuS75DMgdhPCeNsf7obXTWW2LoPgWcmwSro8JxE2AezOxRG+u
X-Developer-Key: i=mocker-mug-unwoven@duck.com; a=ed25519;
 pk=Q7l9BnP4XnFimCK28K+NVowcECqTaJNXicdBAInot0k=
X-Endpoint-Received: by B4 Relay for mocker-mug-unwoven@duck.com/20261016 with auth_id=1206
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These two fixes came up while bringing up mainline Linux on the Amazon
Echo Show 8 (2nd gen), an MT8183 board.

Patch 1 is the important one. On this board the AFE never ran. Runtime
resume enabled the audiosys clock gates while the regmap was still
cache-only, so the gate writes were dropped. With the fix, playback and
capture work on the device.

Patch 2 fixes a wrong register in the UL1_CH2 mixer. I found it while
adding capture routes for the device's microphones. The Echo Show does
not use I2S0, so that path is compile tested only.

I do not know why MT8183 Chromebooks do not seem to hit this. I have no
Chromebook to test on. My guess is that something else keeps the gates
open there, but I have not confirmed it.

Patch 1 was tested on the device with a 6.18 based kernel. Both were
then rebased onto for-next and build tested there.

Runtime suspend has the mirror problem. It goes cache-only before
mt8183_afe_disable_clock(), so those gate writes are dropped as well
and the gates stay open after the first use. I left that alone because
I have not tested a change there. I can send a patch if you want it
handled the same way.

---
HuskerMinion (2):
      ASoC: mediatek: mt8183: Leave cache-only mode before enabling clocks
      ASoC: mediatek: mt8183: Fix UL1_CH2 I2S0_CH2 routing register

 sound/soc/mediatek/mt8183/mt8183-afe-pcm.c | 18 ++++++++++++++----
 1 file changed, 14 insertions(+), 4 deletions(-)
---
base-commit: 764db7a068919c9e3d4618731dd854df43070399
change-id: 20261015-mt8183-afe-fixes-94ee941c3fd0

Best regards,
--  
HuskerMinion <mocker-mug-unwoven@duck.com>

