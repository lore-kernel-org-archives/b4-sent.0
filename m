From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/5] memory: tegra: Support EMC dfs on Tegra186/Tegra194
Date: Tue, 21 Oct 2025 13:29:39 -0500
Message-Id: <20251021-tegra186-icc-p2-v1-0-39d53bdc9aab@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABPR92gC/x3MQQqAIBBA0avIrBvIIcW6SrQIHW02FRoRhHdPW
 r7F/y8UzsIFJvVC5luKHHuD7hT4bd0To4RmoJ6M7knjxSmv2lkU7/EkdHaIwVkydhyhVWfmKM9
 /nJdaP/Euh21hAAAA
X-Change-ID: 20251021-tegra186-icc-p2-864fd8625699
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761071387; l=1375;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=daEGchRbrB82O1mBoWQ5N40AQ1EPwEMYN8krVbdjopo=;
 b=ILWchI7y7cIlEiR6AA5tMPVLbFCIYiAPQLyfq+4Ktw+krK5CNPab8D2fnm/VrLzJjZkBY9QuE
 X0tkMdOO9ROCfQ+vmW9peQOJ+rfjsbQjW759arw3dqL5l2x8K6qVUTz
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series borrows the concept used on Tegra234 to scale EMC based on
CPU frequency and applies it to Tegra186 and Tegra194. Except that the
bpmp on those archs does not support bandwidth manager, so the scaling
iteself is handled similar to how Tegra124 currently works.

This was originally part of a larger series [0], but it was requested to
be split into smaller series.

[0] https://lore.kernel.org/r/20250909-tegra186-icc-v2-0-09413724e781@gmail.com

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Aaron Kling (5):
      dt-bindings: memory: tegra186-mc: Add dummy client IDs for Tegra186
      dt-bindings: memory: tegra194-mc: Add dummy client IDs for Tegra194
      memory: tegra186-emc: Support non-bpmp icc scaling
      memory: tegra186: Support icc scaling
      memory: tegra194: Support icc scaling

 drivers/memory/tegra/tegra186-emc.c      | 132 ++++++++++++++++++++++++++++++-
 drivers/memory/tegra/tegra186.c          |  48 +++++++++++
 drivers/memory/tegra/tegra194.c          |  59 +++++++++++++-
 include/dt-bindings/memory/tegra186-mc.h |   4 +
 include/dt-bindings/memory/tegra194-mc.h |   6 ++
 5 files changed, 246 insertions(+), 3 deletions(-)
---
base-commit: 211ddde0823f1442e4ad052a2f30f050145ccada
change-id: 20251021-tegra186-icc-p2-864fd8625699

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

