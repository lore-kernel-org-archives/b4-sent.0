From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 0/8] Add OnePlus 6T display (Samsung S6E3FC2X01 DDIC
 with AMS641RW panel)
Date: Thu, 16 Oct 2025 18:16:55 +0200
Message-Id: <20251016-s6e3fc2x01-v3-0-ce0f3566b903@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHca8WgC/1XMyw6CMBCF4VcxXVsznabQuvI9jAssU5kNmJY0K
 OHdLSTeluck/zeLRJEpieNuFpEyJx76MvR+J3zX9DeS3JYtENCAQy1TRTp4nEDJ4IyBq0UMZEQ
 J7pECTxt2vpTdcRqH+NjsrNb3zZhfJisJ0qHToKq6sqE+8cTjwT/FimT8hArA/oVYQlTkG9Uaj
 9Z9w2VZXr1PJaTbAAAA
X-Change-ID: 20250923-s6e3fc2x01-f9550b822fe5
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3365; i=david@ixit.cz;
 h=from:subject:message-id; bh=zvd05p0ExbkaGmxBTuCfy3Mb9KA9l3VBNuCLsOtci1I=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo8Rp5WmQMaKk6HyPBsIVaXQcl59yziiTdiMgfM
 CQlZwALQ9eJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaPEaeQAKCRBgAj/E00kg
 crbXEACZWdPmxPaRBqbdU1NfmbFxDrwwcfrqGw+tPoZoYv/LmbZo4wY0pQ0/uWv9RovOaAZOUMM
 Hx+M/InPH2G0cD3x9bgVnhuNIM8vVyyurpHUBvcQtwfJMgXisU+E2vYQgdybvbhwAtZ2UvAfjUP
 EM6EL3bg1364NftAT34swngxGt8A6QgP1pv5xPFBJDTflzuVu9ZBYYVKE54HAdtkHzhMk3DAYjt
 FN++37tWQ2fShAMbXJCCFGxLpOoZOySHH6w7nZk6IGfy/94gxjyvJ5PR/kRrhi0zU0GyGYFBGl4
 P+813tE5f1hSgcszBgsMY9nBYbjLQyyqsv6Jdd68H7lhYdA2mhoo05nlUWvQx16yJSkhH8/Zgaf
 mpazc1rqISzlkPdBOSy/8+ODbQOWuXeEEhNO3GHff/noXDXmCZFvXGl/kv8iihHfOgJrh+TOsxz
 A4FgLNOuLiseUI7JlfQRTYwCEUDEluWnewfoMj1DQbeH3HMvgg+fQ4C5soNmKfRXzakz1J3LwfK
 CquoJ4AjAFQyasjbPdCxbJWKIj/tjVrOw30mUHQiaMTOZXK0LWZdNJ7UCipL9AwTZF3bIPZB9cn
 RfBsJmQ0PMmA3Sk+X3XHHg3UxVIKbbR8lJhcS47WeHtUfOo7kKJfGkfhjiUnNi0nCPoeFuDN/SF
 Dqd0PCX7jUo90SQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

First, proper bindings for the DDIC and panel are added.

Next, the VCI and POC supplies are introduced for the OnePlus 6 and 6T
phones, and the OnePlus 6T device tree is extended with more precise
compatible string.

Finally, a new DDIC driver is introduced along with the AMS641RW panel
initialization sequences.

This patchset enables the display on the OnePlus 6T smartphone.

Since the display node is shared between the OnePlus 6 and 6T,
the following warning appears:

..sdm845-oneplus-enchilada.dtb: panel@0 (samsung,sofef00): 'poc-supply', 'te-gpios', 'vci-supply' do not match any of the regexes: '^pinctrl-[0-9]+$'

This will be addressed in a follow-up patch, as the SOFEF00 DDIC also
requires additional overhaul to properly initialize and function in mainline.

Last two patches are not needed for panel to work, it's up to maintainer
decision to merge them with the series or not.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v3:
- Use mipi_dsi_dcs_set_display_brightness_large (Konrad)
- added legacy compatible samsung,s6e3fc2x01 into the driver (Dmitry)
- extended compatible string to
  "samsung,s6e3fc2x01-ams641rw", "samsung,s6e3fc2x01" (Dmitry)
- Brought back
  "dt-bindings: display: panel-simple-dsi: Remove Samsung S6E3FC2 compatible"
- Link to v2: https://lore.kernel.org/r/20251008-s6e3fc2x01-v2-0-21eca1d5c289@ixit.cz

Changes in v2:
- Dropped the gpio reset polarity change as suggested (Jens and Dmitry).
- Fixed unused warnings (kernel test robot).
- Added a pinctrl config for the VCI and POC supply.
- Removed patch "dt-bindings: display: panel-simple-dsi: Remove Samsung S6E3FC2 compatible"
  while the compatible is used in device-tree, but without any driver
  serving it, do not touch it (Rob)
- Added more details into the device-tree about the OnePlus 6T panel properties
- Put display gpio -pins into one -state block.
- Link to v1: https://lore.kernel.org/r/20250925-s6e3fc2x01-v1-0-9293016768f7@ixit.cz

---
Casey Connolly (1):
      arm64: dts: qcom: sdm845-oneplus: Describe panel vci and poc supplies

David Heidelberg (7):
      dt-bindings: panel: Add Samsung S6E3FC2X01 DDIC with panel
      arm64: dts: qcom: sdm845-oneplus-fajita: Compatible describing both DDIC and panel
      drm/panel: Add Samsung S6E3FC2X01 DDIC with AMS641RW panel
      arm64: dts: qcom: sdm845-oneplus: Group panel pinctrl
      arm64: dts: qcom: sdm845-oneplus: Implement panel sleep pinctrl
      arm64: dts: qcom: sdm845-oneplus: Describe TE gpio
      dt-bindings: display: panel-simple-dsi: Remove Samsung S6E3FC2 compatible

 .../bindings/display/panel/panel-simple-dsi.yaml   |   2 -
 .../bindings/display/panel/samsung,s6e3fc2x01.yaml |  81 +++++
 MAINTAINERS                                        |   6 +
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 113 ++++--
 arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts |   2 +-
 drivers/gpu/drm/panel/Kconfig                      |  13 +
 drivers/gpu/drm/panel/Makefile                     |   1 +
 drivers/gpu/drm/panel/panel-samsung-s6e3fc2x01.c   | 399 +++++++++++++++++++++
 8 files changed, 593 insertions(+), 24 deletions(-)
---
base-commit: 2433b84761658ef123ae683508bc461b07c5b0f0
change-id: 20250923-s6e3fc2x01-f9550b822fe5

Best regards,
-- 
David Heidelberg <david@ixit.cz>

