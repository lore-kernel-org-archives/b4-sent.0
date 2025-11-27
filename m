From: Maud Spierings <maudspierings@gocontroll.com>
Date: Thu, 27 Nov 2025 15:18:52 +0100
Subject: [PATCH] ARM: i.MX8M: Fix the RAM size calculation for DDR3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251127-ddr3_size-v1-1-cb26cadcb348@gocontroll.com>
X-B4-Tracking: v=1; b=H4sIAMtdKGkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDQyNz3ZSUIuP44syqVN3kZANjQwtLA7M0UwMloPqCotS0zAqwWdGxtbU
 AvNR9L1sAAAA=
X-Change-ID: 20251127-ddr3_size-cc0318906f50
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764253135; l=1641;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=S/1+D57OXDOXBoJu1ee59GubYFVu0yhihDlh11/cdtg=;
 b=sjH8KsDCwabGRl0tgeN20OpBWfP+a4TumFB41XRee8MEcYV5UkCNMDUbxzp5yoBIj4FxYgNjm
 yVaC8k1Ej+7BOQum37GuXZ2Juf1e9ZrX8GhYoawpSPiRVzW4IvI1xMJ
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The default value in the MSTR register for DDRC_MSTR_DEVICE_CONFIG is
16bit which causes the calculation to be half of the actual RAM. Add the
BIT() define for DDR3 and add it to the workaround for calculating the
correct amount of RAM like LPDDR4.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 arch/arm/mach-imx/esdctl.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/arch/arm/mach-imx/esdctl.c b/arch/arm/mach-imx/esdctl.c
index 4c4c3528e1..935c3d3257 100644
--- a/arch/arm/mach-imx/esdctl.c
+++ b/arch/arm/mach-imx/esdctl.c
@@ -325,6 +325,7 @@ static int vf610_ddrmc_add_mem(void *mmdcbase, const struct imx_esdctl_data *dat
 #define DDRC_ADDRMAP0_CS_BIT0			GENMASK(4, 0)
 
 #define DDRC_MSTR				0x0000
+#define DDRC_MSTR_DDR3				BIT(0)
 #define DDRC_MSTR_DDR4				BIT(4)
 #define DDRC_MSTR_LPDDR4			BIT(5)
 #define DDRC_MSTR_DATA_BUS_WIDTH		GENMASK(13, 12)
@@ -508,8 +509,8 @@ static resource_size_t imx8m_ddrc_sdram_size(void __iomem *ddrc, unsigned buswid
 		FIELD_GET(DDRC_ADDRMAP6_LPDDR4_6GB_12GB_24GB, addrmap[6]);
 	u32 mstr = readl(ddrc + DDRC_MSTR);
 
-	/* Device config is ignored and taken as 32-bit for LPDDR4 */
-	if (mstr & DDRC_MSTR_LPDDR4)
+	/* Device config is ignored and taken as 32-bit for LPDDR4 and DDR3 */
+	if (mstr & DDRC_MSTR_LPDDR4 || mstr & DDRC_MSTR_DDR3)
 		imx_ddrc_set_mstr_device_config(&mstr, buswidth);
 
 	return imx_ddrc_sdram_size(ddrc, addrmap,

---
base-commit: 5d89bec4985d850d59813e34c6b5213d8e8f48f0
change-id: 20251127-ddr3_size-cc0318906f50

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

