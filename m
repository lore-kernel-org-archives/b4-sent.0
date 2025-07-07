From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 07 Jul 2025 16:17:14 -0500
Subject: [PATCH v6 2/3] cpufreq: dt: Add register helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250707-tegra124-cpufreq-v6-2-fe69c0f9bbab@gmail.com>
References: <20250707-tegra124-cpufreq-v6-0-fe69c0f9bbab@gmail.com>
In-Reply-To: <20250707-tegra124-cpufreq-v6-0-fe69c0f9bbab@gmail.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751923039; l=1698;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=o7BSnjiEeAr40p8PQoKLMNpDwUQoKoaMMFdZbO3EPoY=;
 b=wXWLmy6jc3k4OJng0097xSiNPXWyA0flXotAsiuNhuR+74Ab7gz0CiykHDD4jteSMI7q1Qgcq
 1/bp4h/blJ1Dx96SKgvPmhzQTaeL9Axr4vljJ+lI7S3hfO5xrMFt7Ga
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Cpufreq-dt currently exports no functions. This means that drivers that
are based on cpufreq-dt have no way of establishing a depmod dependency
on it. This helper allows that link.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/cpufreq/cpufreq-dt.c | 11 +++++++++++
 drivers/cpufreq/cpufreq-dt.h |  2 ++
 2 files changed, 13 insertions(+)

diff --git a/drivers/cpufreq/cpufreq-dt.c b/drivers/cpufreq/cpufreq-dt.c
index e80dd982a3e23f6e678d691daba2d8bfda28d93c..506437489b4db241a7a6259274ae84e688772e66 100644
--- a/drivers/cpufreq/cpufreq-dt.c
+++ b/drivers/cpufreq/cpufreq-dt.c
@@ -329,6 +329,17 @@ static struct platform_driver dt_cpufreq_platdrv = {
 };
 module_platform_driver(dt_cpufreq_platdrv);
 
+struct platform_device *cpufreq_dt_pdev_register(struct device *dev)
+{
+	struct platform_device_info cpufreq_dt_devinfo = {};
+
+	cpufreq_dt_devinfo.name = "cpufreq-dt";
+	cpufreq_dt_devinfo.parent = dev;
+
+	return platform_device_register_full(&cpufreq_dt_devinfo);
+}
+EXPORT_SYMBOL_GPL(cpufreq_dt_pdev_register);
+
 MODULE_ALIAS("platform:cpufreq-dt");
 MODULE_AUTHOR("Viresh Kumar <viresh.kumar@linaro.org>");
 MODULE_AUTHOR("Shawn Guo <shawn.guo@linaro.org>");
diff --git a/drivers/cpufreq/cpufreq-dt.h b/drivers/cpufreq/cpufreq-dt.h
index 28c8af7ec5ef3ad0aa94f43ad9129600ca094329..fc1889aeb4f1f15fa7c46c2380021bbf40b62f11 100644
--- a/drivers/cpufreq/cpufreq-dt.h
+++ b/drivers/cpufreq/cpufreq-dt.h
@@ -22,4 +22,6 @@ struct cpufreq_dt_platform_data {
 	int (*resume)(struct cpufreq_policy *policy);
 };
 
+struct platform_device *cpufreq_dt_pdev_register(struct device *dev);
+
 #endif /* __CPUFREQ_DT_H__ */

-- 
2.50.0

