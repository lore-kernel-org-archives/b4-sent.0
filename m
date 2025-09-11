From: Alejandro Enrique <alejandroe1@geotab.com>
Subject: [PATCH v3 0/2] Add support for safeboot pin to UBlox GNSS driver
Date: Thu, 11 Sep 2025 14:58:27 +0200
Message-Id: <20250911-ubx-safeboot-v3-0-32fe6b882a3c@geotab.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHPHwmgC/3WMwQ7CIBAFf6XZsxhYRNCT/2E8AG5bDoqBSmqa/
 ru0JzXx3eYlMxNkSoEyHJsJEpWQQ7xXkJsGfG/vHbFwrQzIUXElduzpRpZtSy7GgUmtTIt1ijx
 U5ZGoDeOaO18q9yEPMb3WehHL+ydUBONMWNJaSKmk2p86ioN1Wx9vsJQKftiIPzZWmxuPKLVxx
 h++7Hme33Ss3d/nAAAA
X-Change-ID: 20250514-ubx-safeboot-3758f22225ec
To: Johan Hovold <johan@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alejandro Enrique <alejandroe1@geotab.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757595528; l=1418;
 i=alejandroe1@geotab.com; s=20250514; h=from:subject:message-id;
 bh=HgKP3M2Ccgb2WIvb1cNpikhrRw5XFgn3Ig1dMQEk+l4=;
 b=HPcL17RK+Ht6IPBGqReMPfYtLVhx+0zXovmOzatE7co3wMDFVmEk7fABp+sJmz2WOPp3bVrlV
 4QCcyorEcqDCeXstKvzT6dOKvi8JQore5+rCLMHr7RxjBkBow8gHQc9
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
Changes in v3:
- Rebase on top of latest gnss-linus tree
- Link to v2: https://lore.kernel.org/r/20250522-ubx-safeboot-v2-0-08c22378b8c9@geotab.com

Changes in v2:
- Add if/then to dt binding to disallow safeboot-gpios property for neo-6m
- Link to v1: https://lore.kernel.org/r/20250514-ubx-safeboot-v1-0-1ae771335356@geotab.com

---
Alejandro Enrique (2):
      dt-bindings: gnss: u-blox: add "safeboot-gpios" binding
      gnss: ubx: add support for the safeboot gpio

 .../devicetree/bindings/gnss/u-blox,neo-6m.yaml      | 20 ++++++++++++++++----
 drivers/gnss/ubx.c                                   |  8 ++++++++
 2 files changed, 24 insertions(+), 4 deletions(-)
---
base-commit: 1b237f190eb3d36f52dffe07a40b5eb210280e00
change-id: 20250514-ubx-safeboot-3758f22225ec

Best regards,
-- 
Alejandro Enrique <alejandroe1@geotab.com>

