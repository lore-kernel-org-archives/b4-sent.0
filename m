From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/5] Properly Limit Tegra210 Clock Rates
Date: Sat, 16 Aug 2025 00:53:32 -0500
Message-Id: <20250816-tegra210-speedo-v1-0-a981360adc27@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANwcoGgC/x3MSwqAIBRG4a3EHSeo9LC2Eg3M/uxOLDQikPaeN
 PwG52RKiIxEY5Up4ubERyhQdUVut8FD8FpMWupWGqXFBR+tVlKkE1gP0fSyGxTMYpyjUp0RGz/
 /cZrf9wPHlmM/YQAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755323658; l=1124;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=8klj2uYRMfs8FE617jEyAtR6aZOYS7SLudYM0j1xsJc=;
 b=YxZKMWmKba+krIJVoRlKTJR6SZv8sVtniqhXAmEvuC1t8HToXFXb2O9pGXk+SJ4NDI4UrjzhQ
 iSR3FVD6PuzDL/FRX2qtKMXMhf5HBqqGlA0s3BPkRJaKv8q50xfq3HX
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
Aaron Kling (5):
      dt-bindings: clock: tegra124-dfll: Add property to limit frequency
      soc: tegra: fuse: speedo-tegra210: Update speedo ids
      soc: tegra: fuse: speedo-tegra210: Add sku 0x8F
      clk: tegra: dfll: Support limiting max clock per device
      arm64: tegra: Limit max cpu frequency on P3450

 .../bindings/clock/nvidia,tegra124-dfll.txt        |  3 ++
 arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts |  1 +
 drivers/clk/tegra/clk-tegra124-dfll-fcpu.c         |  8 ++++-
 drivers/soc/tegra/fuse/speedo-tegra210.c           | 39 ++++++++++++++++++----
 4 files changed, 43 insertions(+), 8 deletions(-)
---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250812-tegra210-speedo-470691e8b8cc

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

