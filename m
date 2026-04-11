From: Vasiliy Doylov <nekocwd@mainlining.org>
Subject: [PATCH v5 0/3] media: i2c: lc898217xc: initial driver
Date: Sat, 11 Apr 2026 16:13:07 +0300
Message-Id: <20260411-media-i2c-lc898217xc-initial-driver-v5-0-c71ddcf40bad@mainlining.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAONI2mkC/53QTWrDMBAF4KsErasijf7srnqPkoUijZwBRw5yE
 CnBd4/i0q68MF2+YfjeMA82YyGc2cfhwQpWmmnKLZi3AwtnnwfkFFtmIMAIAMcvGMlzgsDH0PU
 dSHcPnDLdyI88FqpYeHQnI7xUJqBhTboWTHRfW76OLZ9pvk3ley2t8jX98ZXQu/wqueAIKUU4Q
 YoGPy+e8ti28vA+lYG9Sir8A4YGW6+tCpgU+m4TVn+wBCH3warB2iKornfYg9yE9S9shQKzD9b
 rxdGm6HQvN16xLMsTgRUQM+YBAAA=
X-Change-ID: 20250227-media-i2c-lc898217xc-initial-driver-d7b50a135ce5
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, david@ixit.cz
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Vitalii Skorkin <nikroks@mainlining.org>, 
 Antonio Rische <nt8r@protonmail.com>, 
 Vasiliy Doylov <nekocwd@mainlining.org>, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2535;
 i=nekocwd@mainlining.org; h=from:subject:message-id;
 bh=0ds83WmivfB0Z0vMYXoVl6+7L+6qOV31Rk1YvAQhjqk=;
 b=owGbwMvMwCVmXFbadLHr1XTG02pJDJm3PF54V6dOsWWbcPTD3nWRL8RmNhc/fcK8yWGGdr69Q
 ULJ22OzO0pZGMS4GGTFFFm63x++92AeL2up+idemDmsTCBDGLg4BWAiF9cw/BU8pX+4RmLvujtn
 uWoUV7/ffzY5JPPmhFahjXWhL16/ZA5mZFijPfExC1vZvs3fuqVLPq+eczt5tUOPv7ZN2KxVsfu
 XVbADAA==
X-Developer-Key: i=nekocwd@mainlining.org; a=openpgp;
 fpr=8BEFC3DEE09E0D057527F20D33767582D18AEA97
X-Endpoint-Received: by B4 Relay for nekocwd@mainlining.org/default with auth_id=692
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

LX898217XC is a 11 bit DAC, designed for linear control
of voice coil motor. This driver creates a V4L2 subdevice
and provides control to set the desired focus.

Tested on Oneplus 6 (oneplus-enchilada)

Co-developed-by: Vitalii Skorkin <nikroks@mainlining.org>
Signed-off-by: Vitalii Skorkin <nikroks@mainlining.org>
Co-developed-by: Antonio Rische <nt8r@protonmail.com>
Signed-off-by: Antonio Rische <nt8r@protonmail.com>
Signed-off-by: Vasiliy Doylov <nekocwd@mainlining.org>
---
Changes in v5:
- Add Reviewed-by tag (Krzysztof)
- Link to v4: https://lore.kernel.org/r/20260325-media-i2c-lc898217xc-initial-driver-v4-0-6ad6fd74915e@mainlining.org

Changes in v4:
- Removed unused focus ctrl (Dave)
- Added ctrl state restore on runtime_resume (Dave)
- Removed subscribe/unsubscribe event handlers (Dave)
- Removed V4L2_SUBDEV_FL_HAS_EVENTS flag (Dave)
- Changed supplies from vcc to vdd + vana
- Fixed free and PM issues on probe fail
- Fixed typo in devicetree documentation
- Link to v3: https://lore.kernel.org/r/20251201-media-i2c-lc898217xc-initial-driver-v3-0-46e23897e921@mainlining.org

Changes in v3:
- Fixed MAINTAINERS (Krzysztof)
- Reordered commits (Krzysztof)
- Removed blank line from device-tree documentation (Krzysztof)
- Refactored to use CCI regmap
- Refactored to use dev_err_probe in probe
- Link to v2: https://lore.kernel.org/all/20250304-media-i2c-lc898217xc-initial-driver-v2-0-6a463cef3ea8@mainlining.org/

Changes in v2:
- PM functions annotated as __maybe_unused.
- Fixed dt bindings documentation commit message
- Added v4l2 events (now v4l2-compliance shows no failed tests)
- Link to v1: https://lore.kernel.org/r/20250304-media-i2c-lc898217xc-initial-driver-v1-0-e2ffd2b2fd5e@mainlining.org

---
Vasiliy Doylov (3):
      media: dt-bindings: Add LC898217XC documentation
      media: i2c: Add driver for LC898217XC VCM
      MAINTAINERS: Add entry for Onsemi LC898217XC lens voice coil driver

 .../bindings/media/i2c/onnn,lc898217xc.yaml        |  59 +++++
 MAINTAINERS                                        |   7 +
 drivers/media/i2c/Kconfig                          |   9 +
 drivers/media/i2c/Makefile                         |   1 +
 drivers/media/i2c/lc898217xc.c                     | 289 +++++++++++++++++++++
 5 files changed, 365 insertions(+)
---
base-commit: 66672af7a095d89f082c5327f3b15bc2f93d558e
change-id: 20250227-media-i2c-lc898217xc-initial-driver-d7b50a135ce5

Best regards,
--  
Vasiliy Doylov <nekocwd@mainlining.org>

