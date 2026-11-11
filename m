From: Charlie Jenkins <charjenkins@tesla.com>
Date: Tue, 10 Nov 2026 17:48:05 -0800
Subject: [PATCH] scsi: ufs: exynos: Access HCI regs only while core_clk is
 enabled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-ufs_exynos_hci_order-v1-1-ce3cf68a74d5@tesla.com>
X-B4-Tracking: v=1; b=H4sIAFTJ82oC/yXMyw6CMBBG4Vchs7ZJC95fhZgGyl8ZF62ZEYIhv
 LtVl9/inJUUwlC6VisJZlbOqcDtKgpjl+4wPBRTbeujc86aKarH8k5Z/RjYZxkgxqK79GfbHOL
 +RCV9CiIvv217+1un/oHw+r5o2z7Z+44JeAAAAA==
X-Change-ID: 20261110-ufs_exynos_hci_order-0ea9b8035f47
To: Alim Akhtar <alim.akhtar@samsung.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <mkp@kernel.org>, 
 Krzysztof Kozlowski <krzk@kernel.org>, 
 Chanho Park <chanho61.park@samsung.com>
Cc: linux-samsung-soc@vger.kernel.org, linux-scsi@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Charlie Jenkins <charjenkins@tesla.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794361735; l=2641;
 i=charjenkins@tesla.com; s=20261111; h=from:subject:message-id;
 bh=LAh4uxWJEJlM8NfNlEbxljfVuT2qoU7HqStq10W2Hns=;
 b=haIPNM/jxHhhj/GSLWYwPRTnUfCL/f3zCVGefXGiNVccdK//pUwTS3Lc0hUuzWhloFIVkRzL2
 GZ1rf3a9tJkDF7Dr5ZTJtqe18buZ0G92aaoVtxpEGl/wjADim/B72k5
X-Developer-Key: i=charjenkins@tesla.com; a=ed25519;
 pk=UcHY2MxMlGrG4OWEpbHAPZ2iB7xhVAktL8U7+7y1MhU=
X-Endpoint-Received: by B4 Relay for charjenkins@tesla.com/20261111 with auth_id=1484
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The current clock setup attempts to program the HCI clock-stop registers
after the core clock has already been brought down. With this ordering
on a reboot, the HCI bus clock is stopped before the clock-stop
accesses, triggering an SError on the power-down path.

SError Interrupt on CPU5, code 0x00000000bf000002 -- SError
pc : readl+0x4/0x18
lr : hci_readl.isra.0+0x14/0x20
Kernel panic - not syncing: Asynchronous SError Interrupt
Call trace:
 readl+0x4/0x18
 exynos_ufs_ctrl_clkstop+0x30/0xac
 exynos_ufs_setup_clocks+0x8c/0xa4
 ufshcd_setup_clocks+0x1c8/0x2a0
 ufshcd_suspend+0x4c/0xa8
 ufshcd_wl_shutdown+0x88/0xd4
 device_shutdown+0x158/0x1d8
 kernel_restart_prepare+0x40/0x4c
 kernel_restart+0x20/0x88
 __do_sys_reboot+0x198/0x218

This is visible on FSD, where the CMU gates are in manual mode so
disabling core_clk really stops the clock.

Ungate in POST_CHANGE when turning clocks on and gate in PRE_CHANGE
when turning them off, so the HCI registers are only accessed while
core_clk is running.

Fixes: 91c49e7e82d7 ("scsi: ufs: ufs-exynos: Add setup_clocks callback")
Signed-off-by: Charlie Jenkins <charjenkins@tesla.com>
---
Found on a Tesla FSD board.
---
 drivers/ufs/host/ufs-exynos.c | 8 +++++---
 1 file changed, 5 insertions(+), 3 deletions(-)

diff --git a/drivers/ufs/host/ufs-exynos.c b/drivers/ufs/host/ufs-exynos.c
index 3bcbc9ebbb283..d2a79ebf193e3 100644
--- a/drivers/ufs/host/ufs-exynos.c
+++ b/drivers/ufs/host/ufs-exynos.c
@@ -1116,11 +1116,11 @@ static int exynos_ufs_setup_clocks(struct ufs_hba *hba, bool on,
 	if (!ufs)
 		return 0;
 
-	if (on && status == PRE_CHANGE) {
+	if (on && status == POST_CHANGE) {
 		if (ufs->opts & EXYNOS_UFS_OPT_BROKEN_AUTO_CLK_CTRL)
 			exynos_ufs_disable_auto_ctrl_hcc(ufs);
 		exynos_ufs_ungate_clks(ufs);
-	} else if (!on && status == POST_CHANGE) {
+	} else if (!on && status == PRE_CHANGE) {
 		exynos_ufs_gate_clks(ufs);
 		if (ufs->opts & EXYNOS_UFS_OPT_BROKEN_AUTO_CLK_CTRL)
 			exynos_ufs_enable_auto_ctrl_hcc(ufs);
@@ -1139,7 +1139,9 @@ static int exynos_ufs_pre_link(struct ufs_hba *hba)
 	exynos_ufs_config_intr(ufs, DFES_DEF_L4_ERRS, UNIPRO_L4);
 	exynos_ufs_set_unipro_pclk_div(ufs);
 
-	exynos_ufs_setup_clocks(hba, true, PRE_CHANGE);
+	if (ufs->opts & EXYNOS_UFS_OPT_BROKEN_AUTO_CLK_CTRL)
+		exynos_ufs_disable_auto_ctrl_hcc(ufs);
+	exynos_ufs_ungate_clks(ufs);
 
 	/* unipro */
 	exynos_ufs_config_unipro(ufs);

---
base-commit: e550f2b2b4aab4c5f12db89d04d8978ce4ed7b4e
change-id: 20261110-ufs_exynos_hci_order-0ea9b8035f47

Best regards,
--  
Charlie Jenkins <charjenkins@tesla.com>

