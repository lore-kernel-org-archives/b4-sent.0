From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v3 0/9] Support Tegra210 actmon for dynamic EMC scaling
Date: Sat, 06 Sep 2025 15:16:50 -0500
Message-Id: <20250906-t210-actmon-v3-0-1403365d571e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALKWvGgC/1WPy26DMBREfwV5XVd+BsOq/1F1YewxsVRwYlPUK
 uLf60ClJrs7VzqjMzdSkCMK6ZsbyVhjiWmuQb40xJ3tPIJGXzMRTGhmhKCL4Ixat0xpplJ1TDm
 08MyRSlwyQvze294/jpxx/aqly/Ekgy2gLk1TXPrGBG0hmT91vtVKAmC+ZcxIb4PyMAFce200e
 ZTpm0OFVxWM2d51ygXwiaqWnToOMxjn+lWSu8I5liXln33fyneHvynmacrKab0x8A6OB6HU2zj
 Z+PlaXfeeVfyzHZPPrKhsdddSeRUM7CO7bdsvOGDbWWUBAAA=
X-Change-ID: 20250822-t210-actmon-34904ce7ed0c
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Kyungmin Park <kyungmin.park@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, Dmitry Osipenko <digetx@gmail.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-pm@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>, Chanwoo Choi <cw00c.choi@samsung.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757189854; l=2455;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=h4FTk8uGgBle/y65Nq0TPLgDFPCw5v0+bcCx/Z5KdoY=;
 b=b9Y+H4bMc73RlGZcMc7ikgg9jzQGNldmcACy+D5eogJeLGBv7nbHnNZh1tC3mrIxMzNr56E7+
 jyrYRKp1puRA5xQlYW2atZ9oJQII2zNLN4tCPC2rB7LR7lSZCB9/jiw
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds interconnect support to tegra210 MC and EMC, then
enables actmon. This enables dynamic emc scaling.

There are no cross-subsystem hard dependencies, only logical relations.
The subsystems can be merged in any order.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v3:
- In patch 5, don't fail mc probe if opp tables are missing
- Add more mc bindings to patch 1
- Add patch to use tegra210-mc bindings in the mc driver
- Re-order series to align patches within a subsystem to each other
- Link to v2: https://lore.kernel.org/r/20250903-t210-actmon-v2-0-e0d534d4f8ea@gmail.com

Changes in v2:
- Assume 64-bit dram bus width in patch 4
- Add dt-bindings patch to document the new properties on the
  tegra210-emc node.
- Link to v1: https://lore.kernel.org/r/20250828-t210-actmon-v1-0-aeb19ec1f244@gmail.com

---
Aaron Kling (9):
      dt-bindings: devfreq: tegra30-actmon: Add Tegra124 fallback for Tegra210
      dt-bindings: memory: tegra210: emc: Document OPP table and interconnect
      dt-bindings: memory: tegra210: Add memory client IDs
      memory: tegra210: Use bindings for client ids
      memory: tegra210: Support interconnect framework
      soc: tegra: fuse: speedo-tegra210: Add soc speedo 2
      arm64: tegra: tegra210: Add actmon
      arm64: tegra: Add interconnect properties to Tegra210 device-tree
      arm64: tegra: Add OPP tables on Tegra210

 .../bindings/devfreq/nvidia,tegra30-actmon.yaml    |  13 +-
 .../memory-controllers/nvidia,tegra210-emc.yaml    |  11 +
 .../boot/dts/nvidia/tegra210-peripherals-opp.dtsi  | 135 ++++++++++
 arch/arm64/boot/dts/nvidia/tegra210.dtsi           |  43 ++++
 drivers/memory/tegra/Kconfig                       |   1 +
 drivers/memory/tegra/tegra210-emc-core.c           | 272 ++++++++++++++++++++-
 drivers/memory/tegra/tegra210-emc.h                |  23 ++
 drivers/memory/tegra/tegra210.c                    | 227 +++++++++++------
 drivers/soc/tegra/fuse/speedo-tegra210.c           |   1 +
 include/dt-bindings/memory/tegra210-mc.h           |  74 ++++++
 10 files changed, 720 insertions(+), 80 deletions(-)
---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250822-t210-actmon-34904ce7ed0c
prerequisite-change-id: 20250812-tegra210-speedo-470691e8b8cc:v3
prerequisite-patch-id: f693f138b5d40cdc45d9066ce48cbcff782253f8

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

