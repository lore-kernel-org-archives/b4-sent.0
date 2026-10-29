From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Thu, 29 Oct 2026 10:33:00 +0100
Subject: [PATCH 2/3] soc/tegra: fuse: Store Tegra114 CPU and SoC speedo
 values
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-upstream-speedo-t114-v1-2-81457cc9d94c@tsv-stahl-riesa.de>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793266385; l=1694;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=+yKNYi2IHZusPUhtNKXAX1JpKETKpwUXNfPwjmWY+ag=;
 b=4JvZFiQpSbPsGARZvmxmSLZr+iMyy10+lb4zMf6EirZcluFDTS4zduw3frxa/Auj8QFJ1IhWQ
 QgQfcVAuxW8BWyH+olu/97RA9azIN1bbXEmxe+gPJd22OkQbWQ3nkfk
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Tegra114 CPU DFLL computes its OPP voltages from the CVB tables
added in commit 5aba939e80f4 ("clk: tegra: dfll: Add CVB tables for
Tegra114"), using tegra_sku_info.cpu_speedo_value. The Tegra114 speedo
code computes this value but never stores it, so the DFLL uses speedo
0 and only the c0 coefficient remains. For CPU speedo IDs 1 to 3 c0 is
2190643 to 3395401, so "mv * 1000" in round_cvb_voltage() overflows and
the OPP voltages are wrong.

This is currently hidden by a zero voltage step with Palmas regulators,
fixed in the next patch. With both fixes the CPU OPPs range from 1000 mV
to 1270 mV on a device with CPU speedo 1742, which matches the vendor
kernel.

Store the SoC speedo value as well, as Tegra124 and Tegra210 do.

Fixes: 5aba939e80f4 ("clk: tegra: dfll: Add CVB tables for Tegra114")
Cc: stable@vger.kernel.org
Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 drivers/soc/tegra/fuse/speedo-tegra114.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/soc/tegra/fuse/speedo-tegra114.c b/drivers/soc/tegra/fuse/speedo-tegra114.c
index 1e6c2b5be759..8bf1a1b1287a 100644
--- a/drivers/soc/tegra/fuse/speedo-tegra114.c
+++ b/drivers/soc/tegra/fuse/speedo-tegra114.c
@@ -92,6 +92,9 @@ void __init tegra114_init_speedo_data(struct tegra_sku_info *sku_info)
 	cpu_speedo_val = tegra_fuse_read_early(FUSE_CPU_SPEEDO_1) + 1024;
 	soc_speedo_val = tegra_fuse_read_early(FUSE_SOC_SPEEDO_0);
 
+	sku_info->cpu_speedo_value = cpu_speedo_val;
+	sku_info->soc_speedo_value = soc_speedo_val;
+
 	for (i = 0; i < CPU_PROCESS_CORNERS; i++)
 		if (cpu_speedo_val < cpu_process_speedos[threshold][i])
 			break;

-- 
2.56.0

