From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Thu, 29 Oct 2026 10:32:59 +0100
Subject: [PATCH 1/3] soc/tegra: fuse: Fix Tegra114 speedo fuse offsets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-upstream-speedo-t114-v1-1-81457cc9d94c@tsv-stahl-riesa.de>
References: <20261029-upstream-speedo-t114-v1-0-81457cc9d94c@tsv-stahl-riesa.de>
In-Reply-To: <20261029-upstream-speedo-t114-v1-0-81457cc9d94c@tsv-stahl-riesa.de>
To: Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Mikko Perttunen <mperttunen@nvidia.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, 
 Prashant Gaikwad <pgaikwad@nvidia.com>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, linux-clk@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793266385; l=2745;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=4FiENUbMBaJsOEfAoSxwyoXv1XTgnVLUka3Tp+CNcmo=;
 b=1WDlGcfOvl96hHV72Uyr/1zpplR+EIC9+zmE0u9BsU6eLijGhWHzehlsSz5o1X9ncU1SbP6en
 EVSuILFkuQhBNXy5oI9Nlo+Pch3KOYUOtUbnULFYtNoogZWf0SEzFNI
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tegra_fuse_read_early() takes offsets relative to the start of the fuse
words at FUSE_BEGIN (0x100). When the fuse driver moved out of
mach-tegra, the Tegra30 speedo code was converted to such offsets
(FUSE_SPEEDO_CALIB_0 0x114 became 0x14), and the Tegra124 code uses
them as well. The Tegra114 code kept the absolute offsets from the
vendor kernel, so since then it reads the CPU and SoC speedo values and
the A01 CPU2/3 fuses 0x100 bytes too far.

On a Tegra Note 7 (Tegra114 A02, SKU 5) the fuses at the correct
offsets 0x2c and 0x34 read 718 and 1156. That gives CPU speedo 1742 and
SoC speedo 1156, which is exactly what the vendor kernel prints for this
device. The current code reads 172094 and 0, and so reports SoC process
0 instead of 1.

Today only the reported process IDs depend on these values, since the
Tegra114 core OPPs are selected by the SoC speedo ID and the CPU DVFS
tables apply to all process IDs. The CPU speedo value is needed,
however, to compute correct CPU DFLL voltages, which the next patch
fixes.

Fixes: 783c8f4c8445 ("soc/tegra: Add efuse driver for Tegra")
Cc: stable@vger.kernel.org
Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 drivers/soc/tegra/fuse/speedo-tegra114.c | 13 +++++++++----
 1 file changed, 9 insertions(+), 4 deletions(-)

diff --git a/drivers/soc/tegra/fuse/speedo-tegra114.c b/drivers/soc/tegra/fuse/speedo-tegra114.c
index 6695702bdb4c..1e6c2b5be759 100644
--- a/drivers/soc/tegra/fuse/speedo-tegra114.c
+++ b/drivers/soc/tegra/fuse/speedo-tegra114.c
@@ -14,6 +14,11 @@
 #define SOC_PROCESS_CORNERS	2
 #define CPU_PROCESS_CORNERS	2
 
+#define FUSE_CPU_SPEEDO_1	0x2c
+#define FUSE_SOC_SPEEDO_0	0x34
+#define FUSE_OPT_CPU23_DISABLE	0x16c
+#define FUSE_OPT_CPU23_REENABLE	0x170
+
 enum {
 	THRESHOLD_INDEX_0,
 	THRESHOLD_INDEX_1,
@@ -63,8 +68,8 @@ static void __init rev_sku_to_speedo_ids(struct tegra_sku_info *sku_info,
 	}
 
 	if (rev == TEGRA_REVISION_A01) {
-		tmp = tegra_fuse_read_early(0x270) << 1;
-		tmp |= tegra_fuse_read_early(0x26c);
+		tmp = tegra_fuse_read_early(FUSE_OPT_CPU23_REENABLE) << 1;
+		tmp |= tegra_fuse_read_early(FUSE_OPT_CPU23_DISABLE);
 		if (!tmp)
 			sku_info->cpu_speedo_id = 0;
 	}
@@ -84,8 +89,8 @@ void __init tegra114_init_speedo_data(struct tegra_sku_info *sku_info)
 
 	rev_sku_to_speedo_ids(sku_info, &threshold);
 
-	cpu_speedo_val = tegra_fuse_read_early(0x12c) + 1024;
-	soc_speedo_val = tegra_fuse_read_early(0x134);
+	cpu_speedo_val = tegra_fuse_read_early(FUSE_CPU_SPEEDO_1) + 1024;
+	soc_speedo_val = tegra_fuse_read_early(FUSE_SOC_SPEEDO_0);
 
 	for (i = 0; i < CPU_PROCESS_CORNERS; i++)
 		if (cpu_speedo_val < cpu_process_speedos[threshold][i])

-- 
2.56.0

