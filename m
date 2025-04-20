From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/2] Support building tegra124-cpufreq as a module
Date: Sun, 20 Apr 2025 15:41:59 -0500
Message-Id: <20250420-tegra124-cpufreq-v1-0-0a47fe126091@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABdcBWgC/x3MQQqAIBBA0avErBNULKirRIvQ0WZjNlYE4t2Tl
 m/xf4GMTJhh7gowPpTpiA2q78DuWwwoyDWDlnqQRipxYeBNaSNsuj3jKbybjPHO4qgttCwxenr
 /5bLW+gFDC4nxYgAAAA==
X-Change-ID: 20250401-tegra124-cpufreq-fd944fdce62c
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745181742; l=748;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=kKokJEjFYi8Ksm5QQ3qONIkFxJYvW00e94gaOUzw0KU=;
 b=26xLAOIifCd1GbPdD4cj7WbTjM8dDmrB5R6GMNa+xPo4UL312EK7dD7DYkaLNRXaYp97iv/MR
 pSFG6kKJE/+BCPHLlYpf/wD7I47/EmggR4tGnHKLzdWe5t1XmyL845j
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This driver handles power management while offloading the primary
cpufreq operations to cpufreq-dt. It fully disables cpufreq during
resume if clocks fail, thus it needs access to a previously unexported
cpufreq symbol.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Aaron Kling (2):
      cpufreq: Export disable_cpufreq()
      cpufreq: tegra124: Allow building as a module

 drivers/cpufreq/Kconfig.arm        | 2 +-
 drivers/cpufreq/cpufreq.c          | 1 +
 drivers/cpufreq/tegra124-cpufreq.c | 2 ++
 3 files changed, 4 insertions(+), 1 deletion(-)
---
base-commit: 91e5bfe317d8f8471fbaa3e70cf66cae1314a516
change-id: 20250401-tegra124-cpufreq-fd944fdce62c

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

