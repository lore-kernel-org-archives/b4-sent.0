From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Subject: [PATCH v10 0/7] i2c: xiic: use generic device property accessors
Date: Wed, 04 Feb 2026 07:01:57 +0000
Message-Id: <20260204-i2c-xiic-v10-0-c2b996425235@nexthop.ai>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOXugmkC/3XRPW7DMAwF4KsEnqtAov4z9R5FB1qiag2xA9k1X
 AS5e+UsVeF2JMHv4QG8dzOVTHN3Od27Qmue8zTWQfCXUxcGHD+I5VgXHXAwXACwDIFtOQcme3Q
 +JU3oZVfPb4VS3p5Zb+91TmW6smUohE2A0JyDU+YMWjrPBMM+fpaCwxXH15G2ZZhuZ8x73pDnZ
 Spfz2or7Kl/lFiBcSakSjpaJcn1bcjeYpWtlI2UVVJvQ1SgVUxHqf6TqkqFknqUWvBAB6lbaRq
 pq3QOhUFwFkQ4SNNK20izt3VAkEwy2h6lbaVvpK3SgiUllfOW0kG6HwlcNNJVGamHGIV2UeBB+
 la2X/FVBlLG66TB2PhLPh6PbxwkFUh4AgAA
X-Change-ID: 20260122-i2c-xiic-3ba89ff5ea93
To: Michal Simek <michal.simek@amd.com>, Andi Shyti <andi.shyti@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Andy Shevchenko <andriy.shevchenko@intel.com>, 
 linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Abdurrahman Hussain <abdurrahman@nexthop.ai>, Andrew Lunn <andrew@lunn.ch>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770188524; l=3230;
 i=abdurrahman@nexthop.ai; s=20260119; h=from:subject:message-id;
 bh=xbYtXoLVabpU57x2RmdjqyOY1U9k1ZQ9kSUN4VeCGuY=;
 b=L3hRvrEH3VS3iFOO+kmUvZS/6u5JSJI2HiMMyhMV5jEAxk4LETpSeRQlAobKaT+TNSGQjvsFe
 OBJW7cJajlCBhGGsfekzT+P3uKMs/ROlAFYWaaqB2GAj7vb7agESVZ2
X-Developer-Key: i=abdurrahman@nexthop.ai; a=ed25519;
 pk=S+ysnf+NwMcBdHBlyKIUEAtaFGSIhQwcJcgcXhq0osg=
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/20260119 with auth_id=608
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- Switch to generic device property accessors.
- Switch to managed devm_ functions to simplify error handling.
- General cleanups.
- Skip clock setup on non-OF systems where clock is not specified via
firmware.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
Changes in v10:
- Moved dev_dbg() change from patch 4 to patch 5.
- Reworded description in patch 6.
- Addressed Andy's comment in patch 7 (&pdev->dev -> dev).
- Link to v9: https://lore.kernel.org/r/20260202-i2c-xiic-v9-0-ce4695f5267d@nexthop.ai

Changes in v9:
- Fix an issue found by the test robot in the cleanup patch.
- Reworded the clock change description.
- Add a patch to switch to i2c_add_numbered_adapter().
- Link to v8: https://lore.kernel.org/r/20260201-i2c-xiic-v8-0-deb2dd158d1a@nexthop.ai

Changes in v8:
- Made the clock change the last patch in the series.
- Reworded the clock change description.
- Changed dev->fwnode to dev_fwnode(dev).
- Link to v7: https://lore.kernel.org/r/20260129-i2c-xiic-v7-0-727e434897ef@nexthop.ai

Changes in v7:
- Drop the dt-bindings patch.
- Skip clock setup on non-OF systems.
- Minor commit body rewording.
- Applied code-review trailers with `b4 trailers -u`
- Link to v6: https://lore.kernel.org/r/20260127-i2c-xiic-v6-0-e82e2f6f657c@nexthop.ai

Changes in v6:
- Cosmetic changes to address the comments.
- Added a patch to use resource format specifier in debug log.
- Link to v5: https://lore.kernel.org/r/20260126-i2c-xiic-v5-0-88a16a28721c@nexthop.ai

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
Abdurrahman Hussain (7):
      i2c: xiic: switch to devres managed APIs
      i2c: xiic: remove duplicate error message
      i2c: xiic: switch to generic device property accessors
      i2c: xiic: cosmetic cleanup
      i2c: xiic: cosmetic: use resource format specifier in debug log
      i2c: xiic: use numbered adapter registration
      i2c: xiic: skip input clock setup on non-OF systems

 drivers/i2c/busses/i2c-xiic.c | 99 +++++++++++++++++++------------------------
 1 file changed, 43 insertions(+), 56 deletions(-)
---
base-commit: 18f7fcd5e69a04df57b563360b88be72471d6b62
change-id: 20260122-i2c-xiic-3ba89ff5ea93

Best regards,
-- 
Abdurrahman Hussain <abdurrahman@nexthop.ai>

