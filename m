From: Carl Lee <carl.lee@amd.com>
Subject: [PATCH v2 0/3] hwmon: pmbus: Add support for MPQ8786
Date: Thu, 05 Feb 2026 18:01:36 +0800
Message-Id: <20260205-dt-bindings-hwmon-pmbus-mpq8785-add-mpq8786-support-v2-0-3744cd9b2850@amd.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIBqhGkC/6WOSxKCMBBEr0Jl7VhJjAFdeQ+LBZABZpGPCaAWx
 d2NlDdw168X/XplCSNhYtdiZREXSuRdBnkoWDc2bkAgk5lJLjWX/ARmgpacITckGJ/WOwi2nRP
 Y8KjK6gyNMb+sIc0h+DhBryquLlgpIZDl5RCxp9duvdeZR0qTj+/9xCK+7X++RYAAXbZcCZR9q
 eWtsebYecvqbds+8ZOJU/QAAAA=
X-Change-ID: 20260203-dt-bindings-hwmon-pmbus-mpq8785-add-mpq8786-support-f48049e8411e
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Charles Hsu <ythsu0511@gmail.com>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, carl.lee@amd.com, peter.shen@amd.com, 
 colin.huang2@amd.com
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770285700; l=1326;
 i=carl.lee@amd.com; s=20260203; h=from:subject:message-id;
 bh=DFrlS59fjMgBzDiAHSMCR4kAn5bfamElxFbhVStZ664=;
 b=7qGpO4iddJJUHIK/BZ/PIoUzhQpV18z7EKW+T3ZoLBYmGj0Kal+jH61J7ZWmHS8cykG9xgCzw
 kPnCu9xUc/VBaHD93aMxNi2ZUPpNeEGWJaYEZGD8KyWlE/NySeyyA3M
X-Developer-Key: i=carl.lee@amd.com; a=ed25519;
 pk=pyq7QaQvoxMg806KVkRwpCbiah+7ncWr4MBpK1AEyjA=
X-Endpoint-Received: by B4 Relay for carl.lee@amd.com/20260203 with auth_id=623
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series includes the devicetree binding update followed by the corresponding
hwmon driver changes. In addition to basic MPQ8786 support, the series
also fixes VOUT reporting by forcing direct mode for VID VOUT on both
MPQ8785 and MPQ8786, as VID mode configuration is equivalent to direct
mode according to the datasheet.

Signed-off-by: Carl Lee <carl.lee@amd.com>
---
Changes in v2:
- Combine DT binding and driver changes into a single series
- Fix VOUT reporting by forcing direct mode for VID VOUT
- Link to v1: https://lore.kernel.org/r/20260203-dt-bindings-hwmon-pmbus-mpq8785-add-mpq8786-support-v1-1-67b041e2f762@amd.com

---
Carl Lee (3):
      dt-bindings: hwmon: pmbus: mpq8785: add MPQ8786 support
      hwmon: pmbus: mpq8785: add support for MPQ8786
      hwmon: pmbus: mpq8785: force direct mode for VID VOUT on MPQ8785/MPQ8786

 .../bindings/hwmon/pmbus/mps,mpq8785.yaml          |  5 ++++-
 Documentation/hwmon/mpq8785.rst                    |  7 ++++++
 drivers/hwmon/pmbus/mpq8785.c                      | 26 +++++++++++++++++++++-
 3 files changed, 36 insertions(+), 2 deletions(-)
---
base-commit: 4c87cdd0328495759f6e9f9f4e1e53ef8032a76f
change-id: 20260203-dt-bindings-hwmon-pmbus-mpq8785-add-mpq8786-support-f48049e8411e

Best regards,
-- 
Carl Lee <carl.lee@amd.com>

