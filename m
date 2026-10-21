From: Colton Pawielski <colton.pawielski@gmail.com>
Date: Wed, 21 Oct 2026 18:11:41 -0500
Subject: [PATCH net] net: 8139cp: close race between NAPI completion and Rx
 unmask
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-b4-8139cp-napi-v1-1-c9b683d9564b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQqDMBCE4VeRObtgNmKtryI9aFzb7SGGREtBf
 PdGe/wG5t+RJKokdMWOKB9NuvgMUxZwr8E/hXTKBlfcmIoNjTW1xt5dID8EpVYyZrZ8sw3yKUS
 Z9XsFe3hZ8fiPaRvf4tYzheP4Acf8Luh3AAAA
X-Change-ID: 20261021-b4-8139cp-napi-8e139f232736
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daniel Palmer <daniel@0x0f.com>, Geert Uytterhoeven <geert@linux-m68k.org>, 
 Colton Pawielski <colton.pawielski@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792624365; l=2614;
 i=colton.pawielski@gmail.com; s=20261021; h=from:subject:message-id;
 bh=xysNCUVTIwjH2gSf4rA52HhJwF/s+KbxeRxHiscJJ5M=;
 b=gwUh2h96+C0ZYB88boeAGPNY+yTTOLkpwJE1w8gE6k6U/SyfaMhc1Hr6DOGDUyPsb3zMuV5Tu
 5p3PMWu5h6NBUZq0EYzn42RBit3vE8WuXqQMbyvYukNm1I6yZOBWcvV
X-Developer-Key: i=colton.pawielski@gmail.com; a=ed25519;
 pk=QFoKkkRiV70QY509+evUr/DtmgPqjU3fLV0TaScMuE4=
X-Endpoint-Received: by B4 Relay for colton.pawielski@gmail.com/20261021 with auth_id=1266
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cp_rx_poll() calls napi_complete_done() and only then takes cp->lock
with interrupts disabled to unmask the Rx interrupts.  An interrupt
that is not masked while polling (TxOK, TxErr, ...) can arrive in
between.  cp_interrupt() then sees the Rx status bits, which are still
set, finds NAPI no longer scheduled, masks Rx and schedules NAPI again.
cp_rx_poll() then carries on and unmasks Rx anyway.

From that point Rx interrupts are enabled while NAPI is scheduled:
cp_interrupt() leaves the Rx bits for the poll routine, does not mask
them because napi_schedule_prep() fails, and the level-triggered
interrupt fires again as soon as it returns.  On an SH7751 LANDISK
under combined Tx/Rx load this interrupt storm was captured with a RAM
trace right before the board locked up hard.

Do the completion and the unmask under the lock, as 8139too does.

Fixes: ab1e7e1d2666 ("8139cp: use napi_complete_done()")
Signed-off-by: Colton Pawielski <colton.pawielski@gmail.com>
---
An AI coding assistant (Claude Opus 5.5, in Claude Code) did most of the
debugging: it instrumented the driver with a RAM-backed trace of register
accesses and IRQ entry/exit that survives the power cycle, and decoded
the trace after the hang.

Tested on three I-O DATA LANDISK boards (SH7751R, RTL8139C+ rev 0x20).
Without this patch, pulling 300 MB over ssh while reading the disk
(concurrent IDE and network DMA) hard-hung the board in 7 of 8 runs.
With it, that test passed 8/8, 3/3 and 3/3 on the three boards, and
copying the full rootfs and multi-GB test files over ssh also completed
without problems.
---
 drivers/net/ethernet/realtek/8139cp.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/net/ethernet/realtek/8139cp.c b/drivers/net/ethernet/realtek/8139cp.c
index 9016527e229a..a9334d3a0f7d 100644
--- a/drivers/net/ethernet/realtek/8139cp.c
+++ b/drivers/net/ethernet/realtek/8139cp.c
@@ -554,11 +554,12 @@ static int cp_rx_poll(struct napi_struct *napi, int budget)
 	/* if we did not reach work limit, then we're done with
 	 * this round of polling
 	 */
-	if (rx < budget && napi_complete_done(napi, rx)) {
+	if (rx < budget) {
 		unsigned long flags;
 
 		spin_lock_irqsave(&cp->lock, flags);
-		cpw16_f(IntrMask, cp_intr_mask);
+		if (napi_complete_done(napi, rx))
+			cpw16_f(IntrMask, cp_intr_mask);
 		spin_unlock_irqrestore(&cp->lock, flags);
 	}
 

---
base-commit: 0df412012a26389582b120844d098e1e961f10a6
change-id: 20261021-b4-8139cp-napi-8e139f232736

Best regards,
--  
Colton Pawielski <colton.pawielski@gmail.com>

