From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/2] thermal: Add support A9
Date: Thu, 30 Jul 2026 08:34:36 +0000
Message-Id: <20260730-a9-thermal-v1-0-d786d37cba58@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJwMa2oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDcwNj3URL3ZKM1KLcxBzdNDOj5NQ0s9RES8M0JaCGgqLUtMwKsGHRsbW
 1ANm31zhcAAAA
X-Change-ID: 20260703-a9-thermal-f62cef6ea91f
To: Guillaume La Roque <glaroque@baylibre.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785400497; l=708;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=tqNNorQu+sVU/SRTxPnEuAnWC1OAYWnTv5IKxYETbdY=;
 b=zfcjrasq1supGoSg8xxlaLxkPsPhAg/bR6pml9gzIrTqZuvFw1bGiE3hGpkiOHwRZuJEqkqFY
 UMM2Yhe1IteCihCIk7+PgVcD/7XLZzozJiCoS4DBbFXurW2AQk5ESr6
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the thermal controller compatibles for the Amlogic A9 SoC
And add driver support for the Amlogic A9 thermal controller.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (2):
      dt-bindings: thermal: amlogic: Add A9 thermal bindings
      thermal: amlogic: Add support for A9 thermal controller

 .../bindings/thermal/amlogic,thermal.yaml          |  29 +++++-
 drivers/thermal/amlogic_thermal.c                  | 107 ++++++++++++++++++++-
 2 files changed, 132 insertions(+), 4 deletions(-)
---
base-commit: 78bc8af4affb9a732504eb22eeac7d1e50883853
change-id: 20260703-a9-thermal-f62cef6ea91f

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

