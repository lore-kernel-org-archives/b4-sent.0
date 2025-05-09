From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 08 May 2025 19:04:14 -0500
Subject: [PATCH v4 1/2] cpufreq: tegra124: Remove use of disable_cpufreq
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250508-tegra124-cpufreq-v4-1-d142bcbd0234@gmail.com>
References: <20250508-tegra124-cpufreq-v4-0-d142bcbd0234@gmail.com>
In-Reply-To: <20250508-tegra124-cpufreq-v4-0-d142bcbd0234@gmail.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746749056; l=865;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=tiIp2lJcL5RDKC6iOuLruRLPB9+MEu1Fb+kT9gWphI8=;
 b=6ztn1BppSzZB4kAA4w/uQUj0mKqeIzD5KgOAqWR8jiN8KRDF79YfXJ3lfxUKHf6nZYfJxX8ti
 n+2jk3nDMWCBvMkTxLRyidq/BoOxV7zcJfD1Gc+b0a0She+gcvSGyS6
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead, unregister the cpufreq device for this fatal fail case.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/cpufreq/tegra124-cpufreq.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/cpufreq/tegra124-cpufreq.c b/drivers/cpufreq/tegra124-cpufreq.c
index 514146d98bca2d8aa59980a14dff3487cd8045f6..bc0691e8971f9454def37f489e4a3e244100b9f4 100644
--- a/drivers/cpufreq/tegra124-cpufreq.c
+++ b/drivers/cpufreq/tegra124-cpufreq.c
@@ -168,7 +168,10 @@ static int __maybe_unused tegra124_cpufreq_resume(struct device *dev)
 disable_dfll:
 	clk_disable_unprepare(priv->dfll_clk);
 disable_cpufreq:
-	disable_cpufreq();
+	if (!IS_ERR(priv->cpufreq_dt_pdev)) {
+		platform_device_unregister(priv->cpufreq_dt_pdev);
+		priv->cpufreq_dt_pdev = ERR_PTR(-ENODEV);
+	}
 
 	return err;
 }

-- 
2.48.1

