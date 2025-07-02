From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v5 0/3] Support building tegra124-cpufreq as a module
Date: Wed, 02 Jul 2025 02:46:23 -0500
Message-Id: <20250702-tegra124-cpufreq-v5-0-66ab3640a570@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANDjZGgC/4XO0arCMAyA4VeRXttDkmVz88r3EC+6Np0FdbPTo
 sje/VQ5cEQFL/9AvuSmRolBRrWc3VSUFMbQH3KU85myW3PoRAeXWxFQCQyoT9JFg8TaDmcf5ai
 9a5i9s1KRVXltiOLD5UGuN7m3YTz18fq4kPA+/cMI3rGEGjQYXnhBqqDBVbc3Yfdj+726Y4meg
 Q/fJMoAeeTaijeM9StQfAOKDDSlmNY0Vc3V4hXgf6CE+gPAGXDI1NrWARX8DEzT9AsupkNMcwE
 AAA==
X-Change-ID: 20250401-tegra124-cpufreq-fd944fdce62c
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751442407; l=1799;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=f6OQCjZuWiov1eLKcBiyn9GOG0SInVztkbDL2cq2EXg=;
 b=w/IpZgR+XXSVExwCySdXj0zT1TojJMleiNoC0DH5aGBf7aqM90Ee5bh+JrZAsNqmLvthmZXQK
 0dAvfOLbPiaDTCr7f7HV/JL/+5B1zHsFWDbTHMFNuR/q3Ai8Epux+Qh
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds remove and exit routines that were not previously needed when
this was only available builtin.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v5:
- Add register helper function to cpufreq-dt for kernel users to use to
  establish a depmod dependency
- Drop patch that removes use of disable_cpufreq and re-add the patch to
  export said function
- Link to v4: https://lore.kernel.org/r/20250508-tegra124-cpufreq-v4-0-d142bcbd0234@gmail.com

Changes in v4:
- Move clock puts to remove instead of exit
- Link to v3: https://lore.kernel.org/r/20250421-tegra124-cpufreq-v3-0-95eaba968467@gmail.com

Changes in v3:
- In patch 1, set cpufreq_dt_pdev to an error after unregister on fail
  to prevent a potential double unregister on remove
- In patch 2, clean up clocks on exit
- Link to v2: https://lore.kernel.org/r/20250421-tegra124-cpufreq-v2-0-2f148cefa418@gmail.com

Changes in v2:
- Replace patch 1 with a patch to not use the unexported function
- Update patch 2 to add remove and exit routines
- Link to v1: https://lore.kernel.org/r/20250420-tegra124-cpufreq-v1-0-0a47fe126091@gmail.com

---
Aaron Kling (3):
      cpufreq: Export disable_cpufreq()
      cpufreq: dt: Add register helper
      cpufreq: tegra124: Allow building as a module

 drivers/cpufreq/Kconfig.arm        |  2 +-
 drivers/cpufreq/cpufreq-dt.c       | 11 ++++++++++
 drivers/cpufreq/cpufreq-dt.h       |  2 ++
 drivers/cpufreq/cpufreq.c          |  1 +
 drivers/cpufreq/tegra124-cpufreq.c | 44 +++++++++++++++++++++++++++++---------
 5 files changed, 49 insertions(+), 11 deletions(-)
---
base-commit: 91e5bfe317d8f8471fbaa3e70cf66cae1314a516
change-id: 20250401-tegra124-cpufreq-fd944fdce62c

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

