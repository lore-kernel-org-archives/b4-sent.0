From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/2] arm64: tegra: Enable mmu on Tegra194 display
 controllers
Date: Sat, 01 Nov 2025 18:01:09 -0500
Message-Id: <20251101-tegra194-dc-mmu-v1-0-8401c45d8f13@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADWRBmkC/x3MPQqAMAxA4atIZgNNtYNeRRwkTTWDP7QqQvHuF
 sdveC9DkqiSoK8yRLk16b4VUF0BL9M2C6ovBmusIzKEp8xxoq5Fz7iuF7J01nFofMsBSnVECfr
 8x2F83w+5kEo3YQAAAA==
X-Change-ID: 20251101-tegra194-dc-mmu-ce925cf3d4cf
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762038074; l=612;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=24ZR53rGFlS9aCl+cwrC35kW0ffMoIyXJnJR8Fkzos4=;
 b=qoKvxUZlk1keasy7Yzs1Er5PafaKd65ytc2MeyLgvp4vKYmZSTeWrLaxizj19b+88vFthzZFn
 JJPZb/5aUiNA7MIIYICOzjKu/lByTWzdpQKcSdzQGZNO7ypdpbvuYwa
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This involves reverting a commit that explicitly disabled the associated
smmu, then wiring that to unit to the display controllers.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Aaron Kling (2):
      Revert "arm64: tegra: Disable ISO SMMU for Tegra194"
      arm64: tegra: Enable mmu on Tegra194 display controllers

 arch/arm64/boot/dts/nvidia/tegra194.dtsi | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)
---
base-commit: dcb6fa37fd7bc9c3d2b066329b0d27dedf8becaa
change-id: 20251101-tegra194-dc-mmu-ce925cf3d4cf

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

