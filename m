From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 28 Aug 2025 11:57:21 -0500
Subject: [PATCH v2 2/2] cpufreq: tegra186: Initialize all cores to max
 frequencies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250828-tegra186-cpufreq-fixes-v2-2-fcffe4de1e15@gmail.com>
References: <20250828-tegra186-cpufreq-fixes-v2-0-fcffe4de1e15@gmail.com>
In-Reply-To: <20250828-tegra186-cpufreq-fixes-v2-0-fcffe4de1e15@gmail.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Aaron Kling <luceoscutum@gmail.com>, 
 Sumit Gupta <sumitg@nvidia.com>
Cc: Thierry Reding <treding@nvidia.com>, linux-pm@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>, 
 Mikko Perttunen <mperttunen@nvidia.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756400245; l=2602;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=6Wg/olsymhL3iTHVB65L4Tbz1bDTYeRv7QGuafdu3Ts=;
 b=cq59RVWvKCRsrVWPAoipifGivNEQpYMiPpNPJwrGMvU6ees48p4XzTffroZGdxWFZ0wcMrpcf
 K44ysojMCmuDXNrptjVXxKpI1NnZs9dtspMu+0VxTAAHVwdAmETTsay
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

During initialization, the EDVD_COREx_VOLT_FREQ registers for some cores
are still at reset values and not reflecting the actual frequency. This
causes get calls to fail. Set all cores to their respective max
frequency during probe to initialize the registers to working values.

Suggested-by: Mikko Perttunen <mperttunen@nvidia.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/cpufreq/tegra186-cpufreq.c | 18 +++++++++++++++---
 1 file changed, 15 insertions(+), 3 deletions(-)

diff --git a/drivers/cpufreq/tegra186-cpufreq.c b/drivers/cpufreq/tegra186-cpufreq.c
index 6c394b429b6182faffabf222e5af501393dbbba9..3cd42db955c1c705f9774879e34b71ae124e86d2 100644
--- a/drivers/cpufreq/tegra186-cpufreq.c
+++ b/drivers/cpufreq/tegra186-cpufreq.c
@@ -138,7 +138,8 @@ static struct cpufreq_driver tegra186_cpufreq_driver = {
 
 static struct cpufreq_frequency_table *init_vhint_table(
 	struct platform_device *pdev, struct tegra_bpmp *bpmp,
-	struct tegra186_cpufreq_cluster *cluster, unsigned int cluster_id)
+	struct tegra186_cpufreq_cluster *cluster, unsigned int cluster_id,
+	int *max_rate)
 {
 	struct cpufreq_frequency_table *table;
 	struct mrq_cpu_vhint_request req;
@@ -218,6 +219,7 @@ static struct cpufreq_frequency_table *init_vhint_table(
 	}
 
 	table[j].frequency = CPUFREQ_TABLE_END;
+	*max_rate = num_rates - 1;
 
 free:
 	dma_free_coherent(bpmp->dev, sizeof(*data), virt, phys);
@@ -229,7 +231,9 @@ static int tegra186_cpufreq_probe(struct platform_device *pdev)
 {
 	struct tegra186_cpufreq_data *data;
 	struct tegra_bpmp *bpmp;
-	unsigned int i = 0, err;
+	unsigned int i = 0, err, edvd_offset;
+	int max_rate = 0;
+	u32 edvd_val, cpu;
 
 	data = devm_kzalloc(&pdev->dev,
 			    struct_size(data, clusters, TEGRA186_NUM_CLUSTERS),
@@ -252,11 +256,19 @@ static int tegra186_cpufreq_probe(struct platform_device *pdev)
 	for (i = 0; i < TEGRA186_NUM_CLUSTERS; i++) {
 		struct tegra186_cpufreq_cluster *cluster = &data->clusters[i];
 
-		cluster->table = init_vhint_table(pdev, bpmp, cluster, i);
+		cluster->table = init_vhint_table(pdev, bpmp, cluster, i, &max_rate);
 		if (IS_ERR(cluster->table)) {
 			err = PTR_ERR(cluster->table);
 			goto put_bpmp;
 		}
+
+		for (cpu = 0; cpu < ARRAY_SIZE(tegra186_cpus); cpu++) {
+			if (data->cpus[cpu].bpmp_cluster_id == i) {
+				edvd_val = cluster->table[max_rate].driver_data;
+				edvd_offset = data->cpus[cpu].edvd_offset;
+				writel(edvd_val, data->regs + edvd_offset);
+			}
+		}
 	}
 
 	tegra186_cpufreq_driver.driver_data = data;

-- 
2.50.1

