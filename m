From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v3 0/2] Support building tegra124-cpufreq as a module
Date: Mon, 21 Apr 2025 12:33:52 -0500
Message-Id: <20250421-tegra124-cpufreq-v3-0-95eaba968467@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAICBBmgC/23OzQ6CMAzA8VchOzvT1ongyfcwHpbRwRL5cMNFQ
 3h3B/FAosd/k/7aSQT2joM4Z5PwHF1wfZfisMuEaXRXs3RVakFAR1CAcuTaayQlzfC0nh/SVqV
 StjKckxFpbfBs3Wslr7fUjQtj79/rhYjL9IsR/GIRJUjQ6mQZKYcSL3Wr3X1v+lYsWKQt8OebS
 Akgi6owbLXCYgvM8/wBg+CXXPEAAAA=
X-Change-ID: 20250401-tegra124-cpufreq-fd944fdce62c
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745256838; l=1232;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=an4XT5sgGD6GiQNc4+ujYYfFrngTMsWP8TIiMqbzahc=;
 b=xCB/vHo+bw5EXi3xw2qeWcQVcOddGFRZBrnWmZpWdWMTX3bX2BX5l8J7IIKyCqxuH7opso136
 qngoqLZo5SgDsIGoKhRCJEPLyDOlw4S73FUq4g80UWMQjEHFny2Sw3Z
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds remove and exit routines that were not previously needed when
this was only available builtin. It also converts use of an unexported
function to a more sane alternative.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
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
 drivers/cpufreq/tegra124-cpufreq.c | 46 +++++++++++++++++++++++++++++++++-----
 2 files changed, 42 insertions(+), 6 deletions(-)
---
base-commit: 91e5bfe317d8f8471fbaa3e70cf66cae1314a516
change-id: 20250401-tegra124-cpufreq-fd944fdce62c

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

