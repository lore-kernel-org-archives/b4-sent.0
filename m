From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Subject: [PATCH v5 0/6] i2c: xiic: use generic device property accessors
Date: Mon, 26 Jan 2026 17:08:15 +0000
Message-Id: <20260126-i2c-xiic-v5-0-88a16a28721c@nexthop.ai>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAH+fd2kC/3WOQW7DIBBFrxKxLhGegcTOqveIuhhgKLOIHWHXc
 hT57sVZuWq7fNJ/T/+pRi7Co7ocnqrwLKMMfQX3dlAhU//JWmJlBQZOpgHQAkEvIkGjp7ZLyTF
 1qOr8XjjJ8kpdPyqnMtz0lAvTLtA4Y6C1pyM4bDvdaPLxqxTKN+rfe16mPNyPJFsvyzgN5fF6N
 sNW/ePEDNroBm1y8WyRW7+PbC9m3Ju4M7Ga7M8hWnA2pt+m/c+01bSE7AldYwL/MNd1/QYbsqa
 iVQEAAA==
X-Change-ID: 20260122-i2c-xiic-3ba89ff5ea93
To: Michal Simek <michal.simek@amd.com>, Andi Shyti <andi.shyti@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, info@mocean-labs.com
Cc: Andy Shevchenko <andriy.shevchenko@intel.com>, 
 linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769447300; l=2044;
 i=abdurrahman@nexthop.ai; s=20260119; h=from:subject:message-id;
 bh=VW73wEDlwm86XhzmqjnzsOO/GIvv7ArJjK3GOMgSBcE=;
 b=8Q/hfEyzU9oetCA/lp4xPmLum414rzPxHu/AuVZD4ceCsOa6W4AvAI49TJN3wt8SDE03wwRB1
 kMApOawg1wHCAYOgM3PsjhSaASlZkB6a0M54v0qBXMkOFfGLn9wUeqC
X-Developer-Key: i=abdurrahman@nexthop.ai; a=ed25519;
 pk=S+ysnf+NwMcBdHBlyKIUEAtaFGSIhQwcJcgcXhq0osg=
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/20260119 with auth_id=608
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Switch to generic device property accessors.

Switch to managed devm_ functions to simplify error handling.

Make the clock optional since the driver is designed to operate without
explicit configuration in firmware thus making it useful on platforms
where clock is not or cannot be provided.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
Changes in v5:
- Reorder the cosmetic patch to be the last in the series.
- Added a documentation patch to describe the optional clock.
- Minor commit body rewording.
- Link to v4: https://lore.kernel.org/r/20260123-i2c-xiic-v4-0-4a3eba3510ce@nexthop.ai

Changes in v4:
- Reorder the cosmetic patch to be the first in the series.
- Amend the mutex_init patch to also switch to the managed pm_runtime_
  variant.
- Link to v3: https://lore.kernel.org/r/20260123-i2c-xiic-v3-0-eb7cd4254dfb@nexthop.ai

Changes in v3:
- Reorder the "optional clock" patch to be the first in the series. 
- Add a patch to switch to devm_mutex_init().
- Remove dup message in error path.
- Cosmetic: use temporary dev variable.
- Link to v2: https://lore.kernel.org/r/20260122-i2c-xiic-v2-0-134f5d743e8b@nexthop.ai

Changes in v2:
- Split the patch into two independent changes.
- Added struct device *dev at the top of probe() and remove() to re-use.
- Switched to device_set_node(...)

---
Abdurrahman Hussain (6):
      dt-bindings: i2c: xiic: make clocks optional
      i2c: xiic: make the clock optional
      i2c: xiic: switch to devres managed APIs
      i2c: xiic: remove duplicate error message
      i2c: xiic: switch to generic device property accessors
      i2c: xiic: cosmetic cleanup

 .../bindings/i2c/xlnx,xps-iic-2.00.a.yaml          |  1 -
 drivers/i2c/busses/i2c-xiic.c                      | 81 +++++++++-------------
 2 files changed, 34 insertions(+), 48 deletions(-)
---
base-commit: 24d479d26b25bce5faea3ddd9fa8f3a6c3129ea7
change-id: 20260122-i2c-xiic-3ba89ff5ea93

Best regards,
-- 
Abdurrahman Hussain <abdurrahman@nexthop.ai>

