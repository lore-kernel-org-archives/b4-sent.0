From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v3 0/2] cpufreq: tegra186: Fix initialization and scaling
Date: Thu, 28 Aug 2025 21:48:11 -0500
Message-Id: <20250828-tegra186-cpufreq-fixes-v3-0-23a7341db254@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOsUsWgC/4XNTQ6CMBAF4KuYrq1pi0Bx5T2Mi9LOwCTyY4uNh
 nB3Cys2xuV7k/fNzAJ4gsAuh5l5iBRo6FPIjgdmW9M3wMmlzJRQudCq4BM03khdcDu+0MOTI70
 h8BJrRC1toY1iaTx62A5pe7un3FKYBv/Z/kS5tn/JKLngVYmVdhkI4+pr0xl6nOzQsZWMas/on
 4xKDFpEODuQIPM9syzLF+p8uT0DAQAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756435694; l=1054;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=F7mq3mQpR2KiFF/AsoLrSfDqZtvtQRQwU8TA3URhotg=;
 b=hcKAb77AQTURPlJpbuRsaDf23cZNJC0uF3xq1QlBO+4Q1VRhNuTeQHpmXNZ4jVjEyAgD+AEq7
 Wi0QuMejFeZBR2lqd5CUVhAlkWGvjLMtIkcpD6XCw07MIo0qWZGINYQ
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes an issue with shared policy per cluster not scaling
all cpus and with some cores being initialized by the subsystem.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v3:
- Use more clearly named variables in patch 2
- In patch 2, fail probe if no cpu rates reported by bpmp
- Link to v2: https://lore.kernel.org/r/20250828-tegra186-cpufreq-fixes-v2-0-fcffe4de1e15@gmail.com

Changes in v2:
- Set max freq instead of base freq in patch 2
- Link to v1: https://lore.kernel.org/r/20250826-tegra186-cpufreq-fixes-v1-0-97f98d3e0adb@gmail.com

---
Aaron Kling (2):
      cpufreq: tegra186: Set target frequency for all cpus in policy
      cpufreq: tegra186: Initialize all cores to max frequencies

 drivers/cpufreq/tegra186-cpufreq.c | 35 +++++++++++++++++++++++++++--------
 1 file changed, 27 insertions(+), 8 deletions(-)
---
base-commit: 1b237f190eb3d36f52dffe07a40b5eb210280e00
change-id: 20250826-tegra186-cpufreq-fixes-7fbff81c68a2

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

