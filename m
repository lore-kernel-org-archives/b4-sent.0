From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 24 Apr 2026 18:29:04 +0100
Subject: [PATCH RESEND] clk: clk-axi-clkgen: Add support versal timings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260424-clk-axi-clk-versal-support-v1-1-ea070f83db7e@analog.com>
To: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org
Cc: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777051758; l=2171;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=ZJ7v3IULEwypmWeLvk+oGggx/BI4TrC+oz+ZpJ6hz4g=;
 b=IgD3WmaOreQD7oiTcwpPbMcPlx3y0X2j0mblumLdpeNQOe5T+ZmEzCJUetlnQmbJze74wys4n
 eB0ydWoD9W2CzN4AWuMJKmGSXtH/ZOpEqZu7yLrBPYr1CEaeQA/STYh
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add proper VCO and PFD limits for versal based platforms. For that we
need to add new Technology and Speed grade defines.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/clk/clk-axi-clkgen.c   | 5 ++++-
 include/linux/adi-axi-common.h | 2 ++
 2 files changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/clk-axi-clkgen.c b/drivers/clk/clk-axi-clkgen.c
index fa5ccef73e60..26f76a6db820 100644
--- a/drivers/clk/clk-axi-clkgen.c
+++ b/drivers/clk/clk-axi-clkgen.c
@@ -521,7 +521,7 @@ static int axi_clkgen_setup_limits(struct axi_clkgen *axi_clkgen,
 		axi_clkgen->limits.fvco_max = 1200000;
 		axi_clkgen->limits.fpfd_max = 450000;
 		break;
-	case ADI_AXI_FPGA_SPEED_2 ... ADI_AXI_FPGA_SPEED_2LV:
+	case ADI_AXI_FPGA_SPEED_2 ... ADI_AXI_FPGA_SPEED_2MP:
 		axi_clkgen->limits.fvco_max = 1440000;
 		axi_clkgen->limits.fpfd_max = 500000;
 		if (family == ADI_AXI_FPGA_FAMILY_KINTEX || family == ADI_AXI_FPGA_FAMILY_ARTIX) {
@@ -546,6 +546,9 @@ static int axi_clkgen_setup_limits(struct axi_clkgen *axi_clkgen,
 	if (tech == ADI_AXI_FPGA_TECH_ULTRASCALE_PLUS) {
 		axi_clkgen->limits.fvco_max = 1600000;
 		axi_clkgen->limits.fvco_min = 800000;
+	} else if (tech == ADI_AXI_FPGA_TECH_VERSAL) {
+		axi_clkgen->limits.fvco_max = 4320000;
+		axi_clkgen->limits.fvco_min = 2160000;
 	}
 
 	return 0;
diff --git a/include/linux/adi-axi-common.h b/include/linux/adi-axi-common.h
index 37962ba530df..e7ba393061ee 100644
--- a/include/linux/adi-axi-common.h
+++ b/include/linux/adi-axi-common.h
@@ -51,6 +51,7 @@ enum adi_axi_fpga_technology {
 	ADI_AXI_FPGA_TECH_SERIES7,
 	ADI_AXI_FPGA_TECH_ULTRASCALE,
 	ADI_AXI_FPGA_TECH_ULTRASCALE_PLUS,
+	ADI_AXI_FPGA_TECH_VERSAL,
 };
 
 enum adi_axi_fpga_family {
@@ -71,6 +72,7 @@ enum adi_axi_fpga_speed_grade {
 	ADI_AXI_FPGA_SPEED_2    = 20,
 	ADI_AXI_FPGA_SPEED_2L   = 21,
 	ADI_AXI_FPGA_SPEED_2LV  = 22,
+	ADI_AXI_FPGA_SPEED_2MP  = 23,
 	ADI_AXI_FPGA_SPEED_3    = 30,
 };
 

---
base-commit: 18023cf0dd64f67c403b85dddaada1e9f8c00482
change-id: 20260326-clk-axi-clk-versal-support-8eaef1530870
--

Thanks!
- Nuno Sá
-- 
Nuno Sá <nuno.sa@analog.com>

