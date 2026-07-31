From: Esteban Urrutia <esteuwu@proton.me>
Subject: [PATCH v2 0/2] Support for pmic-glink in SM8475
Date: Fri, 31 Jul 2026 01:00:07 -0400
Message-Id: <20260731-sm8475-pmic-glink-v2-0-28c04928ef22@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ6CMBBFr0Jm7ZhSgYIr72FYSDvAqLSkRaIh3
 F2Ke5cvef/9BQJ5pgDnZAFPMwd2dgN5SED3N9sRstkYpJCFULLCMJSZynEcWGP3ZPvAXFFetFV
 pZHOCbTd6avm9N6/1j8OruZOeYigaPYfJ+c9+OqfR+9efUxSoJaVVobTIDF1G7yZnjwNBva7rF
 9wK0/7EAAAA
X-Change-ID: 20260729-sm8475-pmic-glink-57e56f98d2b3
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-usb@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785474171; l=1031;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=tCQMQynamuZb93GgzmEQI0iJPGc/haOH3L07MnVnM18=;
 b=2AyEu5HVAIR6qRAU+mqy469PFQLYKXnY6KpJsh67ouPlPlrgemyR63UV0vxulTTFBeYFlBq2F
 jfADcsR3EVCBfp8/9pIJ/czsGMGxzs+cEujpc09sJwUOjk4qUv3WL+1
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a compatible string for SM8475 for supporting
pmic-glink.
This way, confusion is avoided, because SM8475 takes most
(CPU/GPU/reserved-memory/etc.) things from SM8450 and some (PHY/eUSB)
from SM8550.
Instead of using one or the other, add a different compatible string.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
Changes in v2:
- Apply suggestions from Krzysztof
- Link to v1: https://patch.msgid.link/20260729-sm8475-pmic-glink-v1-0-c2e1967c04de@proton.me

---
Esteban Urrutia (2):
      dt-bindings: soc: qcom: qcom,pmic-glink: Add compatible string for SM8475
      usb: typec: ucsi: ucsi_glink: Add compatible string for SM8475

 Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml | 1 +
 drivers/usb/typec/ucsi/ucsi_glink.c                             | 1 +
 2 files changed, 2 insertions(+)
---
base-commit: 95d6a9ccef99117115e41e9adb271243bd5e985b
change-id: 20260729-sm8475-pmic-glink-57e56f98d2b3

Best regards,
--  
Esteban Urrutia <esteuwu@proton.me>

