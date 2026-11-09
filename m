From: "Nicholas E. Andrade" <sdnick484@gmail.com>
Date: Mon, 09 Nov 2026 10:22:35 -0800
Subject: [PATCH] ASoC: amd: acp: fix PDM ring buffer address on ACP7.x
 resume
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-for-next-v1-1-54a06f391bda@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqAIBCF4avIrBPUQLCrRAutqaaFhloI0d2zW
 n7wv3dBwkiYoGMXRDwpUfAVsmEwrtYvyGmqBiWUllIYPofIPZbMrWqtUM4apx3UfI84U/mu+uF
 3OtyGY373cN8PRGBWDmwAAAA=
X-Change-ID: 20261109-for-next-a23a02ba9b6b
To: Vijendar Mukunda <Vijendar.Mukunda@amd.com>, 
 Venkata Prasad Potturu <venkataprasad.potturu@amd.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, "Nicholas E. Andrade" <sdnick484@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794248555; l=2818;
 i=sdnick484@gmail.com; s=20261109; h=from:subject:message-id;
 bh=8RaG7FvDYO7V+CSMfCZPjcUt6Rsow7pb/3k3rvgPCIM=;
 b=8HgxVqk2Ro9a50QOMq42KnkEi4iD8kX3OS7sYnkkhDRjDw/4lQJ0gbh9rR2onZekoKglapw7j
 cXpvj4VQXJ3BGzfVwsmHegvLCG43Vnh0gu0vSV1Gc3K92qEyWHseJMC
X-Developer-Key: i=sdnick484@gmail.com; a=ed25519;
 pk=dZeJlYx1JwBxT2ReweY1tgwN5soFTVPcCKakRZCpX54=
X-Endpoint-Received: by B4 Relay for sdnick484@gmail.com/20261109 with auth_id=1464
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On ACP7.x the DMIC ring buffer lives at ACP7x_DMIC_MEM_WINDOW_START,
and acp_dmic_prepare() programs ACP_WOV_RX_RINGBUFADDR accordingly.
The system resume path (acp70_pcm_resume() -> restore_acp_pdm_params()
-> set_acp_pdm_ring_buffer()) however still uses the pre-ACP7.x
calculation, stream->reg_offset + MEM_WINDOW_START (0x6080000).

That window is not backed by the PTEs config_acp_dma() writes for the
DMIC stream (scratch offset 0x6000, i.e. window 0x4C00000), so after
resume the ATU translates DMIC DMA through uninitialised SRAM and the
ACP writes to random IOVAs. With the IOMMU enabled, a capture stream
held open across s2idle produces a continuous stream of faults until
it is closed, and captures nothing useful:

  snd_acp_pci 0000:c4:00.5: AMD-Vi: Event logged [IO_PAGE_FAULT
  domain=0x0018 address=0x1ddeee9942398e20 flags=0x0030]

Commit 3ee257aba1d5 ("ASoC: amd: acp: Audio is not resuming after
s0ix") fixed the same problem for the I2S restore path in
set_acp_i2s_dma_fifo() but left the PDM path unchanged. Select the
ACP7.x window there too, matching acp_dmic_prepare().

Tested on a Lenovo ThinkPad P14s Gen 6 AMD (ACP rev 0x71, kernel
7.3.1) by holding
  arecord -D hw:CARD=acppdmmach,DEV=0 -f S32_LE -r 48000 -c 2
open across s2idle: before the fix, IO_PAGE_FAULTs after every resume
and no audio; after, no faults and audio captured correctly after
resume.

The bug was diagnosed and the fix drafted with the help of an AI
coding assistant (Claude); the analysis, change and testing were
reviewed and verified by the submitter on the hardware above.

Fixes: f6f7d25b1103 ("ASoC: amd: acp: Add pte configuration for ACP7.0 platform")
Cc: stable@vger.kernel.org

Signed-off-by: Nicholas E. Andrade <sdnick484@gmail.com>
---
 sound/soc/amd/acp/acp-legacy-common.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/sound/soc/amd/acp/acp-legacy-common.c b/sound/soc/amd/acp/acp-legacy-common.c
index 4e477c48d4b..9c0528a7dfc 100644
--- a/sound/soc/amd/acp/acp-legacy-common.c
+++ b/sound/soc/amd/acp/acp-legacy-common.c
@@ -154,7 +154,10 @@ static void set_acp_pdm_ring_buffer(struct snd_pcm_substream *substream,
 
 	period_bytes = frames_to_bytes(runtime, runtime->period_size);
 	pdm_size = frames_to_bytes(runtime, runtime->buffer_size);
-	physical_addr = stream->reg_offset + MEM_WINDOW_START;
+	if (chip->acp_rev >= ACP70_PCI_ID)
+		physical_addr = ACP7x_DMIC_MEM_WINDOW_START;
+	else
+		physical_addr = stream->reg_offset + MEM_WINDOW_START;
 
 	/* Init ACP PDM Ring buffer */
 	writel(physical_addr, chip->base + ACP_WOV_RX_RINGBUFADDR);

---
base-commit: cde5523c75f1320a55ac1d55a717ccbb566557f0
change-id: 20261109-for-next-a23a02ba9b6b

Best regards,
--  
Nicholas E. Andrade <sdnick484@gmail.com>

