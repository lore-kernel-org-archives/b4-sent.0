From: Suyuan Wang <shyckless@gmail.com>
Date: Mon, 23 Nov 2026 00:36:20 +0000
Subject: [PATCH] ALSA: emu10k1: Require CAP_SYS_ADMIN for
 SNDRV_EMU10K1_IOCTL_PCM_POKE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-emu10k1-pcm-poke-v1-1-097b8cb8daaf@gmail.com>
X-B4-Tracking: v=1; b=H4sIAIOKA2sC/yXMQQqDMBBG4avIrDvgRLTQq5Qu6vjbTkUNSVME8
 e6muvwW760UEQyRbsVKAT+LNk8ZcilI38/pBbYum1zpGhFXMcYk5SDsdWQ/D+C6AxoVvfaupZz
 5gN6WY3l/nI6p/UC//w9t2w7HkDUwdAAAAA==
X-Change-ID: 20261123-emu10k1-pcm-poke-5dee6c1c7f2b
To: perex@perex.cz, tiwai@suse.com
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795394179; l=1837;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=kB8LDX5IJDExhgvYjrVOmQVYMR24aajUR6/sIJ1pDys=;
 b=RY6fuBqMxDspAZd0dkBGoNrfXztXgy/8jjb4HKtQh8WsFTcB0ZLkHZzbvCl9ZanTUo4IDKO7a
 UB0NnM0JGfpDVJ+KizD+xZ5i+4GCyf649RdN55ACD/DYxONN3NIv0c/
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

snd_emu10k1_fx8010_ioctl() requires CAP_SYS_ADMIN for the commands that
change the FX8010 DSP state: CODE_POKE, TRAM_SETUP, STOP, CONTINUE,
ZERO_TRAM_COUNTER and SINGLE_STEP. PCM_POKE has no such check, although
it changes the card's FX8010 PCM configuration. snd_emu10k1_ipcm_poke()
stores the GPR and TRAM indices given by the caller without checking
them, and the FX8010 PCM code in emupcm.c later uses them as register
offsets:

	snd_emu10k1_ptr_write(emu,
		TANKMEMADDRREGBASE + 0x80 + pcm->etram[i], ...);
	snd_emu10k1_ptr_write(emu, emu->gpr_base + pcm->gpr_trigger, 0, 1);

So a process that can open the hwdep device can change this card-wide
configuration, including which registers the PCM code writes, while the
other DSP configuration commands are limited to CAP_SYS_ADMIN.

Require CAP_SYS_ADMIN for PCM_POKE too, like the other FX8010
configuration commands.

Found with a static analysis tool and checked by hand.

Fixes: 1da177e4c3f4 ("Linux-2.6.12-rc2")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested on x86_64 (W=1, no new warnings). I don't have an EMU10K1 card.
---
 sound/pci/emu10k1/emufx.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/sound/pci/emu10k1/emufx.c b/sound/pci/emu10k1/emufx.c
index ddac6cecc8eb..df4661927041 100644
--- a/sound/pci/emu10k1/emufx.c
+++ b/sound/pci/emu10k1/emufx.c
@@ -2506,6 +2506,8 @@ static int snd_emu10k1_fx8010_ioctl(struct snd_hwdep * hw, struct file *file, un
 		kfree(icode);
 		return res;
 	case SNDRV_EMU10K1_IOCTL_PCM_POKE:
+		if (!capable(CAP_SYS_ADMIN))
+			return -EPERM;
 		ipcm = memdup_user(argp, sizeof(*ipcm));
 		if (IS_ERR(ipcm))
 			return PTR_ERR(ipcm);



