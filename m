From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 28 Aug 2025 21:48:13 -0500
Subject: [PATCH v3 2/2] cpufreq: tegra186: Initialize all cores to max
 frequencies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250828-tegra186-cpufreq-fixes-v3-2-23a7341db254@gmail.com>
References: <20250828-tegra186-cpufreq-fixes-v3-0-23a7341db254@gmail.com>
In-Reply-To: <20250828-tegra186-cpufreq-fixes-v3-0-23a7341db254@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756435694; l=3164;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=Cee7AliwERvbB7wKaI7YwL2ggH/0vhQ+XE9hO86NkEY=;
 b=HeiRL5v18eMEMdGOnHaqyKruV+NWZaMq9DEOZL+rad/fbdGREpgpd56SZYuM31CexSZoLwlAb
 64G6dPnq1uzDAMXzNyNyD8K5JXE46E3JMQvSLBUolq1UMEmuURTmdOE
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
 drivers/cpufreq/tegra186-cpufreq.c | 27 +++++++++++++++++++++------
 1 file changed, 21 insertions(+), 6 deletions(-)

diff --git a/drivers/cpufreq/tegra186-cpufreq.c b/drivers/cpufreq/tegra186-cpufreq.c
index 6c394b429b6182faffabf222e5af501393dbbba9..bd94beebc4cc2fe6870e13ca55343cedb9729e99 100644
--- a/drivers/cpufreq/tegra186-cpufreq.c
+++ b/drivers/cpufreq/tegra186-cpufreq.c
@@ -138,13 +138,14 @@ static struct cpufreq_driver tegra186_cpufreq_driver = {
 
 static struct cpufreq_frequency_table *init_vhint_table(
 	struct platform_device *pdev, struct tegra_bpmp *bpmp,
-	struct tegra186_cpufreq_cluster *cluster, unsigned int cluster_id)
+	struct tegra186_cpufreq_cluster *cluster, unsigned int cluster_id,
+	int *num_rates)
 {
 	struct cpufreq_frequency_table *table;
 	struct mrq_cpu_vhint_request req;
 	struct tegra_bpmp_message msg;
 	struct cpu_vhint_data *data;
-	int err, i, j, num_rates = 0;
+	int err, i, j;
 	dma_addr_t phys;
 	void *virt;
 
@@ -174,6 +175,7 @@ static struct cpufreq_frequency_table *init_vhint_table(
 		goto free;
 	}
 
+	*num_rates = 0;
 	for (i = data->vfloor; i <= data->vceil; i++) {
 		u16 ndiv = data->ndiv[i];
 
@@ -184,10 +186,10 @@ static struct cpufreq_frequency_table *init_vhint_table(
 		if (i > 0 && ndiv == data->ndiv[i - 1])
 			continue;
 
-		num_rates++;
+		(*num_rates)++;
 	}
 
-	table = devm_kcalloc(&pdev->dev, num_rates + 1, sizeof(*table),
+	table = devm_kcalloc(&pdev->dev, *num_rates + 1, sizeof(*table),
 			     GFP_KERNEL);
 	if (!table) {
 		table = ERR_PTR(-ENOMEM);
@@ -229,7 +231,9 @@ static int tegra186_cpufreq_probe(struct platform_device *pdev)
 {
 	struct tegra186_cpufreq_data *data;
 	struct tegra_bpmp *bpmp;
-	unsigned int i = 0, err;
+	unsigned int i = 0, err, edvd_offset;
+	int num_rates = 0;
+	u32 edvd_val, cpu;
 
 	data = devm_kzalloc(&pdev->dev,
 			    struct_size(data, clusters, TEGRA186_NUM_CLUSTERS),
@@ -252,10 +256,21 @@ static int tegra186_cpufreq_probe(struct platform_device *pdev)
 	for (i = 0; i < TEGRA186_NUM_CLUSTERS; i++) {
 		struct tegra186_cpufreq_cluster *cluster = &data->clusters[i];
 
-		cluster->table = init_vhint_table(pdev, bpmp, cluster, i);
+		cluster->table = init_vhint_table(pdev, bpmp, cluster, i, &num_rates);
 		if (IS_ERR(cluster->table)) {
 			err = PTR_ERR(cluster->table);
 			goto put_bpmp;
+		} else if (!num_rates) {
+			err = -EINVAL;
+			goto put_bpmp;
+		}
+
+		for (cpu = 0; cpu < ARRAY_SIZE(tegra186_cpus); cpu++) {
+			if (data->cpus[cpu].bpmp_cluster_id == i) {
+				edvd_val = cluster->table[num_rates - 1].driver_data;
+				edvd_offset = data->cpus[cpu].edvd_offset;
+				writel(edvd_val, data->regs + edvd_offset);
+			}
 		}
 	}
 

-- 
2.50.1

