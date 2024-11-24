From: Maud Spierings <maud_spierings@hotmail.com>
Subject: [PATCH v3 0/4] Asus vivobook s15 improvements
Date: Sun, 24 Nov 2024 11:00:56 +0100
Message-Id: <20241124-asus_qcom_display-v3-0-002b723b1920@hotmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFj5QmcC/4XNywrCMBAF0F8pWRvJo09X/odIGdPEDrRNTWqwl
 P67aXEjCC7vcO+ZhXjtUHtyShbidECPdohBHhKiWhjummITMxFMpJzznIJ/+vqhbF836McOZqp
 0ZkwhKilTRuJudNrgazcv15hb9JN18/4i8O360YT8oQVOGS0zqIypRMoAzq2desDuGFtk84L4a
 4hoALsZU2ZFHnvfxrqub6RDhTz4AAAA
X-Change-ID: 20241116-asus_qcom_display-ce5ff7293340
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Douglas Anderson <dianders@chromium.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732442467; l=1685;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=wsiWmyEwu4YNSWKps6tXSxMb1RutH3lVHwYYksxB0QI=;
 b=wMo89KlcYiVtbpv3CmvyQ2to4ZkboF/CtjQQKLMntm1f+0+og1b/bOfmCy+L0Or5QNGBGlBGG
 /8olbMCxBN/DUoRth+saS1ecD+A9h0S6NfXITmKyvBoxJ6A5KS9emRq
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Improves several parts of the devicetree:
1. The eDP panel bindings
2. Add a lid switch
3. Add bluetooth and describe wlan (depends on [1])

[1]: https://lore.kernel.org/all/20241007-x1e80100-pwrseq-qcp-v1-0-f7166510ab17@linaro.org/

---
I seem to get a warning that the pci17cb vendor is undocumented (wlan)
I can find this compatible in
Documentation/devicetree/bindings/net/wireless/qcom,ath12k.yaml
But pci17cb doesn't really seem like a vendor name to me, I have ignored
this warning for now.

Changes in v3:
- Fixed commit message formatting (line wrapping)
- Fixed bad indentation (lid switch pinctrl)
- Fixed bluetooth addition and added wifi description
- Link to v2: https://lore.kernel.org/r/20241123-asus_qcom_display-v2-0-a0bff8576024@hotmail.com

Changes in v2:
- Add missing gpiokeys include in the lid switch patch
- Add depends on for the bluetooth patch
- Link to v1: https://lore.kernel.org/r/20241123-asus_qcom_display-v1-0-85a9ff9240aa@hotmail.com

---
Maud Spierings (4):
      dt-bindings: display: panel: samsung,atna56ac03: Document ATNA56AC03
      arm64: dts: qcom: x1e80100-vivobook-s15: Use the samsung,atna33xc20 panel driver
      arm64: dts: qcom: x1e80100-vivobook-s15: Add lid switch
      arm64: dts: qcom: x1e80100-vivobook-s15: Add bluetooth

 .../bindings/display/panel/samsung,atna33xc20.yaml |   2 +
 .../boot/dts/qcom/x1e80100-asus-vivobook-s15.dts   | 201 ++++++++++++++++++++-
 2 files changed, 202 insertions(+), 1 deletion(-)
---
base-commit: 98fb106aa5265aab0d857a942c410a753b470cc0
change-id: 20241116-asus_qcom_display-ce5ff7293340

Best regards,
-- 
Maud Spierings <maud_spierings@hotmail.com>

