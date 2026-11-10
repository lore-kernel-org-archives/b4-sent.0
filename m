From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/5] iommu/rockchip: page fault and reset handling fixes
Date: Tue, 10 Nov 2026 07:11:01 +0000
Message-Id: <20261110-iommu-rockchip-faults-v1-0-b1dda574dbb8@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDQAxA0atI1gYmWlrwKuJCY6xp1ZGJIwXx7
 p3a5Vv8f4BJUDGosgOC7GrqlwTKM+CxXZ6C2idD4Yo7ETlUP88Rg+c3j7ri0MZpM3RMciMuS+k
 fkNo1yKCf61s3f1vsXsLbbwbn+QVgbv1SeQAAAA==
X-Change-ID: 20261110-iommu-rockchip-faults-0c1e41c33ed7
To: "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Heiko Stuebner <heiko@sntech.de>, 
 Jeffy Chen <jeffy.chen@rock-chips.com>, Tomasz Figa <tfiga@chromium.org>
Cc: iommu@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294661; l=2716;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=EVE6rslJ+MxVLh2zqLrK9ywoULAK+Ds7e7R8Zqqqths=;
 b=9bGcN+GIhtCncaZ8ZLHC53JlkjNg3jVgIgvQEQAkW4iSUdfYezFR7FGwUR8NRUoZnzZEL+Yid
 iB8ETkxsDd3DIUTh0Ydv54S7RXFOQry1UXqIuXxjBHL/4bqaizplv0U
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes for the Rockchip IOMMU found on an Orange Pi 5 (RK3588S) while
making the video codec drivers recover from bad jobs (Hantro VEPU121
JPEG encoder, rkvdec VDPU381 decoder):

1. log_iova() walked a page table that a master's own reset had taken
   away (DTE_ADDR read as 0) and oopsed under KASAN.
2. A master that keeps faulting on unmapped memory printed three lines
   per fault from the hard interrupt handler; on a 115200 baud console
   one bad job kept the CPU in rk_iommu_irq() for 2 s. Rate-limit it.
3. FORCE_RESET swapped the poll period and the timeout.
4. The stall/paging helpers skipped a bank whose state differed from
   the other bank; the two banks of an RK3588 decoder IOMMU were read
   back in different states after a reset that timed out.
5. In a page fault storm the IOMMU now leaves the fault pending (which
   holds the master) and masks the interrupt until the master's driver
   resets and re-attaches it, or 100 ms pass. Before, one bad JPEG
   encode job kept CPU0 in interrupt context until the soft lockup
   detector and then the hardware watchdog reset the board.

Tested on an Orange Pi 5 (RK3588S): patch 1 with an rkvdec fault
injection run under KASAN (the "page table lost to a reset" path taken
14 times in 3178 decoder recoveries and 96 injected faults, no other
report); patches 2 and 5 with a VEPU121 JPEG encode job given an
unmapped input address, ten times (the storm held after 65 faults,
rk_iommu_irq() 0.8 to 1.7 ms per bad job instead of 2.02 s, the
encoder's timeout reset the core every time, and the GStreamer pipeline
that used to lock the board up ran to its end ten times). The whole
series has been in the board's kernel since, including MPEG-4 and VP9
decoder bring-up runs that hit page fault storms and recovered.

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit messages, and I reviewed and tested
every change as described above.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (5):
      iommu/rockchip: Don't walk a page table that a reset took away
      iommu/rockchip: Rate-limit the page fault reports
      iommu/rockchip: Fix the poll period and timeout of FORCE_RESET
      iommu/rockchip: Don't skip a bank whose state differs from the others
      iommu/rockchip: Hold the master in a page fault storm

 drivers/iommu/rockchip-iommu.c | 217 ++++++++++++++++++++++++++++++++++++-----
 1 file changed, 192 insertions(+), 25 deletions(-)
---
base-commit: 2cf4be57b301ed2d7af82e70cff5dfd96894d8de
change-id: 20261110-iommu-rockchip-faults-0c1e41c33ed7

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

