From: Maud Spierings <maud_spierings@hotmail.com>
Subject: [PATCH 0/4] Asus vivobook s15 improvements
Date: Sat, 23 Nov 2024 12:05:50 +0100
Message-Id: <20241123-asus_qcom_display-v1-0-85a9ff9240aa@hotmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAA63QWcC/x3MywqAIBBA0V+JWSeovahfiQixsQZ6OhSF9O9Jy
 7O4NwCjJ2RokgAeL2La1giVJmAns44oaIgGLXWulCqF4ZP7w25LPxDvs3mExcK5StdZlkuI3e7
 R0f0/2+59Pxu0/GpjAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732359972; l=801;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=k3s+kIa0CozrUauq1AcjHwaHwwjQ2E8jG+8stGujCCA=;
 b=z1bfmanqY+F+p3ytY2hnlRngqnTu7lFNHbAn7lzUqGHYP7BtJcw8ub8fLIDszw/fvWfCho3e1
 FBXlSkGgSnTDom3LJS3emaPssGL7hj1bpn5QqFd+GTa2XJbiTp16ZqD
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Improves several parts of the devicetree:
1. The eDP panel bindings
2. Adds a lid switch
3. Adds bluetooth

---
Maud Spierings (4):
      dt-bindings: display: panel: samsung,atna56ac03: Document ATNA56AC03
      arm64: dts: qcom: x1e80100-vivobook-s15: Use the samsung,atna33xc20 panel driver
      arm64: dts: qcom: x1e80100-vivobook-s15: Add lid switch
      arm64: dts: qcom: x1e80100-vivobook-s15: Add bluetooth

 .../bindings/display/panel/samsung,atna33xc20.yaml |  2 +
 .../boot/dts/qcom/x1e80100-asus-vivobook-s15.dts   | 59 +++++++++++++++++++++-
 2 files changed, 60 insertions(+), 1 deletion(-)
---
base-commit: decc701f41d07481893fdea942c0ac6b226e84cd
change-id: 20241116-asus_qcom_display-ce5ff7293340

Best regards,
-- 
Maud Spierings <maud_spierings@hotmail.com>

