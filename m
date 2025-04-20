From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 20 Apr 2025 15:42:01 -0500
Subject: [PATCH 2/2] cpufreq: tegra124: Allow building as a module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250420-tegra124-cpufreq-v1-2-0a47fe126091@gmail.com>
References: <20250420-tegra124-cpufreq-v1-0-0a47fe126091@gmail.com>
In-Reply-To: <20250420-tegra124-cpufreq-v1-0-0a47fe126091@gmail.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745181742; l=1514;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=0/eJfta3Jq8byw+cbZkUJpmlw+R9HxZHBrK4OMYoxUc=;
 b=qNOJNyVuP9vd2vGD9n/kQuoAS9n/8fozqCUnEWanuZg7SnezDq4JliALrYslAXzV60rD9pmc0
 I1AJrESATxZCNef5ZKrtk5f894BXev2RHNdv2LblfwBqYnJp/1xD965
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This requires a soft dependency on cpufreq-dt as this driver only
handles power management and cpufreq-dt does the real operations. Other
than that, this works fine as a module, so allow building as such.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/cpufreq/Kconfig.arm        | 2 +-
 drivers/cpufreq/tegra124-cpufreq.c | 2 ++
 2 files changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/cpufreq/Kconfig.arm b/drivers/cpufreq/Kconfig.arm
index 4f9cb943d945c244eb2b29f543d14df6cac4e5d4..625f6fbdaaf5fd774e3b0bb996eb7ce980da41ee 100644
--- a/drivers/cpufreq/Kconfig.arm
+++ b/drivers/cpufreq/Kconfig.arm
@@ -238,7 +238,7 @@ config ARM_TEGRA20_CPUFREQ
 	  This adds the CPUFreq driver support for Tegra20/30 SOCs.
 
 config ARM_TEGRA124_CPUFREQ
-	bool "Tegra124 CPUFreq support"
+	tristate "Tegra124 CPUFreq support"
 	depends on ARCH_TEGRA || COMPILE_TEST
 	depends on CPUFREQ_DT
 	default y
diff --git a/drivers/cpufreq/tegra124-cpufreq.c b/drivers/cpufreq/tegra124-cpufreq.c
index 514146d98bca2d8aa59980a14dff3487cd8045f6..9e46b53487fafdc1e9e95e765b9b490d9c95f2c6 100644
--- a/drivers/cpufreq/tegra124-cpufreq.c
+++ b/drivers/cpufreq/tegra124-cpufreq.c
@@ -211,5 +211,7 @@ static int __init tegra_cpufreq_init(void)
 }
 module_init(tegra_cpufreq_init);
 
+MODULE_SOFTDEP("pre: cpufreq-dt");
 MODULE_AUTHOR("Tuomas Tynkkynen <ttynkkynen@nvidia.com>");
 MODULE_DESCRIPTION("cpufreq driver for NVIDIA Tegra124");
+MODULE_LICENSE("GPL");

-- 
2.48.1

