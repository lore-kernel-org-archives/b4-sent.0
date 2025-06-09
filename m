From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH RFC 0/2] arm64: tegra: Add NVIDIA Jetson Nano 2GB Developer
 Kit support
Date: Sun, 08 Jun 2025 23:24:34 -0500
Message-Id: <20250608-p3452-v1-0-4c2c1d7e4310@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAJiRmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDU0Nj3QJjE1MjXQNTS3MDi+RES0tLYyWg2oKi1LTMCrA50UpBbs5KsbW
 1ABmodlpcAAAA
X-Change-ID: 20250513-p3452-059708ca9993
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749443083; l=606;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=nA4pr8rR8GdTPJG1GEj2FJ2dYpGn+ljhMBTSZXnCjfw=;
 b=3whLJDhEmZEwU8CgXuejrd87bVi5K1GSxA2ybAQz6muihICLk3igRj4rBsRDHAJUSejhtoOZs
 lKQcri3FujqByhHbo5T43vkhqLy7BhYxw7ZvjIKUHsSHIcUq9AXbprh
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Aaron Kling (2):
      dt-bindings: arm: tegra: Document Jetson Nano Devkits
      arm64: tegra: Add NVIDIA Jetson Nano 2GB Developer Kit support

 Documentation/devicetree/bindings/arm/tegra.yaml   |  5 +++
 arch/arm64/boot/dts/nvidia/Makefile                |  2 +
 arch/arm64/boot/dts/nvidia/tegra210-p3541-0000.dts | 43 ++++++++++++++++++++++
 3 files changed, 50 insertions(+)
---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20250513-p3452-059708ca9993

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

