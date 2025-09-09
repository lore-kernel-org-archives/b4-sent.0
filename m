From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v2 0/8] Support dynamic EMC frequency scaling on
 Tegra186/Tegra194
Date: Tue, 09 Sep 2025 01:21:28 -0500
Message-Id: <20250909-tegra186-icc-v2-0-09413724e781@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGjHv2gC/1WPy07DMBBFfyXyGqPxuH4kK/4DdeHHOLVEmtZOI
 1CVf8ckC2B5R5pzz32ySiVTZUP3ZIXWXPN8bQFfOhYu7joSz7FlhoAKLEq+0FicsJrnELjBvhc
 CQjTmxNrLrVDKnzvu/XzkQvdHoy7HkXlXiYd5mvIydMKjNEn0QF5GqZPCmBKBcSfwijwKQAsEw
 P7aNLnDRf+6hNsjtSK+l3OTfEpWBG0dDqtkPyaXXJe5fO07V7GrHBgp/k9aBQeuwcQYlPQKzNs
 4ufzx2pzZedu2b8KgVpoyAQAA
X-Change-ID: 20250823-tegra186-icc-7299110cd774
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-pm@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757398893; l=1966;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=+TPugvusqL3MFUtqbV61oju44pY2erZnaLrcqrSXMw0=;
 b=iK2GdH/ePzlNW4B7UF/cmnZZrVv0wHjuHNsT2RcusqUZ7OYZEASWN+vKkZAZlkSFPJOfMqxax
 ifP9WYAc3ebDwQHBOwdayPC2FLSYY/fPHm/Hb9Jc2zSqmeV5d+1zJop
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series borrows the concept used on Tegra234 to scale EMC based on
CPU frequency and applies it to Tegra186 and Tegra194. Except that the
bpmp on those archs does not support bandwidth manager, so the scaling
iteself is handled similar to how Tegra124 currently works.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v2:
- Use opp scoped free in patch 3
- Cleanup as requested in patch 3
- Move patch 3 to the start of the series to keep subsystems grouped
- Link to v1: https://lore.kernel.org/r/20250831-tegra186-icc-v1-0-607ddc53b507@gmail.com

---
Aaron Kling (8):
      cpufreq: tegra186: add OPP support and set bandwidth
      dt-bindings: memory: tegra186-mc: Add dummy client IDs for Tegra186
      dt-bindings: memory: tegra194-mc: Add dummy client IDs for Tegra194
      memory: tegra186-emc: Support non-bpmp icc scaling
      memory: tegra186: Support icc scaling
      memory: tegra194: Support icc scaling
      arm64: tegra: Add CPU OPP tables for Tegra186
      arm64: tegra: Add CPU OPP tables for Tegra194

 arch/arm64/boot/dts/nvidia/tegra186.dtsi | 317 +++++++++++++++
 arch/arm64/boot/dts/nvidia/tegra194.dtsi | 636 +++++++++++++++++++++++++++++++
 drivers/cpufreq/tegra186-cpufreq.c       | 152 +++++++-
 drivers/memory/tegra/tegra186-emc.c      | 132 ++++++-
 drivers/memory/tegra/tegra186.c          |  48 +++
 drivers/memory/tegra/tegra194.c          |  59 ++-
 include/dt-bindings/memory/tegra186-mc.h |   4 +
 include/dt-bindings/memory/tegra194-mc.h |   6 +
 8 files changed, 1344 insertions(+), 10 deletions(-)
---
base-commit: 1b237f190eb3d36f52dffe07a40b5eb210280e00
change-id: 20250823-tegra186-icc-7299110cd774
prerequisite-change-id: 20250826-tegra186-cpufreq-fixes-7fbff81c68a2:v3
prerequisite-patch-id: 74a2633b412b641f9808306cff9b0a697851d6c8
prerequisite-patch-id: 9c52827317f7abfb93885febb1894b40967bd64c

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

