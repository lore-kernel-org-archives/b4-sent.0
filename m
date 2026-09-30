From: Armandas Kvietkus <armandas.kvietkus@proton.me>
Subject: [PATCH v2 0/2] Input: Add Awinic AW8697 haptics driver
Date: Wed, 30 Sep 2026 19:18:49 +0200
Message-Id: <20260930-mainlining-v2-0-40bb1b3943db@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NQQ6CMBBFr0Jmbc1AI6Ir7mFY0GGEMdKSthIN6
 d0F3Lp8yfvvLxDYCwe4Zgt4niWIsysUhwxoaG3PSrqVocCixItGNbZin2LF9gpNV5mzOVFbEqy
 DyfNd3nvs1vw4vMyDKW6FzRgkROc/+9ucb97f8JwrVKRRk+kMIlX15F109jgyNCmlL0eT6YG2A
 AAA
X-Change-ID: 20260930-mainlining-0bd8b7b5ca6c
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Griffin Kroah-Hartman <griffin.kroah@fairphone.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Armandas Kvietkus <armandas.kvietkus@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790788729; l=1883;
 i=armandas.kvietkus@proton.me; h=from:subject:message-id;
 bh=njD6TWFbmDyEqVQkX6D84VkhL9/hfU5DCVnSetZmtHo=;
 b=hNhixIMuEaFVSuf7swosAAzCQhMtz+NyT6WKNzDpjg+JkYq6udb7iFAZXRloQQ9nYUDODBmyT
 3bl1YB7Fo7eAI+vPSHScOZdRlXIx13KoCqB9oDMDEyT0QSVc6L0mQbz
X-Developer-Key: i=armandas.kvietkus@proton.me; a=ed25519;
 pk=wuqmImJ9sKlDVcwALOvfGhjj7G8EBjjM4TpCdmlrAf8=
X-Endpoint-Received: by B4 Relay for armandas.kvietkus@proton.me/default with auth_id=974
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a driver for the Awinic AW8697 LRA haptic driver IC.
It is the vibrator in the Xiaomi POCO F3.

The AW8697 is an older generation than the AW86927. The register map
is different, so it gets its own driver. The binding reuses
awinic,aw86927.yaml.

Tested on the phone: rumble at several strengths, 72 effects in a row,
stop on close, driver rebind and module reload.

Signed-off-by: Armandas Kvietkus <armandas.kvietkus@proton.me>
---
Changes in v2:
- Do not queue I2C work from the ff-memless timer during system
  suspend. A suspended flag is set and cleared under the input event
  lock, as in da7280. Tested with delayed effects across suspend.
- Use explicit error checks instead of returning the last regmap call.
- The NULL IRQ name finding is not changed. devm_request_threaded_irq()
  uses dev_name() when the name is NULL. /proc/interrupts shows 11-005a.
- Link to v1: https://patch.msgid.link/20260930-mainlining-v1-0-c303cbdb00c8@proton.me

v2 only fixes findings from the automated AI review. I will not send
another revision for automated review findings alone, because that
can go on forever. I will wait for human review.

---
Armandas Kvietkus (2):
      dt-bindings: input: awinic,aw86927: Add Awinic AW8697
      Input: aw8697 - Add Awinic AW8697 haptics driver

 .../devicetree/bindings/input/awinic,aw86927.yaml  |   4 +-
 MAINTAINERS                                        |   6 +
 drivers/input/misc/Kconfig                         |  14 +
 drivers/input/misc/Makefile                        |   1 +
 drivers/input/misc/aw8697.c                        | 761 +++++++++++++++++++++
 5 files changed, 785 insertions(+), 1 deletion(-)
---
base-commit: 165768bb70265b5c38cf0b73fafd75be235f8b14
change-id: 20260930-mainlining-0bd8b7b5ca6c

Best regards,
--  
Armandas Kvietkus <armandas.kvietkus@proton.me>

