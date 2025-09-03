From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v2 0/4] Properly Limit Tegra210 Clock Rates
Date: Wed, 03 Sep 2025 14:30:15 -0500
Message-Id: <20250903-tegra210-speedo-v2-0-89e6f86b8942@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEiXuGgC/2WNwQ7CIBAFf6XZsxhApbQn/8P0gLDSTWxpoCGah
 n8Xm3jyOJO8eRskjIQJ+maDiJkShbmCPDRgRzN7ZOQqg+TywrWQbEUfjRScpQXRBXZuueoE6ru
 2Fupqifig1168DZVHSmuI7/0gi6/9tdRfKwvGmem0OClunJXt1U+GnkcbJhhKKR/GQdY0rgAAA
 A==
X-Change-ID: 20250812-tegra210-speedo-470691e8b8cc
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Joseph Lo <josephl@nvidia.com>, 
 Peter De Schrijver <pdeschrijver@nvidia.com>, 
 Prashant Gaikwad <pgaikwad@nvidia.com>
Cc: linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Thierry Reding <treding@nvidia.com>, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756927822; l=1429;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=JUppoQ9npu9DVIYJDijPMBBHVSyQ+ANuSoJqzrpc8AU=;
 b=gqdrIp+Er4EjmHuTZsTCVAYnpCIzJZCtLeIHXNzToXG73rRAqIXhtjsR/yYXkhVEyWZkHVd3m
 lfTrELHYHgKC0DvHZjjFIj74lkvOQBmqSKvNknBVewztG1ZeYfQXrgS
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Tegra210 CVB tables were added in commit 2b2dbc2f94e5. Since then,
all Tegra210 socs have tried to scale the cpu to 1.9 GHz, when the
supported devkits are only supposed to scale to 1.5 or 1.7 GHZ.
Overclocking should not be the default state.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v2:
- Define units in patch 1
- Update patch 1 commit message to better explain the need
- Pull all downstream sku's into patch 2, which eliminates patch 3
- Update patch 4 commit message to indicate the limit is due to thermal
  constraints.
- Link to v1: https://lore.kernel.org/r/20250816-tegra210-speedo-v1-0-a981360adc27@gmail.com

---
Aaron Kling (4):
      dt-bindings: clock: tegra124-dfll: Add property to limit frequency
      soc: tegra: fuse: speedo-tegra210: Update speedo ids
      clk: tegra: dfll: Support limiting max clock per device
      arm64: tegra: Limit max cpu frequency on P3450

 .../bindings/clock/nvidia,tegra124-dfll.txt        |  3 ++
 arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts |  1 +
 drivers/clk/tegra/clk-tegra124-dfll-fcpu.c         |  8 ++-
 drivers/soc/tegra/fuse/speedo-tegra210.c           | 62 +++++++++++++++-------
 4 files changed, 54 insertions(+), 20 deletions(-)
---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250812-tegra210-speedo-470691e8b8cc

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

