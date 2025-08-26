From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 26 Aug 2025 15:16:00 -0500
Subject: [PATCH 2/2] cpufreq: tegra186: Initialize all cores to base
 frequencies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250826-tegra186-cpufreq-fixes-v1-2-97f98d3e0adb@gmail.com>
References: <20250826-tegra186-cpufreq-fixes-v1-0-97f98d3e0adb@gmail.com>
In-Reply-To: <20250826-tegra186-cpufreq-fixes-v1-0-97f98d3e0adb@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756239382; l=1607;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=9bUHeyaYYD5fuQRhqyZoy/YoCxZst0rIRpuE3PyDvxs=;
 b=Zu2irhRctxFYy8ShV3iS/NGGP7/GCtf5cIRe2O/vva1S8TPz5Mtf7QMi+4k9PQMx4+NC44Htj
 iBUqMvyf3/KBGshN+/S06gfLre71hS+9D7kdJZnQidiJcID01Pj5nzs
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

During initialization, the EDVD_COREx_VOLT_FREQ registers for some cores
are still at reset values and not reflecting the actual frequency. This
causes get calls to fail. Set all cores to their respective base
frequency during probe to initialize the registers to working values.

Suggested-by: Mikko Perttunen <mperttunen@nvidia.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/cpufreq/tegra186-cpufreq.c | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/drivers/cpufreq/tegra186-cpufreq.c b/drivers/cpufreq/tegra186-cpufreq.c
index 6c394b429b6182faffabf222e5af501393dbbba9..ef288705f00b0918d0f8963ef9cc9fc53be88091 100644
--- a/drivers/cpufreq/tegra186-cpufreq.c
+++ b/drivers/cpufreq/tegra186-cpufreq.c
@@ -229,7 +229,8 @@ static int tegra186_cpufreq_probe(struct platform_device *pdev)
 {
 	struct tegra186_cpufreq_data *data;
 	struct tegra_bpmp *bpmp;
-	unsigned int i = 0, err;
+	unsigned int i = 0, err, edvd_offset;
+	u32 edvd_val, cpu;
 
 	data = devm_kzalloc(&pdev->dev,
 			    struct_size(data, clusters, TEGRA186_NUM_CLUSTERS),
@@ -257,6 +258,14 @@ static int tegra186_cpufreq_probe(struct platform_device *pdev)
 			err = PTR_ERR(cluster->table);
 			goto put_bpmp;
 		}
+
+		for (cpu = 0; cpu < ARRAY_SIZE(tegra186_cpus); cpu++) {
+			if (data->cpus[cpu].bpmp_cluster_id == i) {
+				edvd_val = cluster->table[0].driver_data;
+				edvd_offset = data->cpus[cpu].edvd_offset;
+				writel(edvd_val, data->regs + edvd_offset);
+			}
+		}
 	}
 
 	tegra186_cpufreq_driver.driver_data = data;

-- 
2.50.1

