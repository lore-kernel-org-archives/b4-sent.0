From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 25 Aug 2025 00:03:07 -0500
Subject: [PATCH] cpufreq: tegra186: Default divider to 35 if register read
 fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250825-tegra186-cpufreq-ndiv-v1-1-4669bf8f2992@gmail.com>
X-B4-Tracking: v=1; b=H4sIAIruq2gC/x3MQQqEMAxA0atI1hOwoWqdqwwuao2aTXVSFUG8u
 8XlW/x/QWIVTvAtLlA+JMkSM8yngDD7ODHKkA1UUlU6srjxpN64GsO6j8p/jIMc2Ie28UTOWN9
 CblflUc73++vu+wGbzNXbZwAAAA==
X-Change-ID: 20250824-tegra186-cpufreq-ndiv-bc97a22814a9
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-pm@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756098191; l=1487;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=rfEcX8ls2L9Ghv6edI8v1CbFCLor3x2WRkwzlxZtph0=;
 b=Ut5weYR7xRwt2M+dlkUv1X8ffkKCHS5+SOthr91vOYmx3+lpcgnUN2WPB3d+b1HVn5TlJnnqE
 Y95qQ6uDk/uAb7Qt2A03opxPaUffsn0mbPZuC6O9sd+AU//d46EdphX
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Several of the cores fail to read any registers and thus fail to
initialize cpufreq. With shared policies, this only affects the Denver
cluster, but one of the A57 cores also exhibits this behaviour. If the
value is initialized to match what is read by the downstream vendor
kernel, scaling works as expected. I have never seen this value be
anything other than 35, so it should be a relatively safe assumption.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/cpufreq/tegra186-cpufreq.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/cpufreq/tegra186-cpufreq.c b/drivers/cpufreq/tegra186-cpufreq.c
index cbabb726c6645d2e5f1857a47e5643c8552d1933..f017f903c6843f1881e8311753f6269637c6bc69 100644
--- a/drivers/cpufreq/tegra186-cpufreq.c
+++ b/drivers/cpufreq/tegra186-cpufreq.c
@@ -115,6 +115,11 @@ static unsigned int tegra186_cpufreq_get(unsigned int cpu)
 
 	edvd_offset = data->cpus[policy->cpu].edvd_offset;
 	ndiv = readl(data->regs + edvd_offset) & EDVD_CORE_VOLT_FREQ_F_MASK;
+	if (ndiv == 0) {
+		dev_warn_once(get_cpu_device(policy->cpu),
+			 "Scaling registers invalid, using expected values");
+		ndiv = 35;
+	}
 	cluster_id = data->cpus[policy->cpu].bpmp_cluster_id;
 	cluster = &data->clusters[cluster_id];
 	cpufreq_cpu_put(policy);

---
base-commit: 1b237f190eb3d36f52dffe07a40b5eb210280e00
change-id: 20250824-tegra186-cpufreq-ndiv-bc97a22814a9

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

