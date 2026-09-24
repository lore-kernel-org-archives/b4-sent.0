From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Subject: [PATCH 0/3] Add T7 PWM core clock support
Date: Thu, 24 Sep 2026 17:14:27 +0200
Message-Id: <20260924-add-t7-sys-pwm-clk-v1-0-05b91e87f0a9@aliel.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MSQqAMAxA0atI1gbaIk5XERdqUw2ONOKAeHeLy
 7f4/wEhzyRQRg94Olh4XQJ0HEE3NEtPyDYYjDKpKkyCjbW4Zyi34HbO2E0jOkXO5bolMhpCuHl
 yfP3Tqn7fD3qqaZlkAAAA
X-Change-ID: 20260924-add-t7-sys-pwm-clk-f0eff81bee21
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1749;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=/Xr6Vonrl8KSO7NkZYS+4LuXBsR+pRx2JEkY9vxDmtQ=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9ZWu/Lohq/icVfPylbtOzRvz7nEya2av36tld9SPduif
 dZR7/4HHaUsDGJcDLJiiiz9cy1PvLt89MzXPeopMHNYmUCGMHBxCsBEOo0Y/hfIBllYapSx6uxZ
 JmUx3+bj/kctv2d93eP4v226gpLDns8MfwVDfi86aPRj6kmPOa48m+sZK/dNbwt/t3WTyRdfacO
 LunwA
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PWM controllers on the Amlogic T7 SoC have a system clock that
controls access to the controller, in addition to the two input
clocks of channels A and B.

It is currently not described in the device tree, so it is neither
referenced nor enabled by the driver.

This series adds support for it:

  - patch 1 extends the binding with a third "core" clock for
    amlogic,t7-pwm, and makes clocks/clock-names required for it;
  - patch 2 makes the driver get and enable the optional "core"
    clock, leaving other SoCs unaffected;
  - patch 3 describes the system clock (CLKID_SYS_PWM_*) in the T7
    device tree for all the PWM controllers.

`dt_binding_check DT_SCHEMA_FILES=pwm-amlogic.yaml` test is ok

  CHKDT   ./Documentation/devicetree/bindings
warning: python package 'yamllint' not installed, skipping
  STYLE   ./Documentation/devicetree/bindings
  DTEX    Documentation/devicetree/bindings/pwm/pwm-amlogic.example.dts
  DTC [C] Documentation/devicetree/bindings/pwm/pwm-amlogic.example.dtb

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
Ronald Claveau (3):
      dt-bindings: pwm: amlogic: Add core clock for T7
      pwm: meson: Add optional core clock for S4 PWM
      arm64: dts: amlogic: t7: Add core clock to PWM controller nodes

 .../devicetree/bindings/pwm/pwm-amlogic.yaml       | 37 +++++++++++++++++++---
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi        | 28 ++++++++++++----
 drivers/pwm/pwm-meson.c                            |  5 +++
 3 files changed, 59 insertions(+), 11 deletions(-)
---
base-commit: a8c591ed6b672915e0be57843f943a2a723aff40
change-id: 20260924-add-t7-sys-pwm-clk-f0eff81bee21

Best regards,
-- 
Ronald Claveau <linux-kernel-dev@aliel.fr>

