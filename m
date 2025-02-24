From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/2] (no cover subject)
Date: Mon, 24 Feb 2025 11:55:32 -0600
Message-Id: <20250224-build-tegra234-v1-0-39e4e912f968@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJSyvGcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDIyMT3aTSzJwU3ZLU9KJEI2MT3WRDC9OklETLtBSTRCWgpoKi1LTMCrC
 B0bG1tQDeDU1GYAAAAA==
X-Change-ID: 20250224-build-tegra234-c185bda9fd4a
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, Sumit Gupta <sumitg@nvidia.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Vidya Sagar <vidyas@nvidia.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740419820; l=723;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=98Z6rWquwnb+oqau6pISJGfTMsaiWJKg9oR7AsN7MLQ=;
 b=iARYKkm2gfxVmnVK8DYl1ygPH+MXiUi2obi+p9pHnMiJJH3kPeSHY4FES+MyFsGKXyVN4z984
 mxKf7YYuNk0DrCqYGfvBq/7H/VUvvLRujZj1xLNpRYw92WAaZu3INUa
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When Tegra234 support was added to existing Tegra drivers, many of them
did not have the matching Kconfig entries updated to allow building for
the arch. A few of those have already been fixed. This series fixes a
couple more.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Aaron Kling (2):
      cpufreq: tegra194: Allow building for Tegra234
      PCI: tegra194: Allow building for Tegra234

 drivers/cpufreq/Kconfig.arm        | 2 +-
 drivers/pci/controller/dwc/Kconfig | 4 ++--
 2 files changed, 3 insertions(+), 3 deletions(-)
---
base-commit: d082ecbc71e9e0bf49883ee4afd435a77a5101b6
change-id: 20250224-build-tegra234-c185bda9fd4a

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

