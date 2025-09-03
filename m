From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v2 0/8] Support Tegra210 actmon for dynamic EMC scaling
Date: Wed, 03 Sep 2025 14:50:06 -0500
Message-Id: <20250903-t210-actmon-v2-0-e0d534d4f8ea@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAO6buGgC/1XPQW7DIBAF0KtYsy4VYIixV71HlQWGbwepNglQq
 1Xku5c4XbS7+SPN6P07ZaSATENzp4Qt5BDXGuRLQ+5i1xks+JpJcqm5kZIVKTizrixxZa3quXL
 o4LmjenFNmMLX8e39/MwJt8/6tDyXNNoM5uKyhDI0ZtIWLfen3ndatQC47zg3rbeT8jAThPbaa
 PqLqbaDIioFc7IPTr4CPjLV8VMvYEbj3LBJehAuIZeYvo9+mzgMv1XMvyqbYHXGKHo4MUml3ub
 Fho/XaqXzvu8/C/0UaykBAAA=
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
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756929080; l=2134;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=gFOnd9Tvis+cqdyg6z7tcp79CJ2p06seEOHvLMOOC+Y=;
 b=7m8WkKu0VNb7sEqCcDhrpHkv7f/U7cahaSgZVOVvIR97hswjw2MAkyV//p2TxDSk41hOQskoF
 GrxPCHZ4hGDBGdPqo3E0mX6eFx9XKgADp0fWytPxmYmB57bPU+kq4/Y
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds interconnect support to tegra210 MC and EMC, then
enables actmon. This enables dynamic emc scaling.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v2:
- Assume 64-bit dram bus width in patch 4
- Add dt-bindings patch to document the new properties on the
  tegra210-emc node.
- Link to v1: https://lore.kernel.org/r/20250828-t210-actmon-v1-0-aeb19ec1f244@gmail.com

---
Aaron Kling (8):
      dt-bindings: memory: tegra210: Add memory client IDs
      dt-bindings: devfreq: tegra30-actmon: Add Tegra124 fallback for Tegra210
      dt-bindings: memory: tegra210: emc: Document OPP table and interconnect
      soc: tegra: fuse: speedo-tegra210: Add soc speedo 2
      memory: tegra210: Support interconnect framework
      arm64: tegra: tegra210: Add actmon
      arm64: tegra: Add interconnect properties to Tegra210 device-tree
      arm64: tegra: Add OPP tables on Tegra210

 .../bindings/devfreq/nvidia,tegra30-actmon.yaml    |  13 +-
 .../memory-controllers/nvidia,tegra210-emc.yaml    |  13 +
 .../boot/dts/nvidia/tegra210-peripherals-opp.dtsi  | 135 ++++++++++
 arch/arm64/boot/dts/nvidia/tegra210.dtsi           |  43 ++++
 drivers/memory/tegra/Kconfig                       |   1 +
 drivers/memory/tegra/tegra210-emc-core.c           | 274 ++++++++++++++++++++-
 drivers/memory/tegra/tegra210-emc.h                |  23 ++
 drivers/memory/tegra/tegra210.c                    |  81 ++++++
 drivers/soc/tegra/fuse/speedo-tegra210.c           |   1 +
 include/dt-bindings/memory/tegra210-mc.h           |  58 +++++
 10 files changed, 635 insertions(+), 7 deletions(-)
---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250822-t210-actmon-34904ce7ed0c
prerequisite-change-id: 20250812-tegra210-speedo-470691e8b8cc:v2
prerequisite-patch-id: 83adce426963f91482cc0928357dad36705a3328
prerequisite-patch-id: f693f138b5d40cdc45d9066ce48cbcff782253f8
prerequisite-patch-id: 9e3b9b2fdb8d9c2264dfa7641d1aec84fb7aedd9
prerequisite-patch-id: ef4bcc4ddba7898b188fb3fc6e414a2662183f91

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

