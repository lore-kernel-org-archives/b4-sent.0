From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH 0/2] watchdog: sp805: add reset control support
Date: Sat, 17 Feb 2024 12:40:33 +0800
Message-Id: <20240217-hisi-wdt-v1-0-cdb9ddcab968@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAME40GUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDI0Nz3QygEt3ylBJd4yRTI0tzw0QzU0tDJaDygqLUtMwKsFHRsbW1AAF
 SbwlaAAAA
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Viresh Kumar <vireshk@kernel.org>
Cc: linux-watchdog@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708144833; l=590;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=LUJDC/VfEayPO/LNjl7p0MlBSOcC2kOdKtdoDYyCuiY=;
 b=0rqqZcArxThG2yX3Hq+rdGLGQsJvuKSoEyteZdrJRyKY14vkNn89yYUJ5TWBgd/TfYi+SFcIs
 JTK/0/6wGJmCEg6DdJ/6ICqR6ZfE6wCIjivmGUiPNshX7xFWzwOt3oX
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Deassert the reset if it's available.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Yang Xiwen (2):
      watchdog: sp805_wdt: deassert the reset if available
      dt-binding: watchdog: arm,sp805: document the reset signal

 Documentation/devicetree/bindings/watchdog/arm,sp805.yaml | 6 ++++++
 drivers/watchdog/sp805_wdt.c                              | 9 +++++++++
 2 files changed, 15 insertions(+)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240217-hisi-wdt-3b52971a6591

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

