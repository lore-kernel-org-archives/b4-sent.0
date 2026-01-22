From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Subject: [PATCH v2 0/2] i2c: xiic: use generic device property accessors
Date: Thu, 22 Jan 2026 08:32:30 +0000
Message-Id: <20260122-i2c-xiic-v2-0-134f5d743e8b@nexthop.ai>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJ7gcWkC/03MQQqDQAxA0atI1o2MsYp21XuULqJmOlk4SsYWQ
 bx7h666fPD5ByQxlQS34gCTjyZdYgZdChgDx5egTtlAjlpXEaHSiLvqiPXAXe99I9zXkPPVxOv
 +Wz2e2d6WGbdgwn+DqnGOumtbUlN3PVbIw/Q24zBzvEfZt7CsJSuc5xfG2wXWmgAAAA==
X-Change-ID: 20260122-i2c-xiic-3ba89ff5ea93
To: Michal Simek <michal.simek@amd.com>, Andi Shyti <andi.shyti@kernel.org>
Cc: Andy Shevchenko <andriy.shevchenko@intel.com>, 
 linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769070755; l=951;
 i=abdurrahman@nexthop.ai; s=20260119; h=from:subject:message-id;
 bh=LLhB3J4m5a0dTpoW8ctYFKn5mu2uLbvwih+4M0rsLMw=;
 b=+tZ5Zf3eiPLTTqfzu0IBnoNfd1f4U1RPJdxysXHB1nD2bss1wzmnJw6G50cAfKiONnI38O2zC
 /Y+ZUkpeoGvAl2HZE38t5EzilD1jGZquagjFfSeVLJwpxFXF18IjUyc
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
Abdurrahman Hussain (2):
      i2c: xiic: switch to generic device property accessors
      i2c: xiic: make the clock optional

 drivers/i2c/busses/i2c-xiic.c | 60 +++++++++++++++++++------------------------
 1 file changed, 27 insertions(+), 33 deletions(-)
---
base-commit: 944aacb68baf7624ab8d277d0ebf07f025ca137c
change-id: 20260122-i2c-xiic-3ba89ff5ea93

Best regards,
-- 
Abdurrahman Hussain <abdurrahman@nexthop.ai>

