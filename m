From: Roman Prucha <zorgan.roman@gmail.com>
Date: Thu, 03 Sep 2026 23:14:44 +0200
Subject: [PATCH] ALSA: ctxfi: Fix CA20K2 S/PDIF passthrough
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260903-ctxfi-spdif-conf9-fix-v1-1-5e4e3e1f801c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvxJ7bsESDPtKdCjdrb2YaIQg/T3pO
 AMzFTIloQxzVyHRI1mu0GDoO3DnFg5C8Y1hVKNRVml0d2HBHL0wuiuwRZaCu1WWJ9LGeAetjYm
 a/r/L+r4f6f2l2GcAAAA=
X-Change-ID: 20260903-ctxfi-spdif-conf9-fix-b909f7e366dc
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Colin Ian King <colin.i.king@gmail.com>
Cc: Takashi Iwai <tiwai@suse.de>, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Roman Prucha <zorgan.roman@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788470085; l=1760;
 i=zorgan.roman@gmail.com; s=20260903; h=from:subject:message-id;
 bh=jp1ueNFuA7dYZ45fIz/uA/BuyiO44DD0w6SFBbr7Fa0=;
 b=z3wyA/sdLPH8AAAP3N3Tqh9wZQJozr+KoUi594t9AJYiIajbW0/CJga6QNj9JUZYR/aLf3hMp
 LZ8Q2LFr1REC5GQA9FP6t1eVQsRP6woUy8JBsHMOVV3uUk7feiqmH0L
X-Developer-Key: i=zorgan.roman@gmail.com; a=ed25519;
 pk=nrIfal6DL0s9II7312EtRS98gHuLh87xybqQk8LhJw4=
X-Endpoint-Received: by B4 Relay for zorgan.roman@gmail.com/20260903 with auth_id=1001
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dao_rsc_init() encodes the DAIO configuration as

    conf = (desc->msr & 0x7) | (desc->passthru << 3);

S/PDIF passthrough uses msr=1 and passthru=1, resulting in
conf=9.

daio_mgr_dao_init() masks conf with 0xf, but handles only values
1, 2, 4 and 8 when programming ATXCTL_NUC. As a result, conf=9
falls through to the default case and leaves NUC at its previous
setting.

On a Creative X-Fi Titanium HD SB1270 (CA20K2), this breaks AC3
IEC61937 passthrough when snd_ctxfi runs with
reference_rate=48000,multiple=2. The receiver detects a non-audio
stream but cannot decode the AC3 payload.

With the unmodified driver, multiple=1 makes the same stream work.
Handle conf=9 through the same NUC=0 path as conf=1.

The change was runtime tested on the SB1270 with multiple=2 using
IEC958 stereo PCM, pre-encoded AC3 IEC61937 passthrough and ALSA
A52 live 5.1 encoding.

Fixes: 26a9630c72eb ("ALSA: ctxfi: cthw20k2: fix mask on conf to allow 4 bits")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Roman Prucha <zorgan.roman@gmail.com>
---
 sound/pci/ctxfi/cthw20k2.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/sound/pci/ctxfi/cthw20k2.c b/sound/pci/ctxfi/cthw20k2.c
index 07e1490a6d17..36066ffe8784 100644
--- a/sound/pci/ctxfi/cthw20k2.c
+++ b/sound/pci/ctxfi/cthw20k2.c
@@ -994,6 +994,7 @@ static int daio_mgr_dao_init(struct hw *hw, void *blk, unsigned int idx, unsigne
 		/* S/PDIF output */
 		switch ((conf & 0xf)) {
 		case 1:
+		case 9:
 			set_field(&ctl->txctl[idx], ATXCTL_NUC, 0);
 			break;
 		case 2:

---
base-commit: 7f71fd44a1089b362eacf87e1f451ddd4fb7df62
change-id: 20260903-ctxfi-spdif-conf9-fix-b909f7e366dc

Best regards,
-- 
Roman Prucha <zorgan.roman@gmail.com>

