From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v2 0/2] phy: tegra: xusb: Default otg mode to peripheral
Date: Tue, 06 May 2025 12:09:16 -0500
Message-Id: <20250506-xusb-peripheral-v2-0-bfbe00671389@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADxCGmgC/3WNyw7CIBBFf6WZtWMKpSpd+R+mC0Aok/RBQElN0
 38Xu3d5bnLO3SDZSDZBV20QbaZEy1yAnyowXs2DRXoWBl7ztha1wPWdNIYiBW+jGtGIVrNLc3V
 No6FYIVpH61F89IU9pdcSP8dBZr/1fyszZCilYTehpXatuw+TovFslgn6fd+/RSnzeq4AAAA=
X-Change-ID: 20250404-xusb-peripheral-c45b1637f33b
To: JC Kuo <jckuo@nvidia.com>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-phy@lists.infradead.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746551373; l=1076;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=FNA2gsRQTdJsloAcS3RRSgVH0l+51ZiDBDeK6njOiz8=;
 b=+Y2xZC3OosSjaAuY4rTFVw/J7gz3zpQ3FqXfBcXxUM2W6VcJmlJ40WuayQMLyyTmMC4TMJ8RA
 SWaNIMRmfzmDzYzt0EQkphgtJmhgwPVpVdguGVVDKbzt3j7q+lCQC2r
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v2:
- Add new patch to document role-switch-default-mode in xusb padctl
- Simplify code change, per review
- Comment in code why device mode is default
- Link to v1: https://lore.kernel.org/r/20250404-xusb-peripheral-v1-1-99c184b9bf5f@gmail.com

---
Aaron Kling (2):
      dt-bindings: phy: tegra-xusb: Document role-switch-default-mode
      phy: tegra: xusb: Default otg mode to peripheral

 .../bindings/phy/nvidia,tegra124-xusb-padctl.yaml  | 33 ++++++++++++++++++++
 .../bindings/phy/nvidia,tegra186-xusb-padctl.yaml  | 27 ++++++++++++++++
 .../bindings/phy/nvidia,tegra194-xusb-padctl.yaml  | 36 ++++++++++++++++++++++
 .../bindings/phy/nvidia,tegra210-xusb-padctl.yaml  | 36 ++++++++++++++++++++++
 drivers/phy/tegra/xusb.c                           | 11 +++----
 5 files changed, 136 insertions(+), 7 deletions(-)
---
base-commit: 91e5bfe317d8f8471fbaa3e70cf66cae1314a516
change-id: 20250404-xusb-peripheral-c45b1637f33b

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

