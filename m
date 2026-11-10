From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:16:59 +0000
Subject: [PATCH 2/2] ASoC: rockchip: i2s-tdm: add the reset value of XFER
 to the regmap defaults
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-asoc-rockchip-i2s-tdm-v1-2-f32951b3c527@gmail.com>
References: <20261110-asoc-rockchip-i2s-tdm-v1-0-f32951b3c527@gmail.com>
In-Reply-To: <20261110-asoc-rockchip-i2s-tdm-v1-0-f32951b3c527@gmail.com>
To: Nicolas Frattaroli <frattaroli.nicolas@gmail.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Heiko Stuebner <heiko@sntech.de>
Cc: linux-rockchip@lists.infradead.org, linux-sound@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295018; l=1378;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=tfT+jEvZfGZPAFf1LpE7sgBjWqRXKwyeQFTfBhDpaGw=;
 b=YA1G5nxGLOCp90pxzz2hYjwcZlCjhLKo+suxmsn7T/GVXpGZfLXsiynDfnogWAhXP0lSCYmGE
 t0A4QEnH8I6A19D8HzUVF2nvpDc/Trndk0VEaZToOuTFuXSLZQMgCw+
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I2S_XFER (0x1c) is writeable and not volatile, so it is cached, but it
has no entry in rockchip_i2s_tdm_reg_defaults[]. The flat cache then
treats it as uninitialised, and the first cached access of it -- the
regmap_update_bits() in the trigger and stop paths, or regcache_sync()
after a runtime suspend -- warns

  rockchip-i2s-tdm fddf0000.i2s: using zero-initialized flat cache, this may cause unexpected behavior

It is the only cached register without a default: TXFIFOLR, INTSR, CLR,
TXDR, RXDR and RXFIFOLR are volatile and all other registers have one.

Add XFER with its reset value of 0 (TX and RX stopped), which is also
what the zero-initialised cache assumed so far, so no register value
written to the hardware changes.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 sound/soc/rockchip/rockchip_i2s_tdm.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/sound/soc/rockchip/rockchip_i2s_tdm.c b/sound/soc/rockchip/rockchip_i2s_tdm.c
index 0abd200a4268..63ef7f676a75 100644
--- a/sound/soc/rockchip/rockchip_i2s_tdm.c
+++ b/sound/soc/rockchip/rockchip_i2s_tdm.c
@@ -926,6 +926,7 @@ static const struct reg_default rockchip_i2s_tdm_reg_defaults[] = {
 	{0x08, 0x00001f1f},
 	{0x10, 0x001f0000},
 	{0x14, 0x01f00000},
+	{0x1c, 0x00000000},
 	{0x30, 0x00003eff},
 	{0x34, 0x00003eff},
 	{0x38, 0x00000707},

-- 
2.55.0

