From: Yedaya Katsman <yedaya.ka@gmail.com>
Subject: [PATCH 0/3] Support FT3518 touchscreen in xiaomi-laurel
Date: Tue, 13 Jan 2026 21:12:34 +0200
Message-Id: <20260113-touchscreen-patches-v1-0-a10957f32dd8@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBG4avErBPSyEVXiRZpvzkbC6cikO6et
 PwW7xUSZIbQ2BTKuFl4TxW6bcjHJW1QvFaT6YzttO7VuV8+is9AUsdy+ghRDs4Mxrp1CI5qeWQ
 Efv7rNL/vBxiP+z1lAAAA
X-Change-ID: 20260113-touchscreen-patches-beb2526bd5fb
To: SzczurekYT <szczurek@szczurek.yt>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Yedaya Katsman <yedaya.ka@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768331572; l=928;
 i=yedaya.ka@gmail.com; s=20260113; h=from:subject:message-id;
 bh=shKJzKw1Ih0HkN9nyF0ttMJM0COgi6vVUCHPLcv23a0=;
 b=DSEKKDFVGI+3VF3inejaQDMH0Q2L84sZznBHxBxkwtTsKkvrib5jvhZ5ponszHQDj0MXnyaLn
 TfEB7BOf3BlDPItmL57iGvyLkaQe8lSujNEX2aM4Ros1mz+d2oLahZ1
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
Yedaya Katsman (3):
      dt-bindings: input: touchscreen: edt-ft5x06: Add FocalTech FT3518
      drivers: input: touchscreen: edt-ft5x06: Add FocalTech FT3518
      arm64: dts: qcom: sm6125-xiaomi-laurel-sprout: Add Focaltech FT3518 touchscreen

 .../bindings/input/touchscreen/edt-ft5x06.yaml     |  1 +
 .../boot/dts/qcom/sm6125-xiaomi-laurel-sprout.dts  | 34 ++++++++++++++++++++++
 drivers/input/touchscreen/edt-ft5x06.c             |  6 ++++
 3 files changed, 41 insertions(+)
---
base-commit: b71e635feefc852405b14620a7fc58c4c80c0f73
change-id: 20260113-touchscreen-patches-beb2526bd5fb

Best regards,
-- 
Yedaya Katsman <yedaya.ka@gmail.com>

