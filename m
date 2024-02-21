From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v3 0/2] watchdog: sp805: add reset control support
Date: Wed, 21 Feb 2024 19:56:40 +0800
Message-Id: <20240221-hisi-wdt-v3-0-9642613dc2e6@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPjk1WUC/22Myw6CMBBFf4XM2pp2gGJd+R/GBX0ojUpNwaoh/
 XcHVpi4PDf3nAkGF70bYF9MEF3ygw89QbkpwHRtf3HMW2JAjhVH0bCOLuxlR1bqGlUjWlkrAXR
 /RHf27yV1PBHTcQzxs5STmNc/kSQYZ8ZqZa1ptZK7Q3iOtxCuWxPuMGcSrlTkKxVJlaWzplKy1
 pX5VXPOX5MVvqLdAAAA
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Viresh Kumar <vireshk@kernel.org>
Cc: linux-watchdog@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708516604; l=1002;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=cVP9oDcFqMe3HIWN3U9hzMH6sEfnqnfkj+cc6SDEDc4=;
 b=OF1L8JvpFPNieb8IzziAiUU/l2TgBSIHHY+WX5+VPGsxwuQ2zJ3cXaqgEPm4geb0nX4u3ynVi
 fvcIG6wx3DsBTZvCcsahf5yDbT2cOVcM3vy/2s2uhVx+JEZZbpepCnb
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Deassert the reset if it's available.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v3:
- move reset to local variable, get reset exclusively (Philipp Zabel)
- Link to v2: https://lore.kernel.org/r/20240220-hisi-wdt-v2-0-63edc4965b4c@outlook.com

Changes in v2:
- commit log: dt-binding->dt-bindings (Krzysztof Kozlowski)
- binding: remove "|", join two lines. (Krzysztof Kozlowski)
- Link to v1: https://lore.kernel.org/r/20240217-hisi-wdt-v1-0-cdb9ddcab968@outlook.com

---
Yang Xiwen (2):
      watchdog: sp805_wdt: deassert the reset if available
      dt-bindings: watchdog: arm,sp805: document the reset signal

 Documentation/devicetree/bindings/watchdog/arm,sp805.yaml | 5 +++++
 drivers/watchdog/sp805_wdt.c                              | 8 ++++++++
 2 files changed, 13 insertions(+)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240217-hisi-wdt-3b52971a6591

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

