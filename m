From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v4 0/2] soc/tegra: pmc: Add Tegra210B01 support
Date: Mon, 27 Jul 2026 21:00:09 -0500
Message-Id: <20260727-t210b01-pmc-v4-0-af68a21cd746@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/13MSwrDIBSF4a0Ux7VcNck1HXUfpQO1mgjNAw3SE
 rL3mkAh6fAc+P6ZRBu8jeR6mkmwyUc/9HkU5xMxreobS/0zb8KBV4BM0Ikz0MDo2BnKlHBS1yC
 hKEgWY7DOv7fa/ZF36+M0hM8WT2x9fx08dBKjQLVDrLSVWii8NZ3yr4sZOrJ2Et9ZDkfLszWqF
 AydLAH1vxV7y49WZMtMqWsElNLxvV2W5QslZc9KHgEAAA==
X-Change-ID: 20260713-t210b01-pmc-1a3f8b908044
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Thierry Reding <thierry.reding@gmail.com>, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>, 
 Thomas Makin <halorocker89@gmail.com>, 
 Mikko Perttunen <mperttunen@nvidia.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785204012; l=1353;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=tXSaf6D+4oT/tivF4Swhyqm9z9vxCocGJRBBgGLQTGY=;
 b=AH/OGdp3UY0CYqiLuqD6MN6kK/40jUp7poCfRHz0xzfIcsKLLPjuE1iujCHpMsJLMi+LuIQOV
 AgVrQrEvr/sDmoed7WZE4BnJOxpjmWBwaHlzmoI8y5UXcHJnY+67Yny
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the Tegra210B01 SoC to the Tegra PMC driver
and documents the new compatible.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v4:
- Add venc to powergate list in patch 2
- Link to v3: https://lore.kernel.org/r/20260722-t210b01-pmc-v3-0-1c5b970788f2@gmail.com

Changes in v3:
- Update patch 2 commit author and sign-off tag as requested off list by
  author
- Update patch 2 commit message to describe the powergate differences
  compared to t210
- Drop sata powergate in patch 2
- Fix has_io_pad_wren value in patch 2
- Link to v2: https://lore.kernel.org/r/20260720-t210b01-pmc-v2-0-ca5317f8507b@gmail.com

Changes in v2:
- Address sashiko report and drop duplicated structs
- Link to v1: https://lore.kernel.org/r/20260717-t210b01-pmc-v1-0-bf776be8b3a7@gmail.com

---
Aaron Kling (1):
      dt-bindings: soc: tegra: pmc: Document Tegra210B01

Alexandre Hamamdjian (1):
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

