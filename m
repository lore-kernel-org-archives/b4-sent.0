From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 26 Aug 2025 15:15:59 -0500
Subject: [PATCH 1/2] cpufreq: tegra186: Set target frequency for all cpus
 in policy
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250826-tegra186-cpufreq-fixes-v1-1-97f98d3e0adb@gmail.com>
References: <20250826-tegra186-cpufreq-fixes-v1-0-97f98d3e0adb@gmail.com>
In-Reply-To: <20250826-tegra186-cpufreq-fixes-v1-0-97f98d3e0adb@gmail.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Aaron Kling <luceoscutum@gmail.com>, 
 Sumit Gupta <sumitg@nvidia.com>
Cc: Thierry Reding <treding@nvidia.com>, linux-pm@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756239382; l=1316;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=WE4FtNYlrqayHn8j1oFAZqsXZWGEdS20pQxJDsMXhig=;
 b=smWWYy/Dw/cQATAk4Z2y1dcYGsWu36PsKoRmK9tyjhXEskFAgD6sXXMNfYn9K9FzflP/aqSj9
 3DihDaoNiFABrTnV76BoTO4+WgS5u7RvZzPAdYn4JKMTrVNJbQxivd3
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The original commit set all cores in a cluster to a shared policy, but
did not update set_target to apply a frequency change to all cores for
the policy. This caused most cores to remain stuck at their boot
frequency.

Fixes: be4ae8c19492 ("cpufreq: tegra186: Share policy per cluster")
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/cpufreq/tegra186-cpufreq.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/drivers/cpufreq/tegra186-cpufreq.c b/drivers/cpufreq/tegra186-cpufreq.c
index cbabb726c6645d2e5f1857a47e5643c8552d1933..6c394b429b6182faffabf222e5af501393dbbba9 100644
--- a/drivers/cpufreq/tegra186-cpufreq.c
+++ b/drivers/cpufreq/tegra186-cpufreq.c
@@ -93,10 +93,14 @@ static int tegra186_cpufreq_set_target(struct cpufreq_policy *policy,
 {
 	struct tegra186_cpufreq_data *data = cpufreq_get_driver_data();
 	struct cpufreq_frequency_table *tbl = policy->freq_table + index;
-	unsigned int edvd_offset = data->cpus[policy->cpu].edvd_offset;
+	unsigned int edvd_offset;
 	u32 edvd_val = tbl->driver_data;
+	u32 cpu;
 
-	writel(edvd_val, data->regs + edvd_offset);
+	for_each_cpu(cpu, policy->cpus) {
+		edvd_offset = data->cpus[cpu].edvd_offset;
+		writel(edvd_val, data->regs + edvd_offset);
+	}
 
 	return 0;
 }

-- 
2.50.1

