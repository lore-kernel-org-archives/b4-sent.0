From: Joel Selvaraj <foss@joelselvaraj.com>
Subject: [PATCH RESEND v4 0/4] Add Xiaomi Poco F1 touchscreen support
Date: Tue, 06 May 2025 13:18:37 -0500
Message-Id: <20250506-pocof1-touchscreen-support-v4-0-bfb53da52945@joelselvaraj.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAH1SGmgC/43RPU/DMBAG4L9SecbIn3HciYGuDDAiBvtyIa7aO
 NhJBKr63zEBBAON2O5Dek5670QypoCZbDcnknAOOcS+NOpqQ6Bz/TPS0JSeCCYUZ8zQIUJsOR3
 jBF2GhNjTPA1DTCMFo4XjlYAGBCnAkLANrwv+SO53D7u7W/JU5l3IY0xvy82ZL9v/8DOnjDZec
 i94zWvQN/uIh4yH2SW3v4Z4XPRZ/IiC1auiKKJ2FRojLbbqkii/Rc0k46uiLKJrGQfpJfP6kqh
 +i3JVVEUsiUqPHqRV4g/x/Bl2wpepPHD8Sty7jLTsj2HcboChr7SyCrVtbC2Vaw1491FWwqJl3
 HihHS/Y+R3Z4NAbFQIAAA==
X-Change-ID: 20241007-pocof1-touchscreen-support-c752a162cdc2
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 Joel Selvaraj <foss@joelselvaraj.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746555528; l=2842;
 i=foss@joelselvaraj.com; s=20250506; h=from:subject:message-id;
 bh=AAwL5uoOTe6wCwpJpDywIRpKXFmiHBgm7TpEJavHXSQ=;
 b=INuU4+qYGCE/v6P5oMl5xtD0ThiZimqH3pLqAa6TCOiX0ZoDbVdCM1e4NImNyO0ctlVed4g0M
 hbERnbpVHQsD5B6sUs9tlg3rRW1vCour20TigfYe5jd2MBnHgYkIOKM
X-Developer-Key: i=foss@joelselvaraj.com; a=ed25519;
 pk=/jk63vyofgC3YCat+t/kcBv+rlSEVcI4PLN/LN0SQlQ=
X-Endpoint-Received: by B4 Relay for foss@joelselvaraj.com/20250506 with auth_id=399
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In the first patch, I have updated the edt-ft5x06 touchscreen binding 
documentation. In Xiaomi Poco F1(qcom/sdm845-xiaomi-beryllium-ebbg.dts),
the FocalTech FT8719 touchscreen is integrally connected to the display 
panel (EBBG FT8719) and thus should be power sequenced together with 
display panel for proper functioning using the panel property. Since the
edt-ft5x06 touchscreen binding uses almost all the properties present in 
touchscreen.yaml, let's remove additionalProperties: false and use 
unevaluatedProperties to include all the properties, including the needed
panel property.

In the second patch, I have enabled the qupv3_id_1 and gpi_dma1 as they
are required for configuring touchscreen. Also added the pinctrl
configurations. These are common for both the Poco F1 Tianma and EBBG
panel variant.

In the subsequent patches, I have enabled support for the Novatek NT36672a
touchscreen and FocalTech FT8719 touchscreen that are used in the Poco F1
Tianma and EBBG panel variant respectively.

Signed-off-by: Joel Selvaraj <foss@joelselvaraj.com>
---
Changes in v4:
- Update the dt-binding patch's commit message to be more accurate
- Link to v3: https://lore.kernel.org/r/20250301-pocof1-touchscreen-support-v3-0-af01c3b30b55@joelselvaraj.com

Changes in v3:
- Fix SoB email id mismatch (suggested by Krzysztof Kozlowski)
- Use unevaluatedProperties instead additionalProperties in dt-binding (suggested by Krzysztof Kozlowski)
- Link to v2: https://lore.kernel.org/r/20241208-pocof1-touchscreen-support-v2-0-5a6e7739ef45@joelselvaraj.com

Changes in v2:
- Fixed the missing "panel" property dt-binding error reported by Rob Herring's bot.
- Change the "input-enable" property to "output-disable" in qcom/sdm845-xiaomi-beryllium-common.dtsi
  (Based on a patch suggested by Konrad Dybcio).
- Link to v1: https://lore.kernel.org/r/20241007-pocof1-touchscreen-support-v1-0-db31b21818c5@joelselvaraj.com

---
Joel Selvaraj (4):
      dt-bindings: input: touchscreen: edt-ft5x06: use unevaluatedProperties
      arm64: dts: qcom: sdm845-xiaomi-beryllium-common: add touchscreen related nodes
      arm64: dts: qcom: sdm845-xiaomi-beryllium-tianma: introduce touchscreen support
      arm64: dts: qcom: sdm845-xiaomi-beryllium-ebbg: introduce touchscreen support

 .../bindings/input/touchscreen/edt-ft5x06.yaml     |  9 +----
 .../dts/qcom/sdm845-xiaomi-beryllium-common.dtsi   | 39 ++++++++++++++++++++++
 .../boot/dts/qcom/sdm845-xiaomi-beryllium-ebbg.dts | 23 +++++++++++++
 .../dts/qcom/sdm845-xiaomi-beryllium-tianma.dts    | 23 +++++++++++++
 4 files changed, 86 insertions(+), 8 deletions(-)
---
base-commit: c0eb65494e59d9834af7cbad983629e9017b25a1
change-id: 20241007-pocof1-touchscreen-support-c752a162cdc2

Best regards,
-- 
Joel Selvaraj <foss@joelselvaraj.com>

