From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Subject: [PATCH v4 0/5] i2c: xiic: use generic device property accessors
Date: Fri, 23 Jan 2026 16:34:13 +0000
Message-Id: <20260123-i2c-xiic-v4-0-4a3eba3510ce@nexthop.ai>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAWjc2kC/22OQQ6CMBBFr2K6dkiZtgiuvIdxUejUzkIgBQmGc
 HcLK0xcvuS/l7+IgSLTIK6nRUSaeOCuTaDPJ9EE2z4J2CUWKLGQOSIwNjAzN6BqW1beG7KVEmn
 eR/I876n7I7GP3QvGEMkeArmREktdZGhUWUEOtnbvGG142fbW0jyGrs8sb73Aw9jFz/5swq365
 8SEICFX2ht30YrK+hjZXkzqaKqDqZJJ9aVxGo12/tdc1/UL3bsVxBsBAAA=
X-Change-ID: 20260122-i2c-xiic-3ba89ff5ea93
To: Michal Simek <michal.simek@amd.com>, Andi Shyti <andi.shyti@kernel.org>
Cc: Andy Shevchenko <andriy.shevchenko@intel.com>, 
 linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769186056; l=1708;
 i=abdurrahman@nexthop.ai; s=20260119; h=from:subject:message-id;
 bh=SH2RWWiwpkeWyZQeIGuiuLmQkTXrbQiB6gtTSnYx/14=;
 b=flb3w1tYsbw3Rosf7jIaipmBHlhMiYFVpLk6X/cKjH494wEKjC4uGWHOqcn+Seh/WM9J0DYCi
 PsXPY+dxdfnD7Pt5LDibPjYywOKDLlBX9IKIV7N3hsOt6CzxS1vxM2X
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
Abdurrahman Hussain (5):
      i2c: xiic: minor cosmetic cleanup
      i2c: xiic: make the clock optional
      i2c: xiic: switch to devm_ managed apis to simplify the error code paths
      i2c: xiic: remove duplicate error message
      i2c: xiic: switch to generic device property accessors

 drivers/i2c/busses/i2c-xiic.c | 83 ++++++++++++++++++-------------------------
 1 file changed, 35 insertions(+), 48 deletions(-)
---
base-commit: 24d479d26b25bce5faea3ddd9fa8f3a6c3129ea7
change-id: 20260122-i2c-xiic-3ba89ff5ea93

Best regards,
-- 
Abdurrahman Hussain <abdurrahman@nexthop.ai>

