From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/2] soc/tegra: pmc: Add Tegra210B01 support
Date: Fri, 17 Jul 2026 19:17:01 -0500
Message-Id: <20260717-t210b01-pmc-v1-0-bf776be8b3a7@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDc0Nj3RIjQ4MkA0PdgtxkXcNE4zSLJEsDCwMTEyWgjoKi1LTMCrBp0bG
 1tQA0+aqjXQAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784333826; l=674;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=idEUgIvEhKFyitcr4yu2xO7SOnzf9HxwpzJ6GhZjMT0=;
 b=IZk2RGK2ULeVK0wkVXw9gWWJ1MJImxmvzIUBjTKGOFhUOcdTKJoEalHZgoWb5sWKZF85dpRC6
 2RlNBAouNlwBR5r0vO8hMJoOF7Ilbb+64ePl3U6pmrYv12CxtyaJgcu
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the Tegra210B01 SoC to the Tegra PMC driver
and documents the new compatible.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Aaron Kling (1):
      dt-bindings: soc: tegra: pmc: Document Tegra210B01

Azkali Manad (1):
      soc/tegra: pmc: Add Tegra210B01 support

 .../bindings/soc/tegra/nvidia,tegra20-pmc.yaml     |   5 +-
 drivers/soc/tegra/pmc.c                            | 160 +++++++++++++++++++++
 2 files changed, 164 insertions(+), 1 deletion(-)
---
base-commit: 1a1757b76427f6201bfe0bf1bea9f7574f332a93
change-id: 20260713-t210b01-pmc-1a3f8b908044

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

