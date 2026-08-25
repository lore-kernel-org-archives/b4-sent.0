From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v4 0/2] thermal: Add support A9
Date: Tue, 25 Aug 2026 06:28:28 +0000
Message-Id: <20260825-a9-thermal-v4-0-d8fc9859cf22@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAw2jWoC/2XMSwqDMBSF4a1Ixk1Jcq0xHXUfpYM8bjTgo0SRF
 nHvjVKo0uE58P0zGTAGHMg1m0nEKQyh79LITxmxte4qpMGlTQQTBZMMqFZ0rDG2uqG+EBZ9gVp
 xTxJ4RvThtcXuj7TrMIx9fG/tia/vNwNsn5k4ZdTJsnAgrdGX8qbbpq+CPdu+JWtoEj9ccn7AI
 mHpnAUwnBul/zHssDhiSJih1MaDyjnCES/L8gEOipaQIAEAAA==
X-Change-ID: 20260703-a9-thermal-f62cef6ea91f
To: Guillaume La Roque <glaroque@baylibre.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787639310; l=1596;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=wtn1I+ai2TfN4YtsNfLA2KMBghSMbAH01BL0yp3zDvE=;
 b=F5+QWQZl4PmucrgygUs+YLg5rrOp+WvqSGZix8VgOu8ehFtrOeF6XCsABxyDJUapkpv9En1pg
 jN30zNiglk+CB37pANMJqMad75efyfP4iaHscftoGikgpJgMXZ6x1b8
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the thermal controller compatibles for the Amlogic A9 SoC
And add driver support for the Amlogic A9 thermal controller.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v4:
- Fix type error in comit mesage, and set factor valid value. 
- Link to v3: https://lore.kernel.org/r/20260821-a9-thermal-v3-0-0e7abf3941e3@amlogic.com

Changes in v3:
- Binding: add restrictive conditions for clock, and remove remove "amlogic,hw-reset-temp" property.
- Driver: add private data reset_temp instead of get value from DTS.
- Link to v2: https://lore.kernel.org/r/20260811-a9-thermal-v2-0-7ddc33b11b9a@amlogic.com

Changes in v2:
- Fix the spelling mistakes (clock-names) and reset-temp properties is visible to old chips.
- Adjust the clock enable sequence in resume func and remove the clock disable in remove func.
- Add the judgment on the divisor zero.
- Add description of support for over-temperature reset for old chips in commit message.
- Link to v1: https://lore.kernel.org/r/20260730-a9-thermal-v1-0-d786d37cba58@amlogic.com

---
Xianwei Zhao (2):
      dt-bindings: thermal: amlogic: Add A9 thermal bindings
      thermal: amlogic: Add support for A9 thermal controller

 .../bindings/thermal/amlogic,thermal.yaml          |  27 ++++-
 drivers/thermal/amlogic_thermal.c                  | 113 ++++++++++++++++++++-
 2 files changed, 136 insertions(+), 4 deletions(-)
---
base-commit: 78bc8af4affb9a732504eb22eeac7d1e50883853
change-id: 20260703-a9-thermal-f62cef6ea91f

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

