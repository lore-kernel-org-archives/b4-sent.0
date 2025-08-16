From: Aaron Kling <webgeek1234@gmail.com>
Date: Sat, 16 Aug 2025 00:53:34 -0500
Subject: [PATCH 2/5] soc: tegra: fuse: speedo-tegra210: Update speedo ids
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250816-tegra210-speedo-v1-2-a981360adc27@gmail.com>
References: <20250816-tegra210-speedo-v1-0-a981360adc27@gmail.com>
In-Reply-To: <20250816-tegra210-speedo-v1-0-a981360adc27@gmail.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Joseph Lo <josephl@nvidia.com>, 
 Peter De Schrijver <pdeschrijver@nvidia.com>, 
 Prashant Gaikwad <pgaikwad@nvidia.com>
Cc: linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Thierry Reding <treding@nvidia.com>, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755323658; l=1990;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=FEiuagoxyTly3FkCZVL5wqa+8cOCwUCmjC0lzQx+w7w=;
 b=He3TG2PtmZCXHlF7vNxNDd4ritkc368+eli+M7ceaJvNhMkyryYHofbSbs/lLbu3e6VEcTFhK
 oOx+R0gWx8rAbvXyanPZldRElXAfN3VzN2fgFJ7pM4L+rqPGe21N4Tw
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Existing code only sets cpu and gpu speedo ids 0 and 1. The cpu dvfs
code supports 11 ids and nouveau supports 5. This aligns with what the
downstream vendor kernel supports. Align the existing supported skus
with the downstream speedo list.

The Tegra210 CVB tables were added in the referenced fixes commit. Since
then, all Tegra210 socs have tried to scale to 1.9 GHz, when the
supported devkits are only supposed to scale to 1.5 or 1.7 GHZ.
Overclocking should not be the default state.

Fixes: 2b2dbc2f94e5 ("clk: tegra: dfll: add CVB tables for Tegra210")
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/soc/tegra/fuse/speedo-tegra210.c | 31 ++++++++++++++++++++++++-------
 1 file changed, 24 insertions(+), 7 deletions(-)

diff --git a/drivers/soc/tegra/fuse/speedo-tegra210.c b/drivers/soc/tegra/fuse/speedo-tegra210.c
index 695d0b7f9a8abe53c497155603147420cda40b63..909fdf8fcc9d9f5ac936ae322e7a73dc720e5ab6 100644
--- a/drivers/soc/tegra/fuse/speedo-tegra210.c
+++ b/drivers/soc/tegra/fuse/speedo-tegra210.c
@@ -68,18 +68,35 @@ static void __init rev_sku_to_speedo_ids(struct tegra_sku_info *sku_info,
 	switch (sku) {
 	case 0x00: /* Engineering SKU */
 	case 0x01: /* Engineering SKU */
+	case 0x13:
+		if (speedo_rev >= 2) {
+			sku_info->cpu_speedo_id = 5;
+			sku_info->gpu_speedo_id = 2;
+			break;
+		}
+
+		sku_info->gpu_speedo_id = 1;
+		break;
+
 	case 0x07:
 	case 0x17:
-	case 0x27:
-		if (speedo_rev >= 2)
-			sku_info->gpu_speedo_id = 1;
+		if (speedo_rev >= 2) {
+			sku_info->cpu_speedo_id = 7;
+			sku_info->gpu_speedo_id = 2;
+			break;
+		}
+
+		sku_info->gpu_speedo_id = 1;
 		break;
 
-	case 0x13:
-		if (speedo_rev >= 2)
-			sku_info->gpu_speedo_id = 1;
+	case 0x27:
+		if (speedo_rev >= 2) {
+			sku_info->cpu_speedo_id = 1;
+			sku_info->gpu_speedo_id = 2;
+			break;
+		}
 
-		sku_info->cpu_speedo_id = 1;
+		sku_info->gpu_speedo_id = 1;
 		break;
 
 	default:

-- 
2.50.1

