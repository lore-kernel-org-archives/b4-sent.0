From: Mathieu Anquetin <mathieu.anquetin@groupe-cahors.com>
Date: Fri, 18 Jul 2025 20:12:42 +0200
Subject: [PATCH] ddr: imx9: fix DRAM PLL bypass
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250718-fix_imx9_ddr_init-v1-1-b52def9e7ee5@groupe-cahors.com>
X-B4-Tracking: v=1; b=H4sIAJmOemgC/x2MQQqAIBAAvxJ7TtDAyr4SIalr7SELjRCkvycdB
 2amQMJImGBqCkR8KNEZKoi2AbuvYUNGrjJ0vJN8ECPzlDUdWWnnoqZAN+ut9coZoaRBqN0VsUr
 /c17e9wMDltsGYwAAAA==
X-Change-ID: 20250718-fix_imx9_ddr_init-6ccf9db195be
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Fabian Pflug <f.pflug@pengutronix.de>, 
 Jonas Rebmann <jre@pengutronix.de>, 
 Mathieu Anquetin <mathieu.anquetin@groupe-cahors.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752862374; l=2373;
 i=mathieu.anquetin@groupe-cahors.com; s=20250718; h=from:subject:message-id;
 bh=HowQP+torUhauTWq0kKmO0H7oJKz/aam9Q83yTfB5TY=;
 b=gk92oCgWs2HRtgMgtVngljc/32/dHQ8jCTD3jgb2NeTcZ0hMX5S+nrI26cdeWpuOHJIN/Nvp6
 KeRNrUdxxpRDtn44TEo2reQ+sD5a13jsEd1+hC+L99cdo7lCjaT6Efg
X-Developer-Key: i=mathieu.anquetin@groupe-cahors.com; a=ed25519;
 pk=nJFDztEGb9FZien6U0hPMKsmzbuAD/RxZ05w64dA5U8=
X-Endpoint-Received: by B4 Relay for mathieu.anquetin@groupe-cahors.com/20250718 with auth_id=464
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On i.MX9, clock selection for DDR PHY is done by setting/clearing bit 0
of GPR_SHARED2 register.

This is done using the generic function ccm_shared_gpr_set() which takes
two arguments, the GPR number and the value to set. However, this
function did not use the GPR number to calculate the offset of the
GPR_SHAREDn register to set in the CCM.

Therefore, it was not possible to enable/disable DRAM PLL bypass
correctly and this led to hangs when training the DDR PHY with some
frequencies (like 625MT/s).

Fixes: e6234f907416 ("ddr: Initial i.MX9 support")
Signed-off-by: Mathieu Anquetin <mathieu.anquetin@groupe-cahors.com>
---
Some DRAM timing configurations require to change the input clock signal
and to bypass the DRAM PLL. This is done by setting bit 0 of the
GPR_SHARED2 register of the CLock Controller Module. However, the
register offset to set was not calculated correctly, leading to hangs
during PHY training when PLL bypass was required.

In particular, this was the case for the configuration setting the FSP
to 625MT/s.
---
 drivers/ddr/imx/imx9_ddr_init.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/ddr/imx/imx9_ddr_init.c b/drivers/ddr/imx/imx9_ddr_init.c
index cdee18e4ad0e4cee1b13bd2aab4b53ffcb537e49..086827d9b34c49a76426289b707aad6fa474d065 100644
--- a/drivers/ddr/imx/imx9_ddr_init.c
+++ b/drivers/ddr/imx/imx9_ddr_init.c
@@ -352,6 +352,8 @@ static void save_trained_mr12_14(struct dram_cfg_param *cfg, u32 cfg_num, u32 mr
 
 #define MHZ(x)        ((x) * 1000000UL)
 
+#define SHARED_GPR(n) (0x4800 + ((n) * 0x20))
+
 #define SHARED_GPR_DRAM_CLK 2
 #define SHARED_GPR_DRAM_CLK_SEL_PLL 0
 #define SHARED_GPR_DRAM_CLK_SEL_CCM BIT(0)
@@ -376,7 +378,7 @@ static int dram_pll_init(u32 freq)
 
 static void ccm_shared_gpr_set(u32 gpr, u32 val)
 {
-	writel(val, IOMEM(MX9_CCM_BASE_ADDR + 0x4800));
+	writel(val, IOMEM(MX9_CCM_BASE_ADDR + SHARED_GPR(gpr)));
 }
 
 #define DRAM_ALT_CLK_ROOT	76

---
base-commit: f49c873d7ec78a2df7bd3c7a86f5372fb1666517
change-id: 20250718-fix_imx9_ddr_init-6ccf9db195be

Best regards,
-- 
*Mathieu ANQUETIN*
/Software Developer/

CRDE -- Groupe Cahors   | http://www.groupe-cahors.com
ZI des Grands Camps     | Phone: +33 (0)5 65 30 38 77
46090 Mercuès -- France |

*GROUPE CAHORS* is a member of the UN Global Compact.

