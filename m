From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Subject: [PATCH v3 0/5] i2c: xiic: use generic device property accessors
Date: Fri, 23 Jan 2026 08:02:43 +0000
Message-Id: <20260123-i2c-xiic-v3-0-eb7cd4254dfb@nexthop.ai>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACQrc2kC/23OOw6DMBBF0a0g1xlkj4GYVNlHRGFgHE/BRzZBR
 Ii9B6goUl7p6eitIlJgiuKRrCLQzJGHfg99S0Tjbf8m4HZvgRILqRCBsYGFuQFdW1M6l5Mttdj
 nYyDHy0m9qr1dGDqYfCB7AVQuJZqsSDHXpgQFtm4/IVjf2f7Z0zL5YUwtH57nOA3hez6b8VD/n
 JgRJCiduby9Z5pMfUWqbdt+Nx4SmeEAAAA=
X-Change-ID: 20260122-i2c-xiic-3ba89ff5ea93
To: Michal Simek <michal.simek@amd.com>, Andi Shyti <andi.shyti@kernel.org>
Cc: Andy Shevchenko <andriy.shevchenko@intel.com>, 
 linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769155384; l=1405;
 i=abdurrahman@nexthop.ai; s=20260119; h=from:subject:message-id;
 bh=1rwOw+x2PuObmHQg0PSYLfFOWrx5Tza0EXXyewj+reY=;
 b=USCULF/Lt5spK7qklBMl8/C7UImXxBOgAQSZhQzHy4Un6pnZOdalSTsrFx40NPp29mtap4Ceq
 2mnIqUUI5wRDBX1nEhY0RzJZBjQVzfpPeu33DzJW3XmvnaZBlvBoABY
X-Developer-Key: i=abdurrahman@nexthop.ai; a=ed25519;
 pk=S+ysnf+NwMcBdHBlyKIUEAtaFGSIhQwcJcgcXhq0osg=
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/20260119 with auth_id=608
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Switch to generic device property accessors and make minor code
refactoring.

Make the clock optional since the driver is designed to operate without
explicit configuration in firmware thus making it useful on platforms
where clock is not or cannot be provided.

Changed in v2:

* Split the patch into two independent changes.
* Added struct device *dev at the top of probe() and remove() to re-use.
* Switched to device_set_node(...)

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
Changes in v3:
- Reorder the "optional clock" patch to be the first in the series. 
- Add a patch to switch to devm_mutex_init().
- Remove dup message in error path.
- Cosmetic: use temporary dev variable.
- Link to v2: https://lore.kernel.org/r/20260122-i2c-xiic-v2-0-134f5d743e8b@nexthop.ai

---
Abdurrahman Hussain (5):
      i2c: xiic: make the clock optional
      i2c: xiic: switch to managed version of mutex_init
      i2c: xiic: remove duplicate error message
      i2c: xiic: switch to generic device property accessors
      i2c: xiic: minor cosmetic cleanup

 drivers/i2c/busses/i2c-xiic.c | 74 ++++++++++++++++++++-----------------------
 1 file changed, 35 insertions(+), 39 deletions(-)
---
base-commit: 944aacb68baf7624ab8d277d0ebf07f025ca137c
change-id: 20260122-i2c-xiic-3ba89ff5ea93

Best regards,
-- 
Abdurrahman Hussain <abdurrahman@nexthop.ai>

