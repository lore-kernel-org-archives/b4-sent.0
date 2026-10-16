From: Petr Hodina <petr.hodina@protonmail.com>
Date: Fri, 16 Oct 2026 22:13:51 +0200
Subject: [PATCH 2/2] clk: qcom: sdm845: add GCC_QUPV3_WRAP0_S4_CLK case
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-b4-sdm845-qupv3-s4-v1-2-672e9be21fd2@protonmail.com>
References: <20261016-b4-sdm845-qupv3-s4-v1-0-672e9be21fd2@protonmail.com>
In-Reply-To: <20261016-b4-sdm845-qupv3-s4-v1-0-672e9be21fd2@protonmail.com>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot@lists.u-boot-project.org, 
 u-boot-qcom@groups.io
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Lukasz Majewski <lukma@denx.de>, David Wronek <david.wronek@mainlining.org>, 
 David Heidelberg <david@ixit.cz>, Petr Pavlata <petr@acrux.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792181640; l=1943;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=f/ZVYYX99vkm0yr1LN794ymXRles7Exb/TzmXveMDL4=;
 b=P+5kD+RjwjaIz9cEd9kCRMdDgRgeCdB8Wh+ypzPKcWxji5XCSQKsSoHxeNsaXgvVXrVHJF3r2
 PKzrLX2f5NhDVLWIDbPCdqob0A2pOj0/x7Ar2+CfdB2rw/zCrQ6z5sY
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sdm845_clk_set_rate() handles the UART9 and SDCC2 clocks but not the
QUP0 SE4 SPI clock.

Add a GCC_QUPV3_WRAP0_S4_CLK case using the standard wrap0_s0
frequency table.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/clk/qcom/clock-sdm845.c | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/qcom/clock-sdm845.c b/drivers/clk/qcom/clock-sdm845.c
index c9a057cf6f9..b2fb44083bf 100644
--- a/drivers/clk/qcom/clock-sdm845.c
+++ b/drivers/clk/qcom/clock-sdm845.c
@@ -18,6 +18,7 @@
 
 #include "clock-qcom.h"
 
+#define SE4_SPI_APPS_CMD_RCGR	0x174f4
 #define SE9_UART_APPS_CMD_RCGR	0x18148
 
 #define USB30_PRIM_MASTER_CLK_CMD_RCGR 0xf018
@@ -77,7 +78,7 @@ static ulong sdm670_clk_set_rate(struct clk *clk, ulong rate)
 	case GCC_SDCC1_APPS_CLK:
 		freq = qcom_find_freq(ftbl_gcc_sdcc1_apps_clk_src, rate);
 		clk_rcg_set_rate_mnd(priv->base, SDCC1_APPS_CLK_CMD_RCGR,
-				     freq->pre_div, freq->m, freq->n, freq->src, 8);
+				     freq->pre_div, freq->m, freq->n, freq->src, 16);
 		return freq->freq;
 	default:
 		return 0;
@@ -95,10 +96,15 @@ static ulong sdm845_clk_set_rate(struct clk *clk, ulong rate)
 		clk_rcg_set_rate_mnd(priv->base, SE9_UART_APPS_CMD_RCGR,
 				     freq->pre_div, freq->m, freq->n, freq->src, 16);
 		return freq->freq;
+	case GCC_QUPV3_WRAP0_S4_CLK: /* QUP0 SE4 SPI */
+		freq = qcom_find_freq(ftbl_gcc_qupv3_wrap0_s0_clk_src, rate);
+		clk_rcg_set_rate_mnd(priv->base, SE4_SPI_APPS_CMD_RCGR,
+				     freq->pre_div, freq->m, freq->n, freq->src, 16);
+		return freq->freq;
 	case GCC_SDCC2_APPS_CLK:
 		freq = qcom_find_freq(ftbl_gcc_sdcc2_apps_clk_src, rate);
 		clk_rcg_set_rate_mnd(priv->base, SDCC2_APPS_CLK_CMD_RCGR,
-				     freq->pre_div, freq->m, freq->n, freq->src, 8);
+				     freq->pre_div, freq->m, freq->n, freq->src, 16);
 		return freq->freq;
 	default:
 		return 0;

-- 
2.55.0

