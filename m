From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/2] cpufreq: tegra186: Fix initialization and scaling
Date: Tue, 26 Aug 2025 15:15:58 -0500
Message-Id: <20250826-tegra186-cpufreq-fixes-v1-0-97f98d3e0adb@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAP4VrmgC/x3LSwqAMAwA0atI1gZswVq8irioNdFs/KQqgnh3i
 8vHMA8kUqEEbfGA0iVJ1iXDlAXEOSwToYzZYCtbV946PGjSYLzDuJ2stCPLTQkbHpi9ic4HC3n
 elP6Q365/3w/l+hYNaAAAAA==
X-Change-ID: 20250826-tegra186-cpufreq-fixes-7fbff81c68a2
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756239382; l=642;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=oVlsbr0Om4iJks3GxT0/vdOhBTnl82lkeLSHLSp9gLY=;
 b=d0y1cj3ZkD/6aUt8GB3zzQTUIqnLEBNCe3MPJ4VbUdTLeQrc51CV9spvqZVqsh390XQB1Chh5
 CEiqpLaufuZBR41VwhRHMCw2W3CqPKrdcp4Cl0ushvieYvHN/Bj0EE5
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes an issue with shared policy per cluster not scaling
all cpus and with some cores being initialized by the subsystem.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Aaron Kling (2):
      cpufreq: tegra186: Set target frequency for all cpus in policy
      cpufreq: tegra186: Initialize all cores to base frequencies

 drivers/cpufreq/tegra186-cpufreq.c | 19 ++++++++++++++++---
 1 file changed, 16 insertions(+), 3 deletions(-)
---
base-commit: 1b237f190eb3d36f52dffe07a40b5eb210280e00
change-id: 20250826-tegra186-cpufreq-fixes-7fbff81c68a2

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

