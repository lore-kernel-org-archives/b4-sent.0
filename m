From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 20 Apr 2025 15:42:00 -0500
Subject: [PATCH 1/2] cpufreq: Export disable_cpufreq()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250420-tegra124-cpufreq-v1-1-0a47fe126091@gmail.com>
References: <20250420-tegra124-cpufreq-v1-0-0a47fe126091@gmail.com>
In-Reply-To: <20250420-tegra124-cpufreq-v1-0-0a47fe126091@gmail.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745181742; l=614;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=lPtQ3+EArJBMl5gBrzCQeGZ6Aeo+U8TlBMXfq1u6eL8=;
 b=0yPG4YbW08dCVz3jh6d1950YItYdKNcKvxxXgmaTYIL9mKSmVgfTmOFJvS6eGqriBkX2vf72w
 9zJU+U1/Uj2CjCDxApISiNM4FLGPZHxd3GUgPl21eGnL2uBD9PVtcTA
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is used by the tegra124-cpufreq driver.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/cpufreq/cpufreq.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/cpufreq/cpufreq.c b/drivers/cpufreq/cpufreq.c
index 0cf5a320bb5e864709b259249fb1af8bfbc0b04b..78cddc78ee98630f99ccc332c64c94f437297177 100644
--- a/drivers/cpufreq/cpufreq.c
+++ b/drivers/cpufreq/cpufreq.c
@@ -109,6 +109,7 @@ void disable_cpufreq(void)
 {
 	off = 1;
 }
+EXPORT_SYMBOL_GPL(disable_cpufreq);
 static DEFINE_MUTEX(cpufreq_governor_mutex);
 
 bool have_governor_per_policy(void)

-- 
2.48.1

