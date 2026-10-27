From: Jian Hu <jian.hu@amlogic.com>
Date: Tue, 27 Oct 2026 16:43:39 +0800
Subject: [PATCH] soc: amlogic: clk-measure: Fix AXG HIFI PLL name
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-fix_axg-v1-1-741388f1e851@amlogic.com>
X-B4-Tracking: v=1; b=H4sIADpk4GoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAyNz3bTMivjEinRdy0RDIyOzlBSTNMMUJaDqgqJUoBTYpOjY2loAfPi
 LY1kAAAA=
X-Change-ID: 20261027-fix_axg-9a1226dd4f1d
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jian Hu <jian.hu@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793090628; l=1118;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=wHBJmRVPOh0SOfv0q4EbK9DeqGUv8x9se7z6Xr31Dm0=;
 b=V8lYaYyG4Nu3SIhK5LElEYnwNp/ff94wpX+2hnl69vnHiMjifymPuy/FBED9Q9X9X/PeG22Pt
 GbA3wgEfVW0BSejd/avhTZ++DXq4bng3liJENmCbXDNtGGs4SornlnR
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

AXG does not have a GP1 PLL. Clock measurement ID 5 corresponds
to the HIFI PLL, but it is incorrectly named "gp1_pll".

Rename it to "hifi_pll" to match the actual hardware.

Fixes: 19e0bde7bf6a ("soc: amlogic: clk-measure: add axg and g12a support")
Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
 drivers/soc/amlogic/meson-clk-measure.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/soc/amlogic/meson-clk-measure.c b/drivers/soc/amlogic/meson-clk-measure.c
index 33767f0bc67c..c1ffa2537464 100644
--- a/drivers/soc/amlogic/meson-clk-measure.c
+++ b/drivers/soc/amlogic/meson-clk-measure.c
@@ -182,7 +182,7 @@ static const struct meson_msr_id clk_msr_axg[] = {
 	CLK_MSR_ID(2, "ring_osc_out_ee_2"),
 	CLK_MSR_ID(3, "a53_ring_osc"),
 	CLK_MSR_ID(4, "gp0_pll"),
-	CLK_MSR_ID(5, "gp1_pll"),
+	CLK_MSR_ID(5, "hifi_pll"),
 	CLK_MSR_ID(7, "clk81"),
 	CLK_MSR_ID(9, "encl"),
 	CLK_MSR_ID(17, "sys_pll_div16"),

---
base-commit: a848d72aab71e19ea78180f2502ad7d12818723f
change-id: 20261027-fix_axg-9a1226dd4f1d

Best regards,
-- 
Jian Hu <jian.hu@amlogic.com>

