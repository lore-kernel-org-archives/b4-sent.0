From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v2 0/2] soc/tegra: pmc: Add Tegra210B01 support
Date: Mon, 20 Jul 2026 01:31:14 -0500
Message-Id: <20260720-t210b01-pmc-v2-0-ca5317f8507b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1XMywrCMBCF4VcpszYySUpTXfke0kUSp+2AvZCUo
 JS8u7HgwuV/4Hw7RApMEa7VDoESR17mEupUgR/tPJDgR2lQqBo0UotNSXQoxTp5Ia3uW3fBFus
 aymMN1PPr0O5d6ZHjtoT3gSf5XX+O+XOSFChcb0zjqHXamtswWX6e/TJBl3P+AAITFjWmAAAA
X-Change-ID: 20260713-t210b01-pmc-1a3f8b908044
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Thierry Reding <thierry.reding@gmail.com>, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>, Azkali Manad <a.ffcc7@gmail.com>, 
 Thomas Makin <halorocker89@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784529079; l=839;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=RbA0CGgTm2dPyexj3MuGmmYeAx3UJ3Q2g4NEHT98CMI=;
 b=lAgndM4mFFZanRZ404++Hwgv23HpqhOvVx2DjVBkSK8zl3PqTC14qdJhqzRgeaHRIAMVLAGj5
 VERRe8azdtVBrN/rMUOUrFJEMH1qfI4IU7KbK9Zf0E0Db/4ypIopkEb
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the Tegra210B01 SoC to the Tegra PMC driver
and documents the new compatible.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v2:
- Address sashiko report and drop duplicated structs
- Link to v1: https://lore.kernel.org/r/20260717-t210b01-pmc-v1-0-bf776be8b3a7@gmail.com

---
Aaron Kling (1):
      dt-bindings: soc: tegra: pmc: Document Tegra210B01

Azkali Manad (1):
      soc/tegra: pmc: Add Tegra210B01 support

 .../bindings/soc/tegra/nvidia,tegra20-pmc.yaml     |  5 +-
 drivers/soc/tegra/pmc.c                            | 62 ++++++++++++++++++++++
 2 files changed, 66 insertions(+), 1 deletion(-)
---
base-commit: 1a1757b76427f6201bfe0bf1bea9f7574f332a93
change-id: 20260713-t210b01-pmc-1a3f8b908044

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

