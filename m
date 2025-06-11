From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v2 0/2] arm64: tegra: Add NVIDIA Jetson Nano 2GB Developer
 Kit support
Date: Wed, 11 Jun 2025 13:53:36 -0500
Message-Id: <20250611-p3452-v2-0-fd2679706c63@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALDQSWgC/y3MSwrCMBSF4a2UOzZy87JNR+5DOghpbC/YpiQSl
 JK9G6vD/3D4dkg+kk/QNztEnylRWGuIUwNutuvkGY21QaDQqLlkm1RaMNSmxc5ZY4yE+t2iv9P
 rcG5D7ZnSM8T3wWb+XX/CBbu/kDlDppxwfGy9khyv02LpcXZhgaGU8gGJpFkUmgAAAA==
X-Change-ID: 20250513-p3452-059708ca9993
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749668025; l=858;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=P+1ESEkXYegBu8N1MnlcKmO5OEfHwJk5Zgtvhhg31BM=;
 b=oT7g3x+h36TNbm8SOmmg4YmQkQRmE2LXcKu5p/zJBftIRo76QJh2flBI4+/SU21VLwNExTevo
 iAK2PkA18Z4AWj4Lnl0LVpHQASK6B2s5WG42xys2bLNc3dsPMnwPQzp
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v2:
- Fix usb power supply to align with downstream power tree
- Control vdd_hdmi with gpio pa6 and delete unused vdd_hub_3v3 to avoid
  conflicts
- Link to v1: https://lore.kernel.org/r/20250608-p3452-v1-0-4c2c1d7e4310@gmail.com

---
Aaron Kling (2):
      dt-bindings: arm: tegra: Document Jetson Nano Devkits
      arm64: tegra: Add NVIDIA Jetson Nano 2GB Developer Kit support

 Documentation/devicetree/bindings/arm/tegra.yaml   |  5 ++
 arch/arm64/boot/dts/nvidia/Makefile                |  2 +
 arch/arm64/boot/dts/nvidia/tegra210-p3541-0000.dts | 59 ++++++++++++++++++++++
 3 files changed, 66 insertions(+)
---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20250513-p3452-059708ca9993

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

