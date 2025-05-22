From: Alejandro Enrique <alejandroe1@geotab.com>
Subject: [PATCH v2 0/2] Add support for safeboot pin to UBlox GNSS driver
Date: Thu, 22 May 2025 18:51:03 +0200
Message-Id: <20250522-ubx-safeboot-v2-0-08c22378b8c9@geotab.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPdVL2gC/3WMyw7CIBBFf6WZtRgeIsaV/2G6ABzaWVgMIKlp+
 Hexe+/u3OScDTImwgzXYYOElTLFpYM8DOBnu0zI6NEZJJeaa3Fib7eybAO6GAtTRl+C7NPooSu
 vhIHWPXcfO8+US0yfvV7F7/0TqoJxJiwaI5TSSp9vE8Zi3dHHJ4yttS/3WLvXqQAAAA==
X-Change-ID: 20250514-ubx-safeboot-3758f22225ec
To: Johan Hovold <johan@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alejandro Enrique <alejandroe1@geotab.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747932696; l=1275;
 i=alejandroe1@geotab.com; s=20250514; h=from:subject:message-id;
 bh=NTC0IA2p9IVr/9NBNvhyqzF1HsQf3uhDF7IQNaKS+Nc=;
 b=/xUEI5CH82z+BjvENsXdv2Gu8D0Ag1Bwpln0iGToIIi67PC0xGOCnD9W4pOm84FPUy01A9YCh
 KADPVHqp0/nAfS+4Q2nuDqmD8qEZEUxzUL4BG2IMgYmxydhmd742xlY
X-Developer-Key: i=alejandroe1@geotab.com; a=ed25519;
 pk=xzHMPbqczL/tMsjXr26iLoHwIzLveHVnT+GIU4p1k38=
X-Endpoint-Received: by B4 Relay for alejandroe1@geotab.com/20250514 with auth_id=404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

U-Blox 8/M8 and M9 chips have a pin to start it in safeboot mode, to
be used to recover from situations where the flash content has become
corrupted and needs to be restored. If this pin is asserted at power
up or reset, the receiver starts in safeboot mode and GNSS operation
is disabled.

If this pin is wired to a GPIO in the host it should be deasserted
before powering up or resetting the GNSS.

This series adds support for handling the safeboot pin when probing
the driver.

Signed-off-by: Alejandro Enrique <alejandroe1@geotab.com>
---
Changes in v2:
- Add if/then to dt binding to disallow safeboot-gpios property for neo-6m
- Link to v1: https://lore.kernel.org/r/20250514-ubx-safeboot-v1-0-1ae771335356@geotab.com

---
Alejandro Enrique (2):
      dt-bindings: gnss: u-blox: add "safeboot-gpios" binding
      gnss: ubx: add support for the safeboot gpio

 Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml | 20 ++++++++++++++++----
 drivers/gnss/ubx.c                                        |  8 ++++++++
 2 files changed, 24 insertions(+), 4 deletions(-)
---
base-commit: 9c32cda43eb78f78c73aee4aa344b777714e259b
change-id: 20250514-ubx-safeboot-3758f22225ec

Best regards,
-- 
Alejandro Enrique <alejandroe1@geotab.com>

