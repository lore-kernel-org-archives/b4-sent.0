From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 21 Apr 2025 03:13:31 -0500
Subject: [PATCH v2 1/2] cpufreq: tegra124: Remove use of disable_cpufreq
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250421-tegra124-cpufreq-v2-1-2f148cefa418@gmail.com>
References: <20250421-tegra124-cpufreq-v2-0-2f148cefa418@gmail.com>
In-Reply-To: <20250421-tegra124-cpufreq-v2-0-2f148cefa418@gmail.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745223214; l=809;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=goje1oshiHYjUzzYAZp/ybbJMpcm4IHxhykHgvfR+Oc=;
 b=zrAuRuIUwzyI6uIM3MhkgAZ+6ROLi1vFgqv8Sk4EMvUi9Zqepv7HlDGnaWhsZs46kSAmFkgdL
 BToHCPx+MTnBDbBAJhhRxldkFlc8T1IC4JkodoLavXEvdAJoRfpo2sv
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead, unregister the cpufreq device for this fatal fail case.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/cpufreq/tegra124-cpufreq.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/cpufreq/tegra124-cpufreq.c b/drivers/cpufreq/tegra124-cpufreq.c
index 514146d98bca2d8aa59980a14dff3487cd8045f6..dc83b1631b13ec428f3b6bbea89462448a62adb4 100644
--- a/drivers/cpufreq/tegra124-cpufreq.c
+++ b/drivers/cpufreq/tegra124-cpufreq.c
@@ -168,7 +168,8 @@ static int __maybe_unused tegra124_cpufreq_resume(struct device *dev)
 disable_dfll:
 	clk_disable_unprepare(priv->dfll_clk);
 disable_cpufreq:
-	disable_cpufreq();
+	if (!IS_ERR(priv->cpufreq_dt_pdev))
+		platform_device_unregister(priv->cpufreq_dt_pdev);
 
 	return err;
 }

-- 
2.48.1

