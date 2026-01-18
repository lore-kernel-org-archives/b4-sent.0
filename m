From: Yedaya Katsman <yedaya.ka@gmail.com>
Subject: [PATCH v3 0/3] Support FT3518 touchscreen in xiaomi-laurel
Date: Sun, 18 Jan 2026 22:29:39 +0200
Message-Id: <20260118-touchscreen-patches-v3-0-1c6a729c5eb4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33Nyw6CMBCF4VchXVvTDhfBle9hXPQypU2EkhYbD
 eHdLaxYGJf/SeabhUQMDiO5FgsJmFx0fsxRngqirBh7pE7nJsCgYZyXdPYvZaMKiCOdxKwsRip
 RQg2N1LWRJF9OAY177+r9kdu6OPvw2Z8kvq3/vcQpo4Kzrr6YErRub/0g3POs/EA2L8HRqH4bk
 I0KeG26SrVCiqOxrusXfdJoOfoAAAA=
X-Change-ID: 20260113-touchscreen-patches-beb2526bd5fb
To: =?utf-8?q?Kamil_Go=C5=82da?= <kamil.golda@protonmail.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Yedaya Katsman <yedaya.ka@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768768201; l=1451;
 i=yedaya.ka@gmail.com; s=20260113; h=from:subject:message-id;
 bh=G/9amyEzzmiJq2m54aS8SBqpO+PBlemTSa23Ha0ZoEM=;
 b=CzqIUrFiXPJaAbwT5V0zOORFeJKtZ3GOsStPT1L0P/MKQb/u7Qi4P6BtGbGDTCAMz2WkZa10T
 pCG6T0xZZGoBpD7MFTU/IYygZMVfZhnsRR+sBJA4I/PVB2UKnuZ4IrY
X-Developer-Key: i=yedaya.ka@gmail.com; a=ed25519;
 pk=CgNmxD3tYSws5dZfpmJfc6re/bV/f47veVijddHLytk=
X-Endpoint-Received: by B4 Relay for yedaya.ka@gmail.com/20260113 with auth_id=601
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds support for the touchscreen in the Xiaomi Mi A3 (xiaomi-laurel)
 smartphone, FocalTech FT3518

Original tree was here:
 Link: https://gitlab.postmarketos.org/SzczurekYT/linux/-/commits/laurel

Signed-off-by: Yedaya Katsman <yedaya.ka@gmail.com>
---
Changes in v3:
- Rename regulator node and reorder nodes
- Add gpio pin configuration for pmx_ts_* in sm6125, and reference in the
  touchscreen configuration as pinctrl-*. Doesn't have configuration for
  the gpio 83 pin since it isn't documented downstream.
- Link to v2: https://lore.kernel.org/r/20260114-touchscreen-patches-v2-0-4215f94c8aba@gmail.com

Changes in v2:
- Fixed name and email in signoffs
- Link to v1: https://lore.kernel.org/r/20260113-touchscreen-patches-v1-0-a10957f32dd8@gmail.com

---
Yedaya Katsman (3):
      dt-bindings: input: touchscreen: edt-ft5x06: Add FocalTech FT3518
      drivers: input: touchscreen: edt-ft5x06: Add FocalTech FT3518
      arm64: dts: qcom: sm6125-xiaomi-laurel-sprout: Add Focaltech FT3518 touchscreen

 .../bindings/input/touchscreen/edt-ft5x06.yaml     |   1 +
 .../boot/dts/qcom/sm6125-xiaomi-laurel-sprout.dts  | 113 +++++++++++++++++++++
 drivers/input/touchscreen/edt-ft5x06.c             |   6 ++
 3 files changed, 120 insertions(+)
---
base-commit: b71e635feefc852405b14620a7fc58c4c80c0f73
change-id: 20260113-touchscreen-patches-beb2526bd5fb

Best regards,
-- 
Yedaya Katsman <yedaya.ka@gmail.com>

