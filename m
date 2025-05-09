From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v4 0/2] Support building tegra124-cpufreq as a module
Date: Thu, 08 May 2025 19:04:13 -0500
Message-Id: <20250508-tegra124-cpufreq-v4-0-d142bcbd0234@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAH1GHWgC/4XOSw6CMBCA4auQrq1ph+HlynsYF7VMoYk8LNhoC
 He3EBdETVz+k8w3M7GBnKWBHaKJOfJ2sF0bAncR07VqK+K2DM1AQCJQSD5S5ZQE5Lq/G0c3bso
 C0ZSaUtAsrPWOjH2s5OkcurbD2LnnesHLZfrGQHxjXnLBhcLMkIRUFPJYNcpe97pr2IJ52AI/v
 vEQADASc01Gocw/gfgfEAegSEhdVJHmmGZbYJ7nF4xzpOoyAQAA
X-Change-ID: 20250401-tegra124-cpufreq-fd944fdce62c
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746749056; l=1390;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=57Np20SdFeVQE9PtU0KXWCY9OLkd7sjux9udzUUqAks=;
 b=JuqRJq7vMFUtK4ZbxKkFFgQ6PSAQpueCmTe6GdZROXOGFE/WfKaQhYHoND47mWrNgLIlshy0V
 CE/Tf7s/CBEA23K7ZytwKZmYLGQxALudy4VnVWlOmSLAZit7C+Z19Hq
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds remove and exit routines that were not previously needed when
this was only available builtin. It also converts use of an unexported
function to a more sane alternative.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
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
Aaron Kling (2):
      cpufreq: tegra124: Remove use of disable_cpufreq
      cpufreq: tegra124: Allow building as a module

 drivers/cpufreq/Kconfig.arm        |  2 +-
 drivers/cpufreq/tegra124-cpufreq.c | 41 +++++++++++++++++++++++++++++++++-----
 2 files changed, 37 insertions(+), 6 deletions(-)
---
base-commit: 91e5bfe317d8f8471fbaa3e70cf66cae1314a516
change-id: 20250401-tegra124-cpufreq-fd944fdce62c

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

