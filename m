From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/4] Add support for Amlogic S6/S7/S7D Reset
Date: Tue, 23 Dec 2025 05:37:08 +0000
Message-Id: <20251223-reset-s6-s7-s7d-v2-0-958f341449f1@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIQqSmkC/2WNwQrCMBBEf6Xs2ZUkUtN48j+kh9hs2wXbSLYUp
 eTfjQVPwlzewLzZQCgxCVyqDRKtLBznAuZQQTf6eSDkUBiMMrXWpsZEQgvKGcWWBDRa9842JvT
 +DmX1TNTzazfe2sIjyxLTez9Y9bf9ueyfa9WosLFOOeeDU+F09dMjDtwduzhBm3P+APAZsOewA
 AAA
X-Change-ID: 20251125-reset-s6-s7-s7d-211f9782dfab
To: Philipp Zabel <p.zabel@pengutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766468230; l=1263;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=TopfHx7R+NfEkqLUaU8SHkHIJkgRVh3DScg2mMFNmUQ=;
 b=WI3MBDEAUmJoam63ErKvMPGdx1iWdVinT1IT/wRrj443CU3LFtAcSvfZ8WO4itFicCvXRq2JY
 8FGgbqNHf7bCUg+CgnCe8qSHD22kEnBZ7Xp4LEgNhIRZuR6VLL+NiD1
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add dt-binding compatibles and device nodes for Amlogic S6/S7/S7D reset.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v2:
- Fix some macro definition names, MAIL to MALI, PIPEL to PIPE, PIPL to PIPE.
- Link to v1: https://lore.kernel.org/r/20251127-reset-s6-s7-s7d-v1-0-879099ad90d3@amlogic.com

---
Xianwei Zhao (4):
      dt-bindings: reset: Add compatible for Amlogic S6/S7/S7D
      arm64: dts: amlogic: Add S6 Reset Controller
      arm64: dts: amlogic: Add S7 Reset Controller
      arm64: dts: amlogic: Add S7D Reset Controller

 .../bindings/reset/amlogic,meson-reset.yaml        |   3 +
 arch/arm64/boot/dts/amlogic/amlogic-s6-reset.h     | 171 +++++++++++++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-s6.dtsi        |   8 +
 arch/arm64/boot/dts/amlogic/amlogic-s7-reset.h     | 124 +++++++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-s7.dtsi        |   8 +
 arch/arm64/boot/dts/amlogic/amlogic-s7d-reset.h    | 134 ++++++++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-s7d.dtsi       |   8 +
 7 files changed, 456 insertions(+)
---
base-commit: 79482f3791c4760b9b0d8d9bfde9f1053ea3dd5e
change-id: 20251125-reset-s6-s7-s7d-211f9782dfab

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

