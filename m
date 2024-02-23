From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH 0/2] simple-pm-bus: deassert resets if possible
Date: Fri, 23 Feb 2024 11:49:45 +0800
Message-Id: <20240223-b4-bus-v1-0-2803c3ac4673@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANkV2GUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDIyNj3SQT3aTSYt0U02SzNHPTRCNTw0QloOKCotS0zAqwQdGxtbUAock
 28lgAAAA=
To: Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Geert Uytterhoeven <geert+renesas@glider.be>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708660187; l=658;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=FABj5PqTYhnM786LMrFtQ0eBls3CUT1p0QbNHPCEQCs=;
 b=lAjMgm0upwe5GNEV4wO9MDqjNe+0Gto1rn6DLXSaTmlZoFGjD2+RXTGbL9uwWw6+3sir5+WNP
 tQQ29dl5Rw1AQ8/E5UGsm02f5c26NWy06kxgA0nYOhW9ArEmiBAfR67
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

simple power-managed buses can also have resets. Get and deassert them
if possible.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Yang Xiwen (2):
      dt-bindings: simple-pm-bus: Add optional resets
      drivers: bus: simple-pm-bus: Get and deassert resets exclusively

 Documentation/devicetree/bindings/bus/simple-pm-bus.yaml |  7 +++++--
 drivers/bus/simple-pm-bus.c                              | 14 +++++++++++++-
 2 files changed, 18 insertions(+), 3 deletions(-)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240223-b4-bus-d5c6f75a251a

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

