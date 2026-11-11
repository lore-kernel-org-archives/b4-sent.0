From: Marc Herrero <marcht@proton.me>
Subject: [PATCH 0/2] ASoC: qcom: audioreach: fix S24_LE playback and route
 mixer disconnects
Date: Wed, 11 Nov 2026 10:54:16 +0000
Message-Id: <20261111-q6apm-fixes-v1-0-1beb5702b372@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2LMQqAMAwAv1IyWzAZOvgVcWht1AzW2oIIpX83e
 NtxXIPKRbjCZBoUfqTKlVRwMLAePu1sJaoDjeRQsbfz+bSbvFwtYQwYAkXnEfTIhf+gw7z0/gG
 JQE3KXQAAAA==
X-Change-ID: 20261111-q6apm-fixes-21db1bb2d6a1
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Pierre-Louis Bossart <pierre-louis.bossart@linux.dev>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Marc Herrero <marcht@proton.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794394460; l=1262;
 i=marcht@proton.me; s=20261111; h=from:subject:message-id;
 bh=oDandKZoj9aKJ9LxqOQ1TuaE8cLg2Oz+Q5oKITxptrs=;
 b=MLo4KyG596+Yj2uFfnkjg1GFNX1GeimwQGRcyl7E6gfpjgjkPvfkWK6SeMJ9/D4dwakUg6TFF
 g3xmL0H/JGJD9ssPofWc08VVZD6zUApR1fXU3kL9aRHxtyPeGsFMiZv
X-Developer-Key: i=marcht@proton.me; a=ed25519;
 pk=pIPy6L+INgiuJt7L7umVilPgpzy/Ni3QS77ToLj/H9c=
X-Endpoint-Received: by B4 Relay for marcht@proton.me/20261111 with auth_id=1490
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two AudioReach fixes found while bringing up 24-bit headphone playback
on the Radxa Dragon Q6A (QCS6490, sc8280xp machine driver, WCD9385).

Patch 1: S24_LE was described to the DSP as packed 3-byte samples, so
the ADSP audio_process crashed as soon as an S24_LE stream started.
Using the 32-bit container size makes S24_LE work.

Patch 2: writing 0 to any "<BE> Audio Mixer <FE>" route control cleared
the back end's link even if it belonged to another front end. As a
result alsactl restore lost DisplayPort on every boot, and the board's
UCM HDMI sequence disconnected the headphones (the PCM then stalls with
hw_ptr stuck at 0).

Both were tested on 7.2.9 with the board's topology changed to allow
S24_LE on MultiMedia1, and both apply to and build on asoc/for-next.

---
Marc Herrero (2):
      ASoC: qcom: audioreach: use a 32-bit container for S24_LE PCM
      ASoC: qcom: audioreach: only disconnect the route a mixer control owns

 sound/soc/qcom/qdsp6/audioreach.c | 4 ++--
 sound/soc/qcom/qdsp6/topology.c   | 2 +-
 2 files changed, 3 insertions(+), 3 deletions(-)
---
base-commit: cde5523c75f1320a55ac1d55a717ccbb566557f0
change-id: 20261111-q6apm-fixes-21db1bb2d6a1

Best regards,
-- 
Marc Herrero <marcht@proton.me>

