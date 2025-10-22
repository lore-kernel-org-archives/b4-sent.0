From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v3 0/5] memory: tegra: Support EMC dfs on Tegra186/Tegra194
Date: Tue, 21 Oct 2025 20:09:52 -0500
Message-Id: <20251021-tegra186-icc-p2-v3-0-1a50b526dd40@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOEu+GgC/3WNywrDIBBFfyXMulPUVNGu+h8lC6PGDDQPNEhLy
 L/XZt/lOXDP3SGHRCHDvdkhhUKZlrlCe2nAjXaOAclXBsGE5Exw3EJMlmuF5ByuArW6DV4rIZU
 xUFdrCgO9z+KzqzxS3pb0OQ8K/9n/rcKRYWu8bHvvjLX9I06WXle3TNAdx/EFWgQ8N64AAAA=
X-Change-ID: 20251021-tegra186-icc-p2-864fd8625699
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761095398; l=1563;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=iEZ3/OOtUYpUWb/Hmkq01MLpHrlFJVXHuEpAh10U1PU=;
 b=mkiUirVqrWeYiSErGm6C0HNaMXUx+3pFokbiZZExtqkZXd9vr2J5+pK4nop+RlQSa6GN3nWp0
 vkdg89lOyNrCXdLLQQGIcfbaqYaIAq+AToHDesRUb83qhyRcs2zl1LC
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
Changes in v3:
- Split series
- Link to v2: https://lore.kernel.org/r/20250909-tegra186-icc-v2-0-09413724e781@gmail.com

Changes in v2:
- Use opp scoped free in patch 3
- Cleanup as requested in patch 3
- Move patch 3 to the start of the series to keep subsystems grouped
- Link to v1: https://lore.kernel.org/r/20250831-tegra186-icc-v1-0-607ddc53b507@gmail.com

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

