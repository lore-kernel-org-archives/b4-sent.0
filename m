From: Suyuan Wang <shyckless@gmail.com>
Date: Tue, 24 Nov 2026 04:47:07 +0000
Subject: [PATCH] ALSA: mixart: Don't touch the mailbox when the BAR mapping
 failed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-mixart-free-v1-1-13765d8d445b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMoWBWsC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyMT3dzMisSiEt20otRUXQuTNEvz1GTDJDMLEyWgjoKi1LTMCrBp0bE
 QfnFpUlZqcgnICKXaWgBdPnQNbwAAAA==
X-Change-ID: 20261124-mixart-free-84f97ec1b684
To: tiwai@suse.com, perex@perex.cz
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795495627; l=1657;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=KroNMBNLmqXWTwC1spkNnjxXDnIiXoTFsmYu+3KeonU=;
 b=GAspBgd8YPw6ltv7qrF8nA9eRiO3UmTQ86OaVDcOYWUL9OEtz7qm3/FnRkjgzwyP1GrQWhvdI
 CQD7uD8ekRuDKHyPBA5WVmjASfUJe4xJ9jw1zXLq/4Q8f4QbCulLwug
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

snd_mixart_probe() calls snd_mixart_free() when pci_ioremap_bar() fails
for either BAR. snd_mixart_free() then unconditionally calls

	snd_mixart_exit_mailbox(mgr);

which masks the outbound mailbox interrupts by writing to
MIXART_REG(mgr, MIXART_PCI_OMIMR_OFFSET), i.e. through mgr->mem[1].virt.
mem[1].virt is still NULL if either BAR mapping fails, so the error
path oopses on a write near address 0 instead of returning -EBUSY.

Only call snd_mixart_exit_mailbox() when the register BAR is mapped. The
rest of snd_mixart_free() already copes with a partly set up manager:
iounmap() accepts NULL, and the IRQ and DMA buffers are checked before
release.

Found with a static analysis tool and checked by hand.

Fixes: 1da177e4c3f4 ("Linux-2.6.12-rc2")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested on x86_64 (W=1, no new warnings). I don't have a miXart board.
---
 sound/pci/mixart/mixart.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/sound/pci/mixart/mixart.c b/sound/pci/mixart/mixart.c
index f451554cff5f..0266467734ca 100644
--- a/sound/pci/mixart/mixart.c
+++ b/sound/pci/mixart/mixart.c
@@ -1066,8 +1066,9 @@ static int snd_mixart_free(struct mixart_mgr *mgr)
 			snd_card_free(mgr->chip[i]->card);
 	}
 
-	/* stop mailbox */
-	snd_mixart_exit_mailbox(mgr);
+	/* stop mailbox, unless the register BAR was never mapped */
+	if (mgr->mem[1].virt)
+		snd_mixart_exit_mailbox(mgr);
 
 	/* release irq  */
 	if (mgr->irq >= 0)



