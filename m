From: Maud Spierings <maud_spierings@hotmail.com>
Subject: [PATCH v2 0/4] Asus vivobook s15 improvements
Date: Sat, 23 Nov 2024 13:58:52 +0100
Message-Id: <20241123-asus_qcom_display-v2-0-a0bff8576024@hotmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIzRQWcC/22NwQ6CMBBEf4Xs2Zq2gIon/8MQsimt3QQodpFIC
 P9uJR49vsnMmxXYRrIM12yFaGdiCkMCfcjAeBweVlCbGLTUhVLqJJBf3DxN6JuWeOxwEcaWzp1
 1leeFhLQbo3X03p33OrEnnkJc9otZfdOfTed/bLMSUlxKrJyrdCERbz5MPVJ3TC2ot237AB1Kf
 q20AAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732366736; l=1132;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=gRTpoiz71rEZ3HEhPa5QBWzaIeCM3QF+8GY8L2ThZMU=;
 b=MODatZrh/bk+k0WvKk5jsrWTZsQpXoa/lqa9kKOJxymK6Qyl0TGqe7vy0/wuKcbNZJs7+mAWj
 LqMReLG/gtYBYkRFPII2dBPjLg6Se6DsoDUJ7gRNEix7oZGpSZmEqn/
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Improves several parts of the devicetree:
1. The eDP panel bindings
2. Adds a lid switch
3. Adds bluetooth (depends on [1])

[1]: https://lore.kernel.org/all/20241007-x1e80100-pwrseq-qcp-v1-0-f7166510ab17@linaro.org/

---
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

 .../bindings/display/panel/samsung,atna33xc20.yaml |  2 +
 .../boot/dts/qcom/x1e80100-asus-vivobook-s15.dts   | 61 +++++++++++++++++++++-
 2 files changed, 62 insertions(+), 1 deletion(-)
---
base-commit: 80e87ab38380e4ddf238ba3d8436357c3e0b52d1
change-id: 20241116-asus_qcom_display-ce5ff7293340

Best regards,
-- 
Maud Spierings <maud_spierings@hotmail.com>

