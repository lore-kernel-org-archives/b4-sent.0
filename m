From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v3 0/2] thermal: Add support A9
Date: Fri, 21 Aug 2026 07:50:21 +0000
Message-Id: <20260821-a9-thermal-v3-0-0e7abf3941e3@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD4DiGoC/1XMSwqDMBSF4a3IHTclD5poR91H6SAmNxpQUxIJL
 eLeG6XQOjwH/m+BhNFjgmu1QMTskw9TGeJUgen11CHxtmzglEuqqCC6IXOPcdQDcZIbdBJ1wxy
 U4BnR+deO3R9l9z7NIb53O7Pt/TKC/jOZEUqsqqUVyrT6Ut/0OITOm7MJI2xQ5r+4ZuwQ8xIra
 40QLWNto4/xuq4f4VU40OMAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787298628; l=1423;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=tR0AdX527Cmy9X8GHIcvSa9gZoHO6qvprjxgfmzKfO0=;
 b=8ssSs355jJ34Webn2x+NSp0s1xQgKrk1IrbDHbvXVqIKRtJgeGNrU+eIAwI8R8RoAdog8xHef
 aOd91L1si2ACJJaGP7Z92n2jHeetsTwYG8Wn1kUVdU8pNHHrKnZAtmP
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the thermal controller compatibles for the Amlogic A9 SoC
And add driver support for the Amlogic A9 thermal controller.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
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

