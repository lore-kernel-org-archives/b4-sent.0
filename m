From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 07 Jul 2025 16:17:13 -0500
Subject: [PATCH v6 1/3] cpufreq: Export disable_cpufreq()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250707-tegra124-cpufreq-v6-1-fe69c0f9bbab@gmail.com>
References: <20250707-tegra124-cpufreq-v6-0-fe69c0f9bbab@gmail.com>
In-Reply-To: <20250707-tegra124-cpufreq-v6-0-fe69c0f9bbab@gmail.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751923039; l=614;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=NFHbo8ZLsnmTINee5fdPYY+g47zvEQ1GnvuQon0Ga54=;
 b=SYN1C3omppLTHmdh/N3jYvRNM8zPPiu4wxHYor/Ky6k+sIPYa4crIEGfGSX57vy0vWPOK/foB
 gQ9x/Dj5oIdBijvZaiyJm9kq2v+uDeC4ISAuyxTqTnU2IkMzcLzjEpy
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
2.50.0

