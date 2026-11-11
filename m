From: Marc Herrero <marcht@proton.me>
Date: Wed, 11 Nov 2026 10:54:17 +0000
Subject: [PATCH 1/2] ASoC: qcom: audioreach: use a 32-bit container for
 S24_LE PCM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-q6apm-fixes-v1-1-1beb5702b372@proton.me>
References: <20261111-q6apm-fixes-v1-0-1beb5702b372@proton.me>
In-Reply-To: <20261111-q6apm-fixes-v1-0-1beb5702b372@proton.me>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Pierre-Louis Bossart <pierre-louis.bossart@linux.dev>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Marc Herrero <marcht@proton.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794394460; l=2662;
 i=marcht@proton.me; s=20261111; h=from:subject:message-id;
 bh=9fJzhmYUq3LyiOGxgqaMh+RyxTe6x0FH/AqCa9i1ZJM=;
 b=NtdgL1f71BjOhvSO6cGEs3Y0JCeTj7nkuY/GfIZ8t79gXECCYHSjzYDo0uZRZv7MAS9Tw2yc3
 9Lyi4UzXau6AZvA0ybFKjLsuIRUx4d8yHM9uan0px5Qi7g04YJJFc84
X-Developer-Key: i=marcht@proton.me; a=ed25519;
 pk=pIPy6L+INgiuJt7L7umVilPgpzy/Ni3QS77ToLj/H9c=
X-Endpoint-Received: by B4 Relay for marcht@proton.me/20261111 with auth_id=1490
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SNDRV_PCM_FORMAT_S24_LE carries 24 valid bits in a 32-bit container, but
audioreach_shmem_set_media_format() and audioreach_pcm_set_media_format()
set bits_per_sample = bit_width = 24 in PARAM_ID_MEDIA_FORMAT and
PARAM_ID_PCM_OUTPUT_FORMAT_CFG, which tells the DSP that the samples are
packed 3-byte words.

q6apm-dai advertises S24_LE, so with a topology that allows it on a
playback front end the DSP walks the buffer with the wrong stride. On
QCS6490 (Radxa Dragon Q6A) this crashes the ADSP audio_process:

  PDM: service 'audio_process' crash: 'EX:audio_process:0x2:...'
  q6apm-lpass-dais ...: Failed to start APM port 113
  remoteproc remoteproc0: crash detected in adsp: type fatal error

Use the container size (32) for 24-bit data and keep bit_width = 24,
alignment = PCM_LSB_ALIGNED and q_factor = 23. With this change S24_LE
playback works on the headphone path (codec DMA RX -> LPASS RX macro ->
WCD9385), tested with the back end at S16_LE, S24_LE and S32_LE and at
48, 96 and 192 kHz.

The DSP then reads each 32-bit word as Q23, so S24_LE samples must be
sign-extended into the top byte, as alsa-lib's conversions do.

Fixes: 25ab80db6b13 ("ASoC: qdsp6: audioreach: add module configuration command helpers")
Cc: stable@vger.kernel.org
Signed-off-by: Marc Herrero <marcht@proton.me>
---
 sound/soc/qcom/qdsp6/audioreach.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/sound/soc/qcom/qdsp6/audioreach.c b/sound/soc/qcom/qdsp6/audioreach.c
index d2dc5d37bccf..937506edf34a 100644
--- a/sound/soc/qcom/qdsp6/audioreach.c
+++ b/sound/soc/qcom/qdsp6/audioreach.c
@@ -1216,7 +1216,7 @@ static int audioreach_pcm_set_media_format(struct q6apm_graph *graph,
 	media_cfg->interleaved = module->interleave_type;
 	media_cfg->num_channels = mcfg->num_channels;
 	media_cfg->q_factor = mcfg->bit_width - 1;
-	media_cfg->bits_per_sample = mcfg->bit_width;
+	media_cfg->bits_per_sample = mcfg->bit_width == 24 ? 32 : mcfg->bit_width;
 	/* Convert the physical mapping to a logical mapping of the channels */
 	for (i = 0, j = 0; i < AR_PCM_MAX_NUM_CHANNEL && j < mcfg->num_channels; i++) {
 		if (!mcfg->channel_map[i])
@@ -1308,7 +1308,7 @@ static int audioreach_shmem_set_media_format(struct q6apm_graph *graph,
 		cfg->sample_rate = mcfg->sample_rate;
 		cfg->bit_width = mcfg->bit_width;
 		cfg->alignment = PCM_LSB_ALIGNED;
-		cfg->bits_per_sample = mcfg->bit_width;
+		cfg->bits_per_sample = mcfg->bit_width == 24 ? 32 : mcfg->bit_width;
 		cfg->q_factor = mcfg->bit_width - 1;
 		cfg->endianness = PCM_LITTLE_ENDIAN;
 		cfg->num_channels = mcfg->num_channels;

-- 
2.53.0

