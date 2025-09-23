From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v4 0/9] Support Tegra210 actmon for dynamic EMC scaling
Date: Tue, 23 Sep 2025 12:05:26 -0500
Message-Id: <20250923-t210-actmon-v4-0-442d1eb6377c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFfT0mgC/12P0W6EIBBFf8XwXJoBBkWf+h9NHxAGl6SuW7Cmz
 cZ/L6tNqn2bO8m5OffOMqVImXXVnSVaYo7TtQR8qpi72OtAPPqSmQSpwUjJZymAWzeP05UrbAE
 dNeTBsULcEoX4tbW9vu050cdnKZ33J+ttJu6mcYxzV5mgLSnwdesbjYqIwDcARnkb0JMJJLTXR
 rOjTFftKqKo0JDsQyffiPzEsYG6FWR641y3IHsoXGKep/S97VvE5vA7xZymLIKXm3rRkhNBIr4
 Mo43vz8V161nkH9uCOrOysMVdK/QYDNn/rDqy9ZlVhRUIStVlayPoyK7r+gNOzL7noQEAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758647133; l=2651;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=3WlgG06ZOkLQJ3sKxctiH8zHTTaZsOpoBGk+S7tsbOs=;
 b=z0v2a8ImXyw4C7krSyxtVQ46J/3UUsgNQMisJ1gGGvT32B3g3VipgCuObglCK0TjDHHqJGiMC
 jIo42o+zbYpBX3w8datMv6EH/k4yv1l6XSp9oA+5PW5AQcwR8kCIz2h
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
Changes in v4:
- Various cleanups in patch 5 as requested by review
- Fix a couple typos in patch 4
- Link to v3: https://lore.kernel.org/r/20250906-t210-actmon-v3-0-1403365d571e@gmail.com

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
 .../boot/dts/nvidia/tegra210-peripherals-opp.dtsi  | 135 +++++++++++
 arch/arm64/boot/dts/nvidia/tegra210.dtsi           |  43 ++++
 drivers/memory/tegra/Kconfig                       |   1 +
 drivers/memory/tegra/tegra210-emc-core.c           | 268 ++++++++++++++++++++-
 drivers/memory/tegra/tegra210-emc.h                |  23 ++
 drivers/memory/tegra/tegra210.c                    | 227 +++++++++++------
 drivers/soc/tegra/fuse/speedo-tegra210.c           |   1 +
 include/dt-bindings/memory/tegra210-mc.h           |  74 ++++++
 10 files changed, 716 insertions(+), 80 deletions(-)
---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250822-t210-actmon-34904ce7ed0c
prerequisite-change-id: 20250812-tegra210-speedo-470691e8b8cc:v4
prerequisite-patch-id: d32dd215b54ac46086377c1ce2c8d53d746690c9

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

