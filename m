From: Kim Wooseok <5mghybrid@khu.ac.kr>
Subject: [PATCH rtw-next] wifi: rtl8xxxu: isolate the USB register buffer
Date: Sat, 10 Oct 2026 07:39:15 +0900
Message-Id: <20261010-rtl8xxxu-usb-dma-v1-0-e670d9c08fdf@khu.ac.kr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/z2MwQ7CIBBEf6XZs5tAQ1r1V4wHoFuLUTS7oCRN/
 13QxOPMvHkrCHEggWO3AtMrSHjEGvSuA7/YeCEMU83Qq37QSivkdNuXUjJmcTjdLfqDmc04kFZ
 mhHp7Ms2hfJUn4PTGSCXB+bdIdlfyqRkb66wQOrbRL63609v2AbDrgCuZAAAA
X-Change-ID: 20261010-rtl8xxxu-usb-dma-c94f476e1047
To: linux-wireless@vger.kernel.org
Cc: Jes Sorensen <Jes.Sorensen@gmail.com>, 
 Ping-Ke Shih <pkshih@realtek.com>, Kalle Valo <kvalo@kernel.org>, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Kim Wooseok <5mghybrid@khu.ac.kr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791585555; l=1272;
 i=5mghybrid@khu.ac.kr; s=kernel-20260913; h=from:subject:message-id;
 bh=KWpQFquq7avx1bUklcWT3BnzeA5u9h49N5vuVBzTD3k=;
 b=YCKDuTM5arzlyP5KChB/r3Xqskn7TypP3HRG1TFZaZUbljeb1n2LZ79C27gogbLTxln71VstU
 HvTbYg4enNeDdWP8kN2+SqY1cfmMUtdjCJgpRfVMTA0NcnizT/goeO1
X-Developer-Key: i=5mghybrid@khu.ac.kr; a=ed25519;
 pk=1az/6lC8Tmd6BcvyarPc8FWoSxsV/WRr5NLs1v+kjlE=
X-Endpoint-Received: by B4 Relay for 5mghybrid@khu.ac.kr/kernel-20260913 with auth_id=1028
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I encountered reconnect failures on four Raspberry Pis in my project.
While investigating the failure on a Raspberry Pi 5 after an AP power
cycle, I found that RF_MODE had been corrupted. Restoring its initialized
value restored reception without reloading the driver.

The USB register buffer shared a cache line with CPU-written mutex state.
This patch allocates the buffer separately while keeping the existing
register access and locking.

I tested the separate-buffer approach on the Pi's Linux 6.18.34 kernel.
During repeated scan requests, wireless ping traffic kept receiving
replies and the RF_MODE and HSSI values stayed stable. I also built the
submission's rtl8xxxu driver for ARM64 with W=1; sparse reported no
diagnostics in core.c.

Signed-off-by: Kim Wooseok <5mghybrid@khu.ac.kr>

---
Kim Wooseok (1):
      wifi: rtl8xxxu: isolate the USB register buffer from CPU state

 drivers/net/wireless/realtek/rtl8xxxu/core.c     | 35 ++++++++++++++++--------
 drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h |  2 +-
 2 files changed, 24 insertions(+), 13 deletions(-)
---
base-commit: 83de3a16c7b37064a59305040ba9b0f93b832794
change-id: 20261010-rtl8xxxu-usb-dma-c94f476e1047

Best regards,
--  
Kim Wooseok <5mghybrid@khu.ac.kr>

