From: Vincent Jardin <vjardin@free.fr>
Subject: [PATCH v2 0/2] hwmon: pmbus: 0-based thermal sensor index,
 mps,mpq8785 #thermal-sensor-cells
Date: Thu, 01 Oct 2026 09:28:21 +0200
Message-Id: <20261001-for-upstream-dt-mpq8785-thermal-sensor-cells-v2-0-07d368dcc662@free.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJULvmoC/52NTQ6CMBBGr2Jm7ZgCtkVX3sOwaMpUmvDnTCUaw
 t2tHMHl+/LlvRWEOJLA9bAC0xIlTmOG8ngA37nxQRjbzFCq0qhLpTBMjK9ZEpMbsE04zM/a1hp
 TRzy4HoVGyRdPfS/orQ3OtE6flYGsnJlCfO+5e5O5i5Im/uz1pfitf4aWAgs02lbeGk0U6ltgo
 lNgaLZt+wIrI/7N5gAAAA==
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Charles Hsu <ythsu0511@gmail.com>, 
 Eduardo Valentin <eduval@amazon.com>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>, 
 stable+noautosel@kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790839710; l=1592;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=fnkw+GF/J35hw3r+1vkzRsr1snb5UGGguV8teybYY48=;
 b=FmoTpu7IVAFu9zOx+03ETWgBzk239thQMC9+HKq6GWg3wexsOK/Xv89dEIjNaLMZWlvlyNN9v
 OAo4xaOS5m0AK82vN2i9sAckVt4/3t/crwhLSv/HvvNrqydE78+3kES
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PMBus core registers its temperature inputs with the thermal core
from index 1, while the thermal core expects a 0-based index.

Patch 1 fixes it, as Guenter commente on v1 [1].

Patch 2 is the v1 binding change, now with #thermal-sensor-cells = <0>.

[1] https://lore.kernel.org/r/37298c5b-aa6b-473a-8e22-d29ddec12c04@roeck-us.net

To: Guenter Roeck <linux@roeck-us.net>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Charles Hsu <ythsu0511@gmail.com>
To: Eduardo Valentin <eduval@amazon.com>
Cc: linux-hwmon@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Signed-off-by: Vincent Jardin <vjardin@free.fr>

Changes in v2:
- New patch 1: register the PMBus thermal sensors with a 0-based index (Sashiko, Guenter)
- Patch 2: #thermal-sensor-cells const: 0 instead of 1
- Link to v1: https://lore.kernel.org/r/20260930-for-upstream-dt-mpq8785-thermal-sensor-cells-v1-1-6573c765eef8@free.fr

---
Vincent Jardin (2):
      hwmon: (pmbus/core) Register the thermal sensors with a 0-based index
      dt-bindings: hwmon: pmbus: mps,mpq8785: add #thermal-sensor-cells

 Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml | 3 +++
 drivers/hwmon/pmbus/pmbus_core.c                               | 2 +-
 2 files changed, 4 insertions(+), 1 deletion(-)
---
base-commit: 4781ca52761e666cf18b591e6bb0478396c90320
change-id: 20260930-for-upstream-dt-mpq8785-thermal-sensor-cells-c77fa6da5406

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

