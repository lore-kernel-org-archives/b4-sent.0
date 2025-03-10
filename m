From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 10 Mar 2025 00:28:48 -0500
Subject: [PATCH v2] cpufreq: tegra186: Share policy per cluster
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250310-cpufreq-t186-share-policy-v2-1-d0b743cd051f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAI94zmcC/0XMTQ7CIBBA4as0rJ2GGQTRlfcwLhCnLbEtFepfm
 t5d4sblt3hvEZlT4CwO1SISP0MOcSygTSV858aWIVyLBUnSUqEEPz2axHeY0RrInUsMU+yD/4C
 jndFkldWKROmnxE14/96nc3GT4gBzl9j9j4QGjbTS1GqP2hhAePGlZb4hqe2xHVzoax8Hsa5fr
 JkUUqsAAAA=
X-Change-ID: 20250310-cpufreq-t186-share-policy-a27652838532
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-pm@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <luceoscutum@gmail.com>, 
 Sumit Gupta <sumitg@nvidia.com>, Thierry Reding <treding@nvidia.com>, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741584529; l=1424;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=/U0Kh7Cb90mT2b4NourHWsyj9SF5IW5h30D3gxH4nRw=;
 b=PCFAeC5Bm9uq1dNxo+stUss63q42Esm2EXmtWsfRFbcc7mCaEnG69ijd77iec6/SSgX0SLsY2
 7c7GqheMqsXCAi4IEEqCtMGlQOdU0Y8jYktpuRf1ba8fqUhWhflzU0x
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Aaron Kling <luceoscutum@gmail.com>

This functionally brings tegra186 in line with tegra210 and tegra194,
sharing a cpufreq policy between all cores in a cluster.

Reviewed-by: Sumit Gupta <sumitg@nvidia.com>
Acked-by: Thierry Reding <treding@nvidia.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/cpufreq/tegra186-cpufreq.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/cpufreq/tegra186-cpufreq.c b/drivers/cpufreq/tegra186-cpufreq.c
index c7761eb99f3ccc3e85389cb1e79d338c47584ae3..92aa50f0166601e7b077a4127eba0cb60181dee3 100644
--- a/drivers/cpufreq/tegra186-cpufreq.c
+++ b/drivers/cpufreq/tegra186-cpufreq.c
@@ -73,11 +73,18 @@ static int tegra186_cpufreq_init(struct cpufreq_policy *policy)
 {
 	struct tegra186_cpufreq_data *data = cpufreq_get_driver_data();
 	unsigned int cluster = data->cpus[policy->cpu].bpmp_cluster_id;
+	u32 cpu;
 
 	policy->freq_table = data->clusters[cluster].table;
 	policy->cpuinfo.transition_latency = 300 * 1000;
 	policy->driver_data = NULL;
 
+	/* set same policy for all cpus in a cluster */
+	for (cpu = 0; cpu < ARRAY_SIZE(tegra186_cpus); cpu++) {
+		if (data->cpus[cpu].bpmp_cluster_id == cluster)
+			cpumask_set_cpu(cpu, policy->cpus);
+	}
+
 	return 0;
 }
 

---
base-commit: 1110ce6a1e34fe1fdc1bfe4ad52405f327d5083b
change-id: 20250310-cpufreq-t186-share-policy-a27652838532

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

