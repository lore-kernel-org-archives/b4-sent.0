From: Maud Spierings <maud_spierings@hotmail.com>
Subject: [PATCH 0/2] arm64: dts: imx93-11x11-frdm: some fixes
Date: Sun, 06 Sep 2026 15:58:20 +0200
Message-Id: <20260906-imx93_frdm_rtc-v1-0-3fadbda0bea1@hotmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM2wpAQBCA4VfRXNsaq9bhVSSxBqMcmkVK3t3i8
 rv4/wscCZODPLhA6GDHy+wRhQHYoZ57Utx6g0ZtMEOjeDqzuOqknSrZrNJpanViDNaI4KNVqOP
 zGxblb7c3I9ntvcB9P5OL1khyAAAA
X-Change-ID: 20260906-imx93_frdm_rtc-288c27660a00
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Frank Li <Frank.Li@nxp.com>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788703104; l=7874;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=cMPtFeXnQwfMtY2iSNajkw8O1e5RkdUMYYTB7u99l2E=;
 b=zzKau0vv5VHeSSvG9I33HVEXMmbmyChfeZA+iYQwVMkfdSzM/udb94eilnbwsozb8/H1K1G1y
 EeGtY9MEDImCSEJ5JMOWkn157EWW3Mrklyo9D07CyYb7EcuD/6TkMPV
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pcf2131 has been assigned the rtc0 alias, but if the bbnsm_rtc gets
probed first it will take this name.

Properly assign bbnsm_rtc to rtc1 so that this doesn't happen

Add the power supply to the pcal6408 gpio expander, it doesn't have the
dependency loop like the pcal6524.

To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Frank Li <Frank.Li@nxp.com>
To: Sascha Hauer <s.hauer@pengutronix.de>
To: Pengutronix Kernel Team <kernel@pengutronix.de>
To: Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org
Cc: imx@lists.linux.dev
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-kernel@vger.kernel.org
Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>

----

On a side note, I'm seeing:

[   16.100470] fec 42890000.ethernet: Invalid MAC address: 00:00:00:00:00:00
[   16.109866] fec 42890000.ethernet: Using random MAC address: 4e:1b:bb:80:4c:90

But I'm not actually getting a random MAC address, it is constently:
f6:32:43:09:2e:b7

Something off about the nvmem reading or something?

I am also consistently getting crashes on this next tag, also without my
changes:

[   42.718742] Unable to handle kernel NULL pointer dereference at virtual address 0000000000000000
[   42.727600] Mem abort info:
[   42.730527]   ESR = 0x0000000096000004
[   42.734649]   EC = 0x25: DABT (current EL), IL = 32 bits
[   42.739988]   SET = 0, FnV = 0
[   42.743047]   EA = 0, S1PTW = 0
[   42.746189]   FSC = 0x04: level 0 translation fault
[   42.751066] Data abort info:
[   42.754272]   ISV = 0, ISS = 0x00000004, ISS2 = 0x00000000
[   42.759793]   CM = 0, WnR = 0, TnD = 0, TagAccess = 0
[   42.764844]   GCS = 0, Overlay = 0, DirtyBit = 0
[   42.769492] user pgtable: 4k pages, 48-bit VAs, pgdp=0000000087f6d000
[   42.776247] [0000000000000000] pgd=0000000000000000, p4d=0000000000000000
[   42.783070] Internal error: Oops: 0000000096000004 [#1]  SMP
[   42.788724] Modules linked in: btnxpuart hci_uart btqca snd_soc_fsl_mqs snd_soc_fsl_sai btrtl imx_pcm_dma btbcm snd_soc_fsl_utils sm_misc btintel snd_soc_core bluetooth tcpci tcpm aes_ce_blk ghash_ce gf128mul snd_compress ethosu typec ac97_bus sm4 gpu_sched snd_pcm_dmaengine fsl_imx9_ddr_perf thunderbolt reset_gpio phy_generic snd_pcm drm_dma_helper drm_kms_helper motorcomm nvmem_imx_ocotp_ele snd_timer at24 rtc_nxp_bbnsm nxp_bbnsm_pwrkey rtc_pcf2127 imx_rproc snd flexcan qoriq_thermal can_dev sm_lmm fec imx93_adc imx7ulp_wdt soundcore industrialio sm_cpu dwmac_imx rfkill drm crypto_user mmc_block rpmb_core gpio_keys phy_can_transceiver
[   42.845147] CPU: 0 UID: 0 PID: 130 Comm: jbd2/mmcblk0p2- Not tainted 7.3.0-rc1-next-20260904 #26 PREEMPT(full)  858e134aa3e8368ae2529c7f3178854a425a3e2b
[   42.858774] Hardware name: fsl NXP i.MX93 11X11 FRDM board, BIOS barebox 2026.08.0-00258-g32c817c9dbf0 #15 Sat Sep 5 21:03:53 CEST 2026 08/01/2026
[   42.871879] pstate: 60400009 (nZCv daif +PAN -UAO -TCO -DIT -SSBS BTYPE=--)
[   42.878828] pc : __bh_submit+0xa8/0x210
[   42.882659] lr : __bh_submit+0x9c/0x210
[   42.886490] sp : ffff800083793bf0
[   42.889791] x29: ffff800083793bf0 x28: ffff0000068f6030 x27: ffff000028f760cc
[   42.896915] x26: 0000000000000000 x25: 0000000003000000 x24: ffff00000052dc48
[   42.904039] x23: 0000000000000000 x22: 0000000000000000 x21: ffff8000806c5ad0
[   42.911163] x20: ffff00000ad9f000 x19: ffff000001a24480 x18: ffff7ffffd6de000
[   42.918288] x17: 0000000000000000 x16: 0000000000000000 x15: 0000000000000000
[   42.925412] x14: 0000000000000000 x13: 0000000000000000 x12: 0000000000000000
[   42.932535] x11: 0000000000000000 x10: fffffdffc0e56040 x9 : ffff800080972ac4
[   42.939659] x8 : ffff000007e3a888 x7 : 000000000000000d x6 : 000000000000000d
[   42.946783] x5 : 00000000000004c3 x4 : ffff8000828df140 x3 : 0000000000000001
[   42.953908] x2 : 0000000000009801 x1 : 0000000000000000 x0 : 0000000000000000
[   42.961032] Call trace:
[   42.963469]  __bh_submit+0xa8/0x210 (P)
[   42.967298]  bh_submit+0x24/0x38
[   42.970522]  jbd2_journal_commit_transaction+0xb98/0x1d20
[   42.975912]  kjournald2+0xb8/0x238
[   42.979310]  kthread+0x134/0x150
[   42.982534]  ret_from_fork+0x10/0x20
[   42.986108] Code: 940e488e aa0003f4 f9400a60 b9404fe2 (f9400003) 
[   42.992190] ---[ end trace 0000000000000000 ]---
[   42.997146] ------------[ cut here ]------------
[   43.001767] WARNING: kernel/exit.c:935 at do_exit+0x914/0xb78, CPU#0: jbd2/mmcblk0p2-/130
[   43.009938] Modules linked in: btnxpuart hci_uart btqca snd_soc_fsl_mqs snd_soc_fsl_sai btrtl imx_pcm_dma btbcm snd_soc_fsl_utils sm_misc btintel snd_soc_core bluetooth tcpci tcpm aes_ce_blk ghash_ce gf128mul snd_compress ethosu typec ac97_bus sm4 gpu_sched snd_pcm_dmaengine fsl_imx9_ddr_perf thunderbolt reset_gpio phy_generic snd_pcm drm_dma_helper drm_kms_helper motorcomm nvmem_imx_ocotp_ele snd_timer at24 rtc_nxp_bbnsm nxp_bbnsm_pwrkey rtc_pcf2127 imx_rproc snd flexcan qoriq_thermal can_dev sm_lmm fec imx93_adc imx7ulp_wdt soundcore industrialio sm_cpu dwmac_imx rfkill drm crypto_user mmc_block rpmb_core gpio_keys phy_can_transceiver
[   43.066355] CPU: 0 UID: 0 PID: 130 Comm: jbd2/mmcblk0p2- Tainted: G      D             7.3.0-rc1-next-20260904 #26 PREEMPT(full)  858e134aa3e8368ae2529c7f3178854a425a3e2b
[   43.081543] Tainted: [D]=DIE
[   43.084419] Hardware name: fsl NXP i.MX93 11X11 FRDM board, BIOS barebox 2026.08.0-00258-g32c817c9dbf0 #15 Sat Sep 5 21:03:53 CEST 2026 08/01/2026
[   43.097524] pstate: 80400009 (Nzcv daif +PAN -UAO -TCO -DIT -SSBS BTYPE=--)
[   43.104474] pc : do_exit+0x914/0xb78
[   43.108044] lr : make_task_dead+0x84/0x1b8
[   43.112135] sp : ffff800083793840
[   43.115437] x29: ffff800083793860 x28: ffff000005461440 x27: ffff000028f760cc
[   43.122561] x26: 0000000000000000 x25: 0000000003000000 x24: 0000000000000000
[   43.129685] x23: ffff8000805a99f0 x22: 0000000000000000 x21: ffff000005461440
[   43.136809] x20: ffff800083793ab0 x19: 000000000000000b x18: ffff7ffffd6de000
[   43.143933] x17: ffff8000800ec2c4 x16: ffff8000811a1820 x15: ffff8000823823e0
[   43.151057] x14: ffff80008225b140 x13: 0000000000000181 x12: ffff00007f939140
[   43.158181] x11: 00000000000000c0 x10: 0000000000000f80 x9 : ffff8000800e9e3c
[   43.165305] x8 : ffff000005462420 x7 : 0000000000000000 x6 : 000000000000000b
[   43.172429] x5 : ffff000005461440 x4 : ffff000005461440 x3 : ffff000000ed4f18
[   43.179552] x2 : 000000000000270f x1 : 0000000000000000 x0 : ffff800083793cf8
[   43.186677] Call trace:
[   43.189113]  do_exit+0x914/0xb78 (P)
[   43.192684]  make_task_dead+0x84/0x1b8
[   43.196427]  die+0x150/0x170
[   43.199304]  die_kernel_fault+0x2b8/0x3b8
[   43.203308]  __do_kernel_fault+0x220/0x230
[   43.207399]  do_page_fault+0x10c/0x7a0
[   43.211143]  do_translation_fault+0x38/0x60
[   43.215320]  do_mem_abort+0x48/0xa0
[   43.218804]  el1_abort+0x44/0x68
[   43.222028]  el1h_64_sync_handler+0x50/0xb8
[   43.226206]  el1h_64_sync+0x6c/0x70
[   43.229690]  __bh_submit+0xa8/0x210 (P)
[   43.233520]  bh_submit+0x24/0x38
[   43.236744]  jbd2_journal_commit_transaction+0xb98/0x1d20
[   43.242135]  kjournald2+0xb8/0x238
[   43.245532]  kthread+0x134/0x150
[   43.248756]  ret_from_fork+0x10/0x20
[   43.252328] ---[ end trace 0000000000000000 ]---

---
Maud Spierings (2):
      arm64: dts: imx93-11x11-frdm-common: fix the rtc aliases
      arm64: dts: imx93-11x11-frdm: add missing vcc-supply

 arch/arm64/boot/dts/freescale/imx93-11x11-frdm-common.dtsi | 1 +
 arch/arm64/boot/dts/freescale/imx93-11x11-frdm.dts         | 1 +
 2 files changed, 2 insertions(+)
---
base-commit: af5f12805e5cefa4fe68d6127c7e1fb78cd5535c
change-id: 20260906-imx93_frdm_rtc-288c27660a00

Best regards,
--  
Maud Spierings <maud_spierings@hotmail.com>

