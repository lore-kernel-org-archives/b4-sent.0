From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/2] Add PWM support Amlogic S7 S7D S6
Date: Thu, 02 Apr 2026 02:40:14 +0000
Message-Id: <20260402-s6-s7-pwm-v2-0-657dce040956@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAA7XzWkC/03MQQrCMBCF4auUWTuSTmkSXXkP6aKJaTtgm5JIV
 ErubiwILv/H49sgusAuwrnaILjEkf1Sgg4V2KlfRod8Kw0kSIqGWowSo8L1OSPpWrbaaK0aCeW
 /Bjfwa7euXemJ48OH906n+rv+FPmnpBoFSuVoUGRO2thLP9/9yPZo/QxdzvkD/RtCwqQAAAA=
X-Change-ID: 20260325-s6-s7-pwm-281658b88736
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Junyi Zhao <junyi.zhao@amlogic.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775097616; l=877;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=MzbXLULHXDPO40t8V2eon7BjaepBG28tDaVLig2EstY=;
 b=AI9WFujgFd2PKUeRxl3/lDThNDBbC94EVYbDBCRIW0gasV4+Cg2oTV2+NeRGuUhUlMr8mNFMi
 Ov9Nz565F7UA3msuJ8WH1N0IpGqOeqxU8cP6/0+Q1G4qEjKIojPiDof
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings and driver support Amlogic S7/S7D/S6 SoCs.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v2:
- Simpler s7 clock desc, and drop the example in bindings.
- Make minor changes to probe based on Martin's suggestion.
- Link to v1: https://lore.kernel.org/r/20260326-s6-s7-pwm-v1-0-67e2f72b98bc@amlogic.com

---
Junyi Zhao (1):
      dt-bindings: pwm: amlogic: Add new bindings for S6 S7 S7D

Xianwei Zhao (1):
      pwm: meson: Add support for Amlogic S7

 .../devicetree/bindings/pwm/pwm-amlogic.yaml       | 19 +++++++++++++
 drivers/pwm/pwm-meson.c                            | 32 ++++++++++++++++++++--
 2 files changed, 48 insertions(+), 3 deletions(-)
---
base-commit: 8ab1fc9104158045f68fde2d0ae16f5fbcf8bfbd
change-id: 20260325-s6-s7-pwm-281658b88736

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

