From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Subject: [PATCH v11 0/7] i2c: xiic: use generic device property accessors
Date: Fri, 13 Feb 2026 00:15:15 +0000
Message-Id: <20260213-i2c-xiic-v11-0-5d18aea11bde@nexthop.ai>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABNtjmkC/3XRPW7DMAwF4KsEnqtAov4z9R5FB8miag2xAzk1U
 gS5e+UsZaF2JMHv4QG8DyvWgutwOtyHiltZyzK3QYiXwzBOYf5AVlJbDMDBcAHACozsVsrIZAz
 O56wxeDm080vFXG7PrLf3Nue6nNl1qhhIgNCcg1PmCFo6zwQLMX3WGqZzmF9nvF2n5XIMZc+by
 npd6tez2gZ76h8lNmCcCamyTlZJdJGG7C02SaUkUjaJ0Y5JgVYp91L9J1WTKkiMQWrBR+ykptI
 QqZt0LggTwFkQYycNlZZIs7d1gJBNNtr20lLpibRNWrCopHLeYu6k+5HABZGuyYQRUhLaJRE66
 amkX/FNjqiM11mDsamTglOqCBV8txC9N+0xIPUv+3g8vgEqt8RTtAIAAA==
X-Change-ID: 20260122-i2c-xiic-3ba89ff5ea93
To: Michal Simek <michal.simek@amd.com>, Andi Shyti <andi.shyti@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Andy Shevchenko <andriy.shevchenko@intel.com>, 
 linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Abdurrahman Hussain <abdurrahman@nexthop.ai>, Andrew Lunn <andrew@lunn.ch>, 
 Jonathan Cameron <jonathan.cameron@huawei.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770941721; l=3438;
 i=abdurrahman@nexthop.ai; s=20260119; h=from:subject:message-id;
 bh=Sb1Z9ToRtr8u+pAOPxIENcrNfGSnJsAfpeH6JTyv4M4=;
 b=PZ0XbQV8s2UWSCFbiogIumjF/qg7yBN1gXJJy+KjQPg3jmjsMZcpIscrCEGlRBpjjacXq9IGD
 o4SKeCIUAiwDq/ZxZmRqIN6lNHpQoyiLAU9itKro+9ayaad7sYYCV0U
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
Changes in v11:
- Cosmetic change to return 0 in patch 1.
- Remove pm_runtime_dont_use_autosuspend() in patch 1.
- Link to v10: https://lore.kernel.org/r/20260204-i2c-xiic-v10-0-c2b996425235@nexthop.ai

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

 drivers/i2c/busses/i2c-xiic.c | 98 +++++++++++++++++++------------------------
 1 file changed, 42 insertions(+), 56 deletions(-)
---
base-commit: 18f7fcd5e69a04df57b563360b88be72471d6b62
change-id: 20260122-i2c-xiic-3ba89ff5ea93

Best regards,
-- 
Abdurrahman Hussain <abdurrahman@nexthop.ai>

