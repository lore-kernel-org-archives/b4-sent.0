From: Alejandro Enrique <alejandroe1@geotab.com>
Subject: [PATCH 0/2] Add u-blox,neo-m9 compatible
Date: Wed, 14 May 2025 13:55:53 +0200
Message-Id: <20250514-ubx-m9-v1-0-193973a4f3ca@geotab.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMqEJGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDU0MT3dKkCt1cS11zg5Q0g7QUi2QTiyQloOKCotS0zAqwQdGxtbUAwmY
 FzVgAAAA=
X-Change-ID: 20250514-ubx-m9-70df0fd8c48b
To: Johan Hovold <johan@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Alejandro Enrique <alejandroe1@geotab.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747223768; l=668;
 i=alejandroe1@geotab.com; s=20250514; h=from:subject:message-id;
 bh=FxUj0Q3Hbzzlo9vltMkfS3G/1BLac1smAJqfGR4/wdg=;
 b=Fclj0erYWxoN7IjKp0yeMD6wAsRkETKDIqX3C3DQKPx96XyFgVi7V3R6LRMCKld0+U3kWJPmT
 7Dl3VW5yMMpBik9K5deywSu4j0cPHsf5mmvqZvuKiZDrCSOrGe/9QGe
X-Developer-Key: i=alejandroe1@geotab.com; a=ed25519;
 pk=xzHMPbqczL/tMsjXr26iLoHwIzLveHVnT+GIU4p1k38=
X-Endpoint-Received: by B4 Relay for alejandroe1@geotab.com/20250514 with auth_id=404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series just add the compatible string for u-blox NEO-9M module. I
have tested the driver with such a module and it is working fine. 

Signed-off-by: Alejandro Enrique <alejandroe1@geotab.com>
---
Alejandro Enrique (2):
      dt-bindings: gnss: add u-blox,neo-9m compatible
      gnss: ubx: add u-blox,neo-m9 compatible

 Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml | 1 +
 drivers/gnss/ubx.c                                        | 1 +
 2 files changed, 2 insertions(+)
---
base-commit: 9c32cda43eb78f78c73aee4aa344b777714e259b
change-id: 20250514-ubx-m9-70df0fd8c48b

Best regards,
-- 
Alejandro Enrique <alejandroe1@geotab.com>

