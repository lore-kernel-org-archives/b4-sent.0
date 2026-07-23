From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v3 0/2] soc/tegra: pmc: Add Tegra210B01 support
Date: Wed, 22 Jul 2026 21:46:46 -0500
Message-Id: <20260722-t210b01-pmc-v3-0-1c5b970788f2@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1XM3QqDIBjG8VsJj+d4X610He0+xg7UaQnrAw3Zi
 O59Fgzq8Hng/1tItMHbSJpiIcEmH/045MEvBTGdGlpL/StvwoDVIJDTmSFoQDr1hqLiTuobSCh
 LkospWOc/u/Z45t35OI/hu+MJt/fviJOTkALVTohaW6m5Eve2V/59NWNPNiexQ8vg3LLcGlVxF
 E5WIPSxXdf1B33zmgfiAAAA
X-Change-ID: 20260713-t210b01-pmc-1a3f8b908044
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Thierry Reding <thierry.reding@gmail.com>, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>, 
 Thomas Makin <halorocker89@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784774814; l=1204;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=faEjHf4ruDkkziyomMoGKUTC/VdZjUyAg1H//yKJt/8=;
 b=gPAI8vl5OhnxdH0mKvveELbLTZtnhGVkqkRSQjswIYy2HKQ+RjIrDOyLRkbGf95sf6iRuZ3Wm
 s9IC82kdxzSA18UNzfk2Z0Nx89atls8aakSgXMKnhBDelQsLYyjM0Zx
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the Tegra210B01 SoC to the Tegra PMC driver
and documents the new compatible.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
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
 drivers/soc/tegra/pmc.c                            | 61 ++++++++++++++++++++++
 2 files changed, 65 insertions(+), 1 deletion(-)
---
base-commit: 1a1757b76427f6201bfe0bf1bea9f7574f332a93
change-id: 20260713-t210b01-pmc-1a3f8b908044

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

