From: Alexandre Messier <alex@me.ssier.org>
Subject: [PATCH v2 0/4] Describe more hardware of the HTC One (M8)
Date: Mon, 06 Apr 2026 01:16:56 -0400
Message-Id: <20260406-m8-dts-additions-v2-0-c4c4bd50af48@me.ssier.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMhB02kC/32NMQ6DMAxFr4I8NygJIEqn3qNiSIkBD0Blo6gVy
 t3rcoBufv7fzwcIMqHArTiAMZHQtir4SwHDHNYJDUVl8NY3ztrWLFcTdzEhRtq1q9OgWefCGHw
 NevZiHOl9Kh+98kyyb/w5PyT32/6RJWesaarYhmfVdDW29wVLEUIuN56gzzl/AfqKz4izAAAA
X-Change-ID: 20251007-m8-dts-additions-ac20291afa24
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Luca Weiss <luca@lucaweiss.eu>, linux-arm-kernel@lists.infradead.org, 
 linux-arm-msm@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Alexandre Messier <alex@me.ssier.org>, 
 Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 linux-leds@vger.kernel.org, Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775452618; l=1221;
 i=alex@me.ssier.org; s=20240603; h=from:subject:message-id;
 bh=Mgy1duuWt0vR+mviueizCgI5vS8MuDmlLDbmB0xbpMk=;
 b=3Tt0iAZ6E7HTSlxgNIYL/SaG2UX02aKjPrgvG5Vsw6RtmW2qn6Lj9foVwxIs2s4rY7huMh71e
 27OECyK4cxNBxK3B+fvfm1ZVQ0JhBS9e58EuwJbHEOEtT+wOjrGpKJX
X-Developer-Key: i=alex@me.ssier.org; a=ed25519;
 pk=JjRqVfLd2XLHX2QTylKoROw346/1LOyZJX0q6cfnrKw=
X-Endpoint-Received: by B4 Relay for alex@me.ssier.org/20240603 with auth_id=168
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add hardware description for these parts of the HTC One (M8):

 - Notification LEDs
 - Bluetooth
 - NFC
 - Touchscreen

Signed-off-by: Alexandre Messier <alex@me.ssier.org>
---
Changes in v2:
- Rebased on top of 7.0-rc6
- In patch 1, change color of one LED from amber to orange.
- In patch 1, use a multicolor LED to represent the logical grouping
  of the LEDs.
- In patches 2 and 4, note in the commit message the usage of same
  I2C bus frequency as the downstream kernel.
- In patch 3, gather Reviewed-by tag from Konrad Dybcio.
- Link to v1: https://lore.kernel.org/r/20251007-m8-dts-additions-v1-0-53d7ab3594e7@me.ssier.org

---
Alexandre Messier (4):
      ARM: dts: qcom: msm8974pro-htc-m8: add status LEDs
      ARM: dts: qcom: msm8974pro-htc-m8: add NFC support
      ARM: dts: qcom: msm8974pro-htc-m8: add Bluetooth pins
      ARM: dts: qcom: msm8974pro-htc-m8: add touchscreen

 arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts | 94 ++++++++++++++++++++++-
 1 file changed, 90 insertions(+), 4 deletions(-)
---
base-commit: 7aaa8047eafd0bd628065b15757d9b48c5f9c07d
change-id: 20251007-m8-dts-additions-ac20291afa24

Best regards,
-- 
Alexandre Messier <alex@me.ssier.org>

