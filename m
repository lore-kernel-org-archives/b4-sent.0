From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v2 0/2] cpufreq: tegra186: Fix initialization and scaling
Date: Thu, 28 Aug 2025 11:57:19 -0500
Message-Id: <20250828-tegra186-cpufreq-fixes-v2-0-fcffe4de1e15@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAG+KsGgC/4WNTQ6CMBCFr0Jm7Zi2xlJceQ/DorRTmET+WiQaw
 t2tXMDl916+9zZIFJkS3IoNIq2ceBwyqFMBrrNDS8g+MyihrsIojQu10Uqj0U2vEGnGwG9KWIY
 mBCOdNlZBlqdIR5HdR52547SM8XP8rPKX/p1cJQqsylAZfyFhfXNve8vPsxt7qPd9/wKAUAMDv
 AAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756400245; l=820;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=MyGuywaVJRTnrDuohxHecg+wMfhfMcnjDHdSphNISLY=;
 b=jTkl4Ze5C2Hk4Gg/ssP9hc3eZzVbpeg/G2YMW+0uFbkBSrM1Is5s3uDGl/NemC36ypPtUO2wc
 +E51dc/pgphCnTJY1zDIBifWBCbDNfAi8M2T/L6m6zrLM1j8mr5kqk3
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes an issue with shared policy per cluster not scaling
all cpus and with some cores being initialized by the subsystem.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v2:
- Set max freq instead of base freq in patch 2
- Link to v1: https://lore.kernel.org/r/20250826-tegra186-cpufreq-fixes-v1-0-97f98d3e0adb@gmail.com

---
Aaron Kling (2):
      cpufreq: tegra186: Set target frequency for all cpus in policy
      cpufreq: tegra186: Initialize all cores to max frequencies

 drivers/cpufreq/tegra186-cpufreq.c | 26 +++++++++++++++++++++-----
 1 file changed, 21 insertions(+), 5 deletions(-)
---
base-commit: 1b237f190eb3d36f52dffe07a40b5eb210280e00
change-id: 20250826-tegra186-cpufreq-fixes-7fbff81c68a2

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

