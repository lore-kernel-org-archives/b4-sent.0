From: Suyuan Wang <shyckless@gmail.com>
Date: Sun, 22 Nov 2026 10:08:16 +0000
Subject: [PATCH] ALSA: sis7019: Don't shift the voice IRQ status by 32
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-sis7019-voice-irq-v1-1-fa5d0cbecf62@gmail.com>
X-B4-Tracking: v=1; b=H4sIAA+/AmsC/yXMyw5AMBCF4VeRWWuiI0i9ilhQU8bCpYNIxLsrl
 l9Ozn+BkGcSKKMLPB0sPE8BOo7ADs3Uk+IuGDDBXGtEJSxFoo06ZrZh9Ksig5hnrk2NSyH8Fk+
 Oz69Z1b9lb0ey2xuC+34A7CfNPHUAAAA=
X-Change-ID: 20261122-sis7019-voice-irq-e92265fb39f3
To: perex@perex.cz, tiwai@suse.com
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795342095; l=2053;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=huKzTa2eQDkgURxI5UqFkDNM3LidKvXVuHpanoNFwvI=;
 b=OLwzOqLLF7VtxbmUbAt4oriLbFnkIetFuSf13BKww5X9N0/3KAgYPO8/hew7/wv3lfG/+rvQ2
 E9cR7P7CvTZDSBQWQGwH5xeOF5gprTMqZAbxdu7VvgP/pVEYRHOe2r1
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

sis_voice_irq() walks the set bits of a PISR_A or PISR_B status word:

	bit = __ffs(status);
	status >>= bit + 1;

When voice 31 or 63 interrupts, bit is 31 and status is shifted by 32,
which is undefined for a u32. On x86 the shift count is masked to 0, so
status does not change, the loop never ends, and voice keeps moving 32
entries forward on every pass, past the end of sis->voices[], with
sis_update_voice() called on whatever is there. All of this runs in the
hard IRQ handler. Voices are handed out from 0 up, so voice 31 is in use
once enough playback streams are open.

Walk the bits with for_each_set_bit() and index the voice by bit number
instead. The voices are still updated in the same order.

Found with a static analysis tool and checked by hand.

Fixes: 175859bf1602 ("[ALSA] sis7019: support the SiS 7019 Audio Accelerator")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested (i386, W=1). I don't have a SiS 7019, so I ran the old
and new loop in userspace on the same status words: with 0x80000000 the
old loop trips UBSan's shift check, and without it ASan reports a read
past the 64-entry voice array; the new loop updates voice 31 (or 63)
and stops.
---
 sound/pci/sis7019.c | 10 +++-------
 1 file changed, 3 insertions(+), 7 deletions(-)

diff --git a/sound/pci/sis7019.c b/sound/pci/sis7019.c
index fe5bda5af6a5..f31e62068ee3 100644
--- a/sound/pci/sis7019.c
+++ b/sound/pci/sis7019.c
@@ -278,15 +278,11 @@ static void sis_update_voice(struct voice *voice)
 
 static void sis_voice_irq(u32 status, struct voice *voice)
 {
+	unsigned long bits = status;
 	int bit;
 
-	while (status) {
-		bit = __ffs(status);
-		status >>= bit + 1;
-		voice += bit;
-		sis_update_voice(voice);
-		voice++;
-	}
+	for_each_set_bit(bit, &bits, 32)
+		sis_update_voice(&voice[bit]);
 }
 
 static irqreturn_t sis_interrupt(int irq, void *dev)



