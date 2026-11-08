From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 00/10] Pixel 3 XL display panel support
Date: Sun, 08 Nov 2026 12:32:21 +0000
Message-Id: <20261108-crosshatch-panel-v3-0-87dd4ec4f7cc@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NQQ7CIBQFr2JYiwG0tLjyHsYFhY9gTNsAkmrTu
 wvtQhNdTvJm3oQCeAcBHTcT8pBccH2XYb/dIGVldwXsdGbECOOkIRQr34dgZVQWD7KDOyZcQSO
 5MG1tUNYGD8aNS/J8WTk82huoWDplYV2IvX8un4mW3ZoXjPzmE8UEa+AgKsq0FPzkRhd36oVKP
 LFv/fBHZ1knja5U3ZqaGfXR53l+Az9P2bP/AAAA
X-Change-ID: 20260801-crosshatch-panel-06ce8a69fb7f
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Petr Vorel <petr.vorel@gmail.com>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2412; i=david@ixit.cz;
 h=from:subject:message-id; bh=tSNDj9ymd4uYRUtBQHQkxmD4lJDASY/5ynNPCLRIiEc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq8GvdnBVMxF6dVYBg04KasocW7b688c6Q1Z7Ac
 SqHVoGejyeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCavBr3QAKCRBgAj/E00kg
 cuw+D/0Sbmtnsb/VzdAqegSnnaK53qakB/RaFB0UcpvX6DlP3yFMUkNM8iEQUkgjFhIjE7ZMYXs
 URqQI2C5vxRsQS3AvXLigIZF2txNuLrwA1w97NN5JQTg6gznbkg6irKg9vmQjd+Hjo52wOLjpeo
 lkosvMUEqAEJUe2csK5QrucpYLMx0kTzD96ECNEG6IvBXZ2luzKxqR2Hjdb5zuS9PfxXeN6QvFp
 0ff66Djt0FjwasesIIaqeM9zC6Dn5moZQI5ivzEVSEcWwo30+J+ss0rLdOilx94bfyOonHiIcMs
 782nx0mQ0Kfbe74rdeGTPsngs8HsDRg9w1HjCW6WPkge7JZLcxRLxvsTKoWRqMGKg/etWzKME0c
 KiCm8Ju2kPdTp+EFHKjHxNiFXL/CZOvQYyro66xznR0+geztQf4W3A9Vlj5pHYIEAYcKSurjg6t
 wLNs7Y+haJh7GkQtycjZ+O8RVu+xoiRwOKimf0zcE6h7NidCGReyDOoVMAZqYob5XmYQGpk+caD
 XUOVqlYfvhkWXjNjzwX8T1Lf1adnOUabQMh51uIwM6h7PSzWHqMU0btSjgLP9ZVJV7Lab84DdeJ
 wlhch6eSb0R6Lk7Jd54goxFaLmnfbxEKUljY0H6ijhERGJPGIApsQnDfDNKBgvX3Tea78RoudoB
 irE/8n65evHOMgg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce Samsung AMB630QY01 (Google Pixel 3 XL) panel.

Includes refactoring and improvements to the S6E3HA8 DDIC which is also
used by Samsung S9 (Korea version).

Patches 9 and 11 switch to the new compatibles, so they must not reach
the qcom tree before the driver patches land.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v3:
- Entire allOf goes after required: block. (Krzysztof)
- Expalin dt-bindings changes more explicitly. (Krzysztof)
- Dropped "Really assert reset on the failure" as requested by (Krzysztof)
- Not addressed: "No, this is wrong. You just broke all the users of
  this DTS.", due to non-existent usage outside of Linux and DTB for
  this device being shipped always together with the kernel.
- Link to v2: https://patch.msgid.link/20260924-crosshatch-panel-v2-0-08d5c7bf72fc@ixit.cz

Changes in v2:
- Rebase on top of next-20260923.
- Cosmetic fix s/Cosmtetic/Cosmetic/ fix in the commit msg. (Neil)
- Link to v1: https://patch.msgid.link/20260920-crosshatch-panel-v1-0-de6e9512da96@ixit.cz

---
David Heidelberg (10):
      dt-bindings: display: panel: s6e3ha8: Adjust to reflect the DDIC and panel used
      dt-bindings: display: panel: samsung,s6e3ha8: Add AMB630QY01 panel
      drm/panel: s6e3ha8: Introduce AMB577PX01 panel compatible
      drm/panel: s6e3ha8: Prepare for supporting multiple panels
      drm/panel: s6e3ha8: Correct the polarity logic within
      drm/panel: s6e3ha8: Assert reset GPIO in unprepare
      drm/panel: s6e3ha8: add Samsung AMB630QY01 (Google Pixel 3 XL) panel
      arm64: dts: qcom: sdm845-samsung-starqltechn: Update panel compatible
      arm64: dts: qcom: sdm845-google: Move panel pins into common
      arm64: dts: qcom: sdm845-google-crosshatch: Add display panel

 .../bindings/display/panel/samsung,s6e3ha8.yaml    |  56 +++-
 .../arm64/boot/dts/qcom/sdm845-google-blueline.dts |  18 --
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi |  16 ++
 .../boot/dts/qcom/sdm845-google-crosshatch.dts     |  60 +++-
 .../boot/dts/qcom/sdm845-samsung-starqltechn.dts   |   4 +-
 drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c      | 304 +++++++++++++++++----
 6 files changed, 372 insertions(+), 86 deletions(-)
---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20260801-crosshatch-panel-06ce8a69fb7f

Best regards,
--  
David Heidelberg <david@ixit.cz>

