From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v3 0/4] Tegra CEC Updates
Date: Wed, 09 Apr 2025 17:57:21 -0500
Message-Id: <20250409-tegra-cec-v3-0-91640131dfa2@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFL79mcC/22MwQ6DIBAFf8XsuTSIUGxP/Y+mB4RFN6nSgCFtj
 P9e9OShx3l5MwskjIQJbtUCETMlClOB5lSBHczUIyNXGAQXikuu2Yx9NMyiZRobozv0Ul08lP8
 7oqfP3no8Cw+U5hC/ezrX2/qvkmvGGQrl3FVp3Sl/70dDr7MNI2yVLI5mezRFMYXnXHrnW4nt0
 VzX9QeA4FBA3AAAAA==
X-Change-ID: 20250407-tegra-cec-7e3a7bef456f
To: Hans Verkuil <hverkuil@xs4all.nl>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-tegra@vger.kernel.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744239446; l=1738;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=IYXgA9m/26sMDrILCQnvUu7ZffwoswKKZa5Bxjp4hnQ=;
 b=XrEolROn2YCvTM9CofMWLZ45J3A3ZofsZlNX8w7BlwIQCijcJl67Ux0IIujVjScG9ENc4FPU2
 pNaHaeMTkoJAKKGJJcCK1fQx4ApdnQloFeD8d1EMdTknnybXd8pn2Aw
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series updates Tegra hdmi cec support to be usable out of the box
on Tegra210 through Tegra194.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v3:
- Update patch 1 to fix lint warnings
- Link to v2: https://lore.kernel.org/r/20250408-tegra-cec-v2-0-2f004fdf84e8@gmail.com

Changes in v2:
- Dropped patch 2, per request
- Added change to declare fallback compatibles instead, as per request
- Update patch 1 to allow fallback compatibles
- Link to v1: https://lore.kernel.org/r/20250407-tegra-cec-v1-0-e25dd9577b5f@gmail.com

---
Aaron Kling (4):
      media: dt-bindings: Document Tegra186 and Tegra194 cec
      arm64: tegra: Add fallback cec compatibles
      arm64: tegra: Add CEC controller on Tegra210
      arm64: tegra: Wire up cec to devkits

 .../bindings/media/cec/nvidia,tegra114-cec.yaml           | 15 +++++++++++----
 arch/arm64/boot/dts/nvidia/tegra186-p2771-0000.dts        |  6 ++++++
 .../boot/dts/nvidia/tegra186-p3509-0000+p3636-0001.dts    |  6 ++++++
 arch/arm64/boot/dts/nvidia/tegra186.dtsi                  |  2 +-
 arch/arm64/boot/dts/nvidia/tegra194-p2972-0000.dts        |  6 ++++++
 arch/arm64/boot/dts/nvidia/tegra194-p3509-0000.dtsi       |  6 ++++++
 arch/arm64/boot/dts/nvidia/tegra194.dtsi                  |  2 +-
 arch/arm64/boot/dts/nvidia/tegra210-p2371-2180.dts        |  6 ++++++
 arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts        |  6 ++++++
 arch/arm64/boot/dts/nvidia/tegra210.dtsi                  |  9 +++++++++
 10 files changed, 58 insertions(+), 6 deletions(-)
---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250407-tegra-cec-7e3a7bef456f

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

