From: Alejandro Enrique <alejandroe1@geotab.com>
Subject: [PATCH 0/2] Add support for safeboot pin to UBlox GNSS driver
Date: Wed, 14 May 2025 15:54:40 +0200
Message-Id: <20250514-ubx-safeboot-v1-0-1ae771335356@geotab.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKCgJGgC/x2MQQqAIBAAvyJ7TlBLir4SHdTW2ouGVgjS35PmN
 oeZChkTYYaZVUj4UKYYmsiOgTtM2JHT1hyUUFpoOfDbFp6NRxvjxftRT141NDpoyZnQU/l3y/q
 +H0c9iIBeAAAA
X-Change-ID: 20250514-ubx-safeboot-3758f22225ec
To: Johan Hovold <johan@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alejandro Enrique <alejandroe1@geotab.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747230900; l=1048;
 i=alejandroe1@geotab.com; s=20250514; h=from:subject:message-id;
 bh=F9XmG0qcImWHKFiJQK0qpgJAz3oJ9FDWgu35+n/rWXk=;
 b=bfHhjdvgF/ldusVneSZftn5yZtD5a4VfsEqVCnIsd9dZcgqABA3ARJlcD7645oH7kUedcE5Vt
 JA6TC28L/CoCyaVbvmJ12vhdQXe29WMd5tXc2/lNQpOfQgB6dgett4l
X-Developer-Key: i=alejandroe1@geotab.com; a=ed25519;
 pk=xzHMPbqczL/tMsjXr26iLoHwIzLveHVnT+GIU4p1k38=
X-Endpoint-Received: by B4 Relay for alejandroe1@geotab.com/20250514 with auth_id=404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

U-Blox M9 and M8 chips have a pin to start it in safeboot mode, to be
used to recover from situations where the flash content has become
corrupted and needs to be restored. If this pin is asserted at power
up or reset, the receiver starts in safeboot mode and GNSS operation
is disabled.

If this pin is wired to a GPIO in the host it should be deasserted
before powering up or resetting the GNSS.

This series adds support for handling the safeboot pin when probing
the driver.

Signed-off-by: Alejandro Enrique <alejandroe1@geotab.com>
---
Alejandro Enrique (2):
      dt-bindings: gnss: u-blox: add "safeboot-gpios" binding
      gnss: ubx: add support for the safeboot gpio

 Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml | 4 ++++
 drivers/gnss/ubx.c                                        | 8 ++++++++
 2 files changed, 12 insertions(+)
---
base-commit: 9c32cda43eb78f78c73aee4aa344b777714e259b
change-id: 20250514-ubx-safeboot-3758f22225ec

Best regards,
-- 
Alejandro Enrique <alejandroe1@geotab.com>

