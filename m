From: Marc Herrero <marcht@proton.me>
Subject: [PATCH v2 0/2] ASoC: qcom: audioreach: fix S24_LE playback and
 route mixer disconnects
Date: Mon, 16 Nov 2026 20:16:19 +0000
Message-Id: <20261116-q6apm-fixes-v2-0-ea89fb43316a@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22MwQ7CIBBEf6XZsxh2jTTx5H+YHlhZLYcCQkM0D
 f8u9uzc3kzebFAkeylwGTbIUn3xMXSgwwD32YanKO86A2ky2KNexqZFPfxbiiJ0jMzkjEXoRsq
 yD124TZ1nX9aYP/t5xV/7/6ei0gpZ+Dxq4tNI15TjGsNxEZhaa197p5KYpgAAAA==
X-Change-ID: 20261111-q6apm-fixes-21db1bb2d6a1
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Pierre-Louis Bossart <pierre-louis.bossart@linux.dev>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>, 
 Marc Herrero <marcht@proton.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794860180; l=1752;
 i=marcht@proton.me; s=20261111; h=from:subject:message-id;
 bh=gBvXPz/uO6Ui2hKJhCwlBxzxOFCbiLFJ7wMH5a0P35E=;
 b=o38zijKvCV/AHQU0xKqA7uJeKbRgtZqEhCGxF/hB322cob+JxhIaI9azUbLCiC7tj3A1cUEm4
 cBywMox1g1VBoOg0LNQrS9Jqg3Z3LldZ0JdMOgwYE0/fQDNs7K5v2iD
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
Changes in v2:
- Patch 1: add a comment on bit_width (valid bits) vs bits_per_sample
  (container size) (Srini). Pick up Reviewed-by.
- Patch 2: move the ownership check into audioreach_connect_sub_graphs()
  and keep updating the DAPM mixer state on every write (Srini, Mark).
  This also fixes a stale DAPM path when switching front ends, reported
  by the Sashiko review.
- Link to v1: https://lore.kernel.org/r/20261111-q6apm-fixes-v1-0-1beb5702b372@proton.me

---
Marc Herrero (2):
      ASoC: qcom: audioreach: use a 32-bit container for S24_LE PCM
      ASoC: qcom: audioreach: only disconnect the route a mixer control owns

 sound/soc/qcom/qdsp6/audioreach.c | 10 ++++++++--
 sound/soc/qcom/qdsp6/topology.c   |  4 +++-
 2 files changed, 11 insertions(+), 3 deletions(-)
---
base-commit: cde5523c75f1320a55ac1d55a717ccbb566557f0
change-id: 20261111-q6apm-fixes-21db1bb2d6a1

Best regards,
-- 
Marc Herrero <marcht@proton.me>

