From: Rudraksha Gupta <guptarud@gmail.com>
Subject: [PATCH v2 0/3] Samsung Expressatt: Camera Flash
Date: Wed, 18 Mar 2026 11:34:38 -0700
Message-Id: <20260318-expressatt_camera_flash-v2-0-5c2b9a623dcb@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD7wumkC/4WP3WrDMAxGXyXoei6284fDGH2PUoriyI1Z3Wy2G
 1pK3n1KerHdDV0dIX2H7wmJoqcEXfGESLNPfroy6LcC7IjXMwk/MIOWupGlbATdvyKlhDmfLAa
 KeHIXTKNQpVU1tpVuEYG/+cr5+5Z8OL440veNBfm1hLDGbIKueOf8WmlZ/8kXebrZ8ZMeYlaCp
 6qq3ujWGlfuzwH9ZWen8LG6ekwkGILPXTE3O2VgVY4+5Sk+tm6z2pz/1mCVFL0ypnGtHdww/Kr
 guCzLD5MPNYQxAQAA
X-Change-ID: 20260306-expressatt_camera_flash-13c15a7427aa
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>
Cc: linux-leds@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773858880; l=1698;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=x3uy/XVTTVpT34PL1AIrqtdEtkXWeZVq3ulfI+0NZ8A=;
 b=QvHgY2nmD9UpmbOnF8ObSGoxhgUjgf5v/0kQd55EVTgeJq8lozWe7pBmpUdomdOqb32TAR1HG
 /PzAtPxvM+bCXaGiKdY0cHR7goegmv+dITjwBJ8kTduQVEB+/ppING+
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This small series adds camera flash to an existing similar mainline
driver and adds it the the Samsung Expressatt's DTS

Assisted by AI (Claude).

Downstream reference:
Link: https://github.com/LineageOS/android_kernel_samsung_d2/blob/stable/cm-12.0-YNG4N/drivers/leds/Makefile#L51
Link: https://github.com/LineageOS/android_kernel_samsung_d2/blob/stable/cm-12.0-YNG4N/arch/arm/mach-msm/board-apexq-camera.c#L591

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
Changes in v2:
- dt-bindings: Explain the hardware and not the driver
- **/*: Use vin-supply instead of unlock-gpio
- expressatt DTS: Reorder pinctrl-*
- expressatt DTS: Define rfs-ohms to a default (couldn't find
                  information about this)
- Link to v1: https://lore.kernel.org/r/20260306-expressatt_camera_flash-v1-0-b1996f7cdfdd@gmail.com

---
Rudraksha Gupta (3):
      dt-bindings: leds: rt8515: Support single-GPIO flash ICs with vin supply
      leds: flash: rt8515: Support single-GPIO flash ICs with vin supply
      ARM: dts: qcom: msm8960: expressatt: Add camera flash

 .../devicetree/bindings/leds/richtek,rt8515.yaml   | 34 +++++++++++-
 .../dts/qcom/qcom-msm8960-samsung-expressatt.dts   | 43 +++++++++++++++
 drivers/leds/flash/leds-rt8515.c                   | 64 +++++++++++++++++++---
 3 files changed, 132 insertions(+), 9 deletions(-)
---
base-commit: e9ec05addd1a067fc7cb218f20ecdc1b1b0898c0
change-id: 20260306-expressatt_camera_flash-13c15a7427aa
prerequisite-message-id: <20251205-expressatt-touchkey-v1-1-1444b927c9f3@gmail.com>
prerequisite-patch-id: 8de4de7909722ccaf385c4224f25a623eaa72c28

Best regards,
-- 
Rudraksha Gupta <guptarud@gmail.com>

