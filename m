From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/2] ASoC: rockchip: i2s-tdm: register the PCM before the
 DAI
Date: Tue, 10 Nov 2026 07:16:57 +0000
Message-Id: <20261110-asoc-rockchip-i2s-tdm-v1-0-f32951b3c527@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMMQ6DMAxA0asgz7WEM0TAVaoOqWPAVCUoBoSEu
 HvTdnzD/yeYZBWDrjohy66maS6gWwU8hnkQ1FgMrnaeiGoMlhhz4hePuqA6wzW+Mfrg+8ZLQ6G
 F0i5Zej1+3/vjb9uek/D6ncF1fQCxBFb3eQAAAA==
X-Change-ID: 20261110-asoc-rockchip-i2s-tdm-d6a6f86e81a9
To: Nicolas Frattaroli <frattaroli.nicolas@gmail.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Heiko Stuebner <heiko@sntech.de>
Cc: linux-rockchip@lists.infradead.org, linux-sound@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295018; l=2133;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=fwtymsovofR1O3F9W5rqYLeo/TK8Hr6MiEo7/hJuKEE=;
 b=Eoei1XstvuoctnMT5F4uX9OmuONHsAC3pwbJT55sfLRkBX/FP2npyYSgUi8pCG8GBa5ap4vSV
 tX2RMrltZWSAXGsWglSG6yXbav1QNF1YAW3u9vbBLrHe9ogyuLn3o5+
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Rockchip I2S-TDM driver registers its DAI component before the
dmaengine PCM component. A sound card that was registered earlier and
waits for the CPU DAI is bound by snd_soc_component_register() as soon
as the DAI component appears, which also satisfies the DAI link's
platform (it defaults to the CPU of_node), so the card binds without the
PCM component. Every open of the PCM then fails with -EINVAL from
snd_pcm_hw_constraints_complete(), silently. On RK3588 this happens to
the HDMI sound card whenever the HDMI codec probes before the I2S
controller. Patch 1 registers the PCM first, as rockchip_spdif already
does.

Patch 2 adds the missing regmap default for I2S_XFER, which otherwise
warns "using zero-initialized flat cache" on its first cached access.

The non-TDM rockchip_i2s driver has the same registration order; the
same change for it will follow once it is tested on a board that uses
that controller (the RK3588 board here only has I2S-TDM instances).

Tested on an Orange Pi 5 (RK3588S): with patch 1 the HDMI card has its
dma:fddf0000.i2s component (debugfs asoc/hdmi0), speaker-test on
plughw:CARD=hdmi0 plays, and "aplay -D hw:<hdmi>,0" no longer fails
with "Invalid argument" (traced before the fix to
snd_pcm_hw_constraint_mask returning -22 with no dmaengine component on
the runtime). With patch 2 the flat-cache warning for fddf0000.i2s is
gone and HDMI playback is unchanged.

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit messages, and I reviewed and tested
every change as described above.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (2):
      ASoC: rockchip: i2s-tdm: Register the PCM before the DAI
      ASoC: rockchip: i2s-tdm: add the reset value of XFER to the regmap defaults

 sound/soc/rockchip/rockchip_i2s_tdm.c | 14 ++++++++++----
 1 file changed, 10 insertions(+), 4 deletions(-)
---
base-commit: cde5523c75f1320a55ac1d55a717ccbb566557f0
change-id: 20261110-asoc-rockchip-i2s-tdm-d6a6f86e81a9

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

