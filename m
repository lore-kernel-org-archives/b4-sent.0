From: Armandas Kvietkus <armandas.kvietkus@proton.me>
Subject: [PATCH v3 0/2] Input: Add Awinic AW8697 haptics driver
Date: Tue, 13 Oct 2026 16:42:44 +0200
Message-Id: <20261013-mainlining-v3-0-fca981f62b57@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNwQ7CIBAFf6XhLGYLVVtP/ofx0AVs11hooBJN0
 38X6sWDHid5M29mwXgygR2LmXkTKZCzCeSmYKpvbWc46cRMgNhDI4EPLdk7WbIdB9Q1HnCn2r1
 iSRi9udJzjZ0vHw4PvBk15UJe9BQm51/rWyzz7mc4lhy4kiAVagRQ9Wn0bnJ2OxiWw1H8V0VSK
 0AsUTaV1PitLsvyBsHJ11LxAAAA
X-Change-ID: 20260930-mainlining-0bd8b7b5ca6c
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Griffin Kroah-Hartman <griffin.kroah@fairphone.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 Armandas Kvietkus <armandas.kvietkus@proton.me>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791902565; l=2577;
 i=armandas.kvietkus@proton.me; h=from:subject:message-id;
 bh=csndEIJALGjmkNsNoRfoNPp6dxs2xMbpUWFP/TJNYmw=;
 b=SUygf2am8eMZuDRJdhM45GRb/k61pT9uA9j+5GI0oW6Nk6B1Cx3kzn+BQfu0Jq40HZdsHth4t
 7deTL2JCcqYAGoKlKJH9UhxMtr7xlzcQnHjdSSQgNrWnAeJaNQwtuAE
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
Changes in v3:
- Drop <linux/mod_devicetable.h>. <linux/i2c.h> provides
  i2c_device_id and of_device_id. (Uwe)
- Use a named initializer in the i2c_device_id table. (Uwe)
- Add Acked-by from Krzysztof to the binding.
- Link to v2: https://patch.msgid.link/20260930-mainlining-v2-0-40bb1b3943db@proton.me

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

To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Griffin Kroah-Hartman <griffin.kroah@fairphone.com>
To: Armandas Kvietkus <armandas.kvietkus@proton.me>
Cc: linux-input@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Armandas Kvietkus (2):
      dt-bindings: input: awinic,aw86927: Add Awinic AW8697
      Input: aw8697 - Add Awinic AW8697 haptics driver

 .../devicetree/bindings/input/awinic,aw86927.yaml  |   4 +-
 MAINTAINERS                                        |   6 +
 drivers/input/misc/Kconfig                         |  14 +
 drivers/input/misc/Makefile                        |   1 +
 drivers/input/misc/aw8697.c                        | 760 +++++++++++++++++++++
 5 files changed, 784 insertions(+), 1 deletion(-)
---
base-commit: 165768bb70265b5c38cf0b73fafd75be235f8b14
change-id: 20260930-mainlining-0bd8b7b5ca6c

Best regards,
--  
Armandas Kvietkus <armandas.kvietkus@proton.me>

