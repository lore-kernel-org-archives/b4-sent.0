From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 03 Sep 2025 14:30:17 -0500
Subject: [PATCH v2 2/4] soc: tegra: fuse: speedo-tegra210: Update speedo
 ids
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250903-tegra210-speedo-v2-2-89e6f86b8942@gmail.com>
References: <20250903-tegra210-speedo-v2-0-89e6f86b8942@gmail.com>
In-Reply-To: <20250903-tegra210-speedo-v2-0-89e6f86b8942@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756927822; l=2732;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=+rnEMK4ZcZWLWnEqy8xfvGYxMDKH6aqGlW/aWu1EMXw=;
 b=Rtw4En8Nol3b3Pqyu9BdJK0rwTTTt5os7DFLrd70wJVDMZn+cLzJ4pMTGtnLG2QIX3EIyXxZX
 OH5UL6xYH9NDsYsEC1n7Yz/o+OUdc3oGJttdKKm2NHAlahOQuhPPMbP
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Existing code only sets cpu and gpu speedo ids 0 and 1. The cpu dvfs
code supports 11 ids and nouveau supports 5. This aligns with what the
downstream vendor kernel supports. Align skus with the downstream list.

The Tegra210 CVB tables were added in the first referenced fixes commit.
Since then, all Tegra210 socs have tried to scale to 1.9 GHz, when the
supported devkits are only supposed to scale to 1.5 or 1.7 GHZ.
Overclocking should not be the default state.

Fixes: 2b2dbc2f94e5 ("clk: tegra: dfll: add CVB tables for Tegra210")
Fixes: 579db6e5d9b8 ("arm64: tegra: Enable DFLL support on Jetson Nano")
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/soc/tegra/fuse/speedo-tegra210.c | 62 ++++++++++++++++++++++----------
 1 file changed, 43 insertions(+), 19 deletions(-)

diff --git a/drivers/soc/tegra/fuse/speedo-tegra210.c b/drivers/soc/tegra/fuse/speedo-tegra210.c
index 695d0b7f9a8abe53c497155603147420cda40b63..60356159e00d2059e55eaacba27b5ca63bf96c90 100644
--- a/drivers/soc/tegra/fuse/speedo-tegra210.c
+++ b/drivers/soc/tegra/fuse/speedo-tegra210.c
@@ -65,27 +65,51 @@ static void __init rev_sku_to_speedo_ids(struct tegra_sku_info *sku_info,
 	sku_info->gpu_speedo_id = 0;
 	*threshold = THRESHOLD_INDEX_0;
 
-	switch (sku) {
-	case 0x00: /* Engineering SKU */
-	case 0x01: /* Engineering SKU */
-	case 0x07:
-	case 0x17:
-	case 0x27:
-		if (speedo_rev >= 2)
+	if (speedo_rev >= 2) {
+		switch (sku) {
+		case 0x00: /* Engineering SKU */
+		case 0x01: /* Engineering SKU */
+		case 0x13:
+			sku_info->cpu_speedo_id = 5;
+			sku_info->gpu_speedo_id = 2;
+			break;
+
+		case 0x07:
+		case 0x17:
+		case 0x1F:
+			sku_info->cpu_speedo_id = 7;
+			sku_info->gpu_speedo_id = 2;
+			break;
+
+		case 0x27:
+			sku_info->cpu_speedo_id = 1;
+			sku_info->gpu_speedo_id = 2;
+			break;
+
+		case 0x83:
+			sku_info->cpu_speedo_id = 3;
+			sku_info->gpu_speedo_id = 3;
+			break;
+
+		case 0x87:
+			sku_info->cpu_speedo_id = 2;
 			sku_info->gpu_speedo_id = 1;
-		break;
-
-	case 0x13:
-		if (speedo_rev >= 2)
-			sku_info->gpu_speedo_id = 1;
-
-		sku_info->cpu_speedo_id = 1;
-		break;
-
-	default:
+			break;
+
+		case 0x8F:
+			sku_info->cpu_speedo_id = 9;
+			sku_info->gpu_speedo_id = 2;
+			break;
+
+		default:
+			pr_err("Tegra210: unknown revision 2 or newer SKU %#04x\n", sku);
+			/* Using the default for the error case */
+			break;
+		}
+	} else if (sku == 0x00 || sku == 0x01 || sku == 0x07 || sku == 0x13 || sku == 0x17) {
+		sku_info->gpu_speedo_id = 1;
+	} else {
 		pr_err("Tegra210: unknown SKU %#04x\n", sku);
-		/* Using the default for the error case */
-		break;
 	}
 }
 

-- 
2.50.1

