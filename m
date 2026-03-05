From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 05 Mar 2026 10:15:38 +0100
Subject: [PATCH v2] powerpc: dts: Build devicetrees of enabled platforms
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260305-mpc83xx-dtb-v2-1-cdb751458445@posteo.net>
X-B4-Tracking: v=1; b=H4sIALlJqWkC/1XMyw7CIBCF4VdpZi2GGdQUV30P00Uvg2VhaYAQT
 MO7i40bl/9JzrdDYG85wL3ZwXOywbq1Bp0amJZhfbKwc20gSTeJEsVrm1qVs5jjKEjNuh1QSyY
 F9bF5NjYf2qOvvdgQnX8feMLv+nNQ/zkJBYorkWkvSFqOpttciOzOK0foSykf07eXY6cAAAA=
X-Change-ID: 20260101-mpc83xx-dtb-23d98a190e23
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>
Cc: devicetree@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Geert Uytterhoeven <geert@linux-m68k.org>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772702150; l=9718;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=5WxZOnJ2RnhvLzP27DbvhYw+ZWyImRomywuyAQF0f/k=;
 b=h2Q+JEKbP0h0D0X2Q1BEfMgXJrHRh/eBrLicOOR2XFBOByA20z+ZDJueBhj/ZfPRA6cKQEMsR
 WsDcbZu8SQvDIPLtYSrKI762GE9OSqUwE7H5xu/lJ9yso59gsxd1BtU
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Follow the same approach as other architectures such as Arm or RISC-V,
and build devicetrees based on platforms selected in Kconfig. This makes
it unnecessary to use CONFIG_OF_ALL_DTBS on PowerPC in order to build
DTB files.

This makes it easier to use other build and test infrastructure such as
`make dtbs_check`, and is a first step towards generating FIT images
that include all the relevant DTBs with `make image.fit`.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
Changes in v2:
- Use "dtb-$(FOO) += foo.dtb" format on every line, avoid backslashes
  (suggested by Geert Uytterhoeven)
- Link to v1: https://lore.kernel.org/r/20260119-mpc83xx-dtb-v1-1-522f841290bf@posteo.net
---
 arch/powerpc/boot/dts/Makefile     | 111 +++++++++++++++++++++++++++++++++++++
 arch/powerpc/boot/dts/fsl/Makefile |  79 ++++++++++++++++++++++++++
 2 files changed, 190 insertions(+)

diff --git a/arch/powerpc/boot/dts/Makefile b/arch/powerpc/boot/dts/Makefile
index 0cd0d8558b475c..7fce8c819d3d72 100644
--- a/arch/powerpc/boot/dts/Makefile
+++ b/arch/powerpc/boot/dts/Makefile
@@ -3,3 +3,114 @@
 subdir-y += fsl
 
 dtb-$(CONFIG_OF_ALL_DTBS) := $(patsubst $(src)/%.dts,%.dtb, $(wildcard $(src)/*.dts))
+
+# PPC44x platforms
+dtb-$(CONFIG_PPC44x_SIMPLE) += arches.dtb
+dtb-$(CONFIG_PPC44x_SIMPLE) += bamboo.dtb
+dtb-$(CONFIG_PPC44x_SIMPLE) += bluestone.dtb
+dtb-$(CONFIG_PPC44x_SIMPLE) += glacier.dtb
+dtb-$(CONFIG_PPC44x_SIMPLE) += eiger.dtb
+dtb-$(CONFIG_PPC44x_SIMPLE) += katmai.dtb
+dtb-$(CONFIG_PPC44x_SIMPLE) += rainier.dtb
+dtb-$(CONFIG_PPC44x_SIMPLE) += redwood.dtb
+dtb-$(CONFIG_PPC44x_SIMPLE) += sequoia.dtb
+dtb-$(CONFIG_PPC44x_SIMPLE) += taishan.dtb
+dtb-$(CONFIG_PPC44x_SIMPLE) += yosemite.dtb
+dtb-$(CONFIG_PPC44x_SIMPLE) += icon.dtb
+dtb-$(CONFIG_EBONY) += ebony.dtb
+dtb-$(CONFIG_SAM440EP) += sam440ep.dtb
+dtb-$(CONFIG_WARP) += warp.dtb
+dtb-$(CONFIG_ISS4xx) += iss4xx.dtb
+dtb-$(CONFIG_ISS4xx) += iss4xx-mpic.dtb
+dtb-$(CONFIG_CANYONLANDS) += canyonlands.dtb
+dtb-$(CONFIG_CURRITUCK) += currituck.dtb
+dtb-$(CONFIG_AKEBONO) += akebono.dtb
+dtb-$(CONFIG_FSP2) += fsp2.dtb
+
+# Embedded 6xx platforms
+dtb-$(CONFIG_LINKSTATION) += kuroboxHG.dtb
+dtb-$(CONFIG_LINKSTATION) += kuroboxHD.dtb
+dtb-$(CONFIG_STORCENTER) += storcenter.dtb
+dtb-$(CONFIG_PPC_HOLLY) += holly.dtb
+dtb-$(CONFIG_GAMECUBE) += gamecube.dtb
+dtb-$(CONFIG_WII) += wii.dtb
+dtb-$(CONFIG_MVME5100) += mvme5100.dtb
+
+# MPC8xx platforms
+dtb-$(CONFIG_MPC885ADS) += mpc885ads.dtb
+dtb-$(CONFIG_MPC86XADS) += mpc866ads.dtb
+dtb-$(CONFIG_PPC_EP88XC) += ep88xc.dtb
+dtb-$(CONFIG_PPC_ADDER875) += adder875-redboot.dtb
+dtb-$(CONFIG_PPC_ADDER875) += adder875-uboot.dtb
+dtb-$(CONFIG_TQM8XX) += tqm8xx.dtb
+
+# MPC512x platforms
+dtb-$(CONFIG_MPC5121_ADS) += mpc5121ads.dtb
+dtb-$(CONFIG_MPC512x_GENERIC) += mpc5125twr.dtb
+dtb-$(CONFIG_MPC512x_GENERIC) += ac14xx.dts
+dtb-$(CONFIG_PDM360NG) += pdm360ng.dtb
+
+# MPC5200 platforms
+dtb-$(CONFIG_PPC_MPC5200_SIMPLE) += a3m071.dtb
+dtb-$(CONFIG_PPC_MPC5200_SIMPLE) += a4m072.dtb
+dtb-$(CONFIG_PPC_MPC5200_SIMPLE) += charon.dtb
+dtb-$(CONFIG_PPC_MPC5200_SIMPLE) += cm5200.dtb
+dtb-$(CONFIG_PPC_MPC5200_SIMPLE) += digsy_mtc.dtb
+dtb-$(CONFIG_PPC_MPC5200_SIMPLE) += motionpro.dtb
+dtb-$(CONFIG_PPC_MPC5200_SIMPLE) += mucmc52.dtb
+dtb-$(CONFIG_PPC_MPC5200_SIMPLE) += o2d.dtb
+dtb-$(CONFIG_PPC_MPC5200_SIMPLE) += o2d300.dtb
+dtb-$(CONFIG_PPC_MPC5200_SIMPLE) += o2dnt2.dtb
+dtb-$(CONFIG_PPC_MPC5200_SIMPLE) += o2i.dtb
+dtb-$(CONFIG_PPC_MPC5200_SIMPLE) += o2mnt.dtb
+dtb-$(CONFIG_PPC_MPC5200_SIMPLE) += o3dnt.dtb
+dtb-$(CONFIG_PPC_MPC5200_SIMPLE) += pcm030.dtb
+dtb-$(CONFIG_PPC_MPC5200_SIMPLE) += pcm032.dtb
+dtb-$(CONFIG_PPC_MPC5200_SIMPLE) += tqm5200.dtb
+dtb-$(CONFIG_PPC_MPC5200_SIMPLE) += uc101.dtb
+dtb-$(CONFIG_PPC_LITE5200) += lite5200.dtb
+dtb-$(CONFIG_PPC_LITE5200) += lite5200b.dtb
+dtb-$(CONFIG_PPC_MEDIA5200) += media5200.dtb
+
+# MPC82xx platforms
+dtb-$(CONFIG_EP8248E) += ep8248e.dtb
+dtb-$(CONFIG_MGCOGE) += mgcoge.dtb
+
+# MPC83xx platforms
+dtb-$(CONFIG_MPC830x_RDB) += mpc8308rdb.dtb
+dtb-$(CONFIG_MPC830x_RDB) += mpc8308_p1m.dtb
+dtb-$(CONFIG_MPC831x_RDB) += mpc8313erdb.dtb
+dtb-$(CONFIG_MPC831x_RDB) += mpc8315erdb.dtb
+dtb-$(CONFIG_MPC832x_RDB) += mpc832x_rdb.dtb
+dtb-$(CONFIG_MPC834x_ITX) += mpc8349emitx.dtb
+dtb-$(CONFIG_MPC834x_ITX) += mpc8349emitxgp.dtb
+dtb-$(CONFIG_ASP834x) += asp834x-redboot.dtb
+dtb-$(CONFIG_MPC836x_RDK) += mpc836x_rdk.dtb
+dtb-$(CONFIG_KMETER1) += kmeter1.dtb
+dtb-$(CONFIG_MPC837x_RDB) += mpc8377_rdb.dtb
+dtb-$(CONFIG_MPC837x_RDB) += mpc8378_rdb.dtb
+dtb-$(CONFIG_MPC837x_RDB) += mpc8379_rdb.dtb
+dtb-$(CONFIG_MPC837x_RDB) += mpc8377_wlan.dtb
+
+# MPC85xx platforms
+dtb-$(CONFIG_STX_GP3) += stx_gp3_8560.dtb
+dtb-$(CONFIG_STX_GP3) += stxssa8555.dtb
+dtb-$(CONFIG_TQM85xx) += tqm8540.dtb
+dtb-$(CONFIG_TQM85xx) += tqm8541.dtb
+dtb-$(CONFIG_TQM85xx) += tqm8548.dtb
+dtb-$(CONFIG_TQM85xx) += tqm8548-bigflash.dtb
+dtb-$(CONFIG_TQM85xx) += tqm8555.dtb
+dtb-$(CONFIG_TQM85xx) += tqm8560.dtb
+dtb-$(CONFIG_SOCRATES) += socrates.dtb
+dtb-$(CONFIG_KSI8560) += ksi8560.dtb
+dtb-$(CONFIG_XES_MPC85xx) += xcalibur1501.dtb
+dtb-$(CONFIG_XES_MPC85xx) += xpedite5200.dtb
+dtb-$(CONFIG_XES_MPC85xx) += xpedite5200_xmon.dtb
+dtb-$(CONFIG_XES_MPC85xx) += xpedite5301.dtb
+dtb-$(CONFIG_XES_MPC85xx) += xpedite5330.dtb
+dtb-$(CONFIG_XES_MPC85xx) += xpedite5370.dtb
+
+# Misc. platforms
+dtb-$(CONFIG_PPC_MICROWATT) += microwatt.dtb
+dtb-$(CONFIG_AMIGAONE) += amigaone.dtb
+dtb-$(CONFIG_PPC_PS3) += ps3.dtb
diff --git a/arch/powerpc/boot/dts/fsl/Makefile b/arch/powerpc/boot/dts/fsl/Makefile
index d3ecdf14bc42e7..9fd0badd89f198 100644
--- a/arch/powerpc/boot/dts/fsl/Makefile
+++ b/arch/powerpc/boot/dts/fsl/Makefile
@@ -1,3 +1,82 @@
 # SPDX-License-Identifier: GPL-2.0
 
 dtb-$(CONFIG_OF_ALL_DTBS) := $(patsubst $(src)/%.dts,%.dtb, $(wildcard $(src)/*.dts))
+
+# MPC85xx platforms
+dtb-$(CONFIG_BSC9131_RDB) += bsc9131rdb.dtb
+dtb-$(CONFIG_BSC9132_QDS) += bsc9132qds.dtb
+dtb-$(CONFIG_C293_PCIE) += c293pcie.dtb
+dtb-$(CONFIG_MPC8536_DS) += mpc8536ds.dtb
+dtb-$(CONFIG_MPC8536_DS) += mpc8536ds_36b.dtb
+dtb-$(CONFIG_MPC85xx_DS) += mpc8544ds.dtb
+dtb-$(CONFIG_MPC85xx_DS) += mpc8572ds_camp_core0.dtb
+dtb-$(CONFIG_MPC85xx_DS) += mpc8572ds_camp_core1.dtb
+dtb-$(CONFIG_MPC85xx_DS) += mpc8572ds_36b.dtb
+dtb-$(CONFIG_MPC85xx_DS) += mpc8572ds.dtb
+dtb-$(CONFIG_MPC85xx_MDS) += mpc8568mds.dtb
+dtb-$(CONFIG_MPC85xx_MDS) += mpc8569mds.dtb
+dtb-$(CONFIG_MPC85xx_MDS) += p1021mds.dtb
+dtb-$(CONFIG_MPC85xx_RDB) += p1020mbg-pc_32b.dtb
+dtb-$(CONFIG_MPC85xx_RDB) += p1020mbg-pc_36b.dtb
+dtb-$(CONFIG_MPC85xx_RDB) += p1020rdb_36b.dtb
+dtb-$(CONFIG_MPC85xx_RDB) += p1020rdb.dtb
+dtb-$(CONFIG_MPC85xx_RDB) += p1020rdb-pc_32b.dtb
+dtb-$(CONFIG_MPC85xx_RDB) += p1020rdb-pc_36b.dtb
+dtb-$(CONFIG_MPC85xx_RDB) += p1020rdb-pc_camp_core0.dtb
+dtb-$(CONFIG_MPC85xx_RDB) += p1020rdb-pc_camp_core1.dtb
+dtb-$(CONFIG_MPC85xx_RDB) += p1020rdb-pd.dtb
+dtb-$(CONFIG_MPC85xx_RDB) += p1020utm-pc_32b.dtb
+dtb-$(CONFIG_MPC85xx_RDB) += p1020utm-pc_36b.dtb
+dtb-$(CONFIG_MPC85xx_RDB) += p1021rdb-pc_32b.dtb
+dtb-$(CONFIG_MPC85xx_RDB) += p1021rdb-pc_36b.dtb
+dtb-$(CONFIG_MPC85xx_RDB) += p1024rdb_32b.dtb
+dtb-$(CONFIG_MPC85xx_RDB) += p1024rdb_36b.dtb
+dtb-$(CONFIG_MPC85xx_RDB) += p1025rdb_32b.dtb
+dtb-$(CONFIG_MPC85xx_RDB) += p1025rdb_36b.dtb
+dtb-$(CONFIG_P1010_RDB) += p1010rdb-pa_36b.dtb
+dtb-$(CONFIG_P1010_RDB) += p1010rdb-pa.dtb
+dtb-$(CONFIG_P1010_RDB) += p1010rdb-pb_36b.dtb
+dtb-$(CONFIG_P1010_RDB) += p1010rdb-pb.dtb
+dtb-$(CONFIG_P1022_DS) += p1022ds_32b.dtb
+dtb-$(CONFIG_P1022_DS) += p1022ds_36b.dtb
+dtb-$(CONFIG_P1022_RDK) += p1022rdk.dtb
+dtb-$(CONFIG_P1023_RDB) += p1023rdb.dtb
+dtb-$(CONFIG_PPC_P2020) += p2020ds.dtb
+dtb-$(CONFIG_PPC_P2020) += turris1x.dtb
+dtb-$(CONFIG_TWR_P102x) += p1025twr.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += b4420qds.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += b4860qds.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += cyrus_p5020.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += kmcent2.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += kmcoge4.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += oca4080.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += p2041rdb.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += p3041ds.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += p4080ds.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += p5020ds.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += p5040ds.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += t1023rdb.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += t1024qds.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += t1024rdb.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += t1040d4rdb.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += t1040qds.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += t1040rdb.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += t1040rdb-rev-a.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += t1042d4rdb.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += t1042qds.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += t1042rdb.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += t1042rdb_pi.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += t2080qds.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += t2080rdb.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += t2081qds.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += t4240qds.dtb
+dtb-$(CONFIG_CORENET_GENERIC) += t4240rdb.dtb
+dtb-$(CONFIG_PPA8548) += ppa8548.dtb
+dtb-$(CONFIG_GE_IMP3A) += ge_imp3a.dtb
+dtb-$(CONFIG_MVME2500) += mvme2500.dtb
+
+# MPC86xx platforms
+dtb-$(CONFIG_GEF_SBC310) += gef_sbc310.dtb
+dtb-$(CONFIG_GEF_SBC610) += gef_sbc610.dtb
+dtb-$(CONFIG_GEF_PPC9A) += gef_ppc9a.dtb
+dtb-$(CONFIG_MVME7100) += mvme7100.dtb

---
base-commit: 11439c4635edd669ae435eec308f4ab8a0804808
change-id: 20260101-mpc83xx-dtb-23d98a190e23

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

