From: Amit Sunil Dhamne <amitsd@google.com>
Subject: [PATCH 0/5] Add support for Battery Status & Battery Caps AMS in
 TCPM
Date: Wed, 12 Mar 2025 16:42:00 -0700
Message-Id: <20250312-batt_ops-v1-0-88e0bb3129fd@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMkb0mcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDY0ND3aTEkpL4/IJi3aRUw6QUc8PkRCNTEyWg8oKi1LTMCrBR0bG1tQD
 JEMecWgAAAA==
X-Change-ID: 20250311-batt_ops-be1bd71ca254
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Sebastian Reichel <sre@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <len.brown@intel.com>, 
 Pavel Machek <pavel@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, linux-pm@vger.kernel.org, 
 RD Babiera <rdbabiera@google.com>, Kyle Tso <kyletso@google.com>, 
 Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741822998; l=1546;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=90OuS2yk7g7bxyQlFmmSVP8LGE/eGIxU1ogAteq6FsQ=;
 b=zsL7hGB9X2//AJOcUw5HcZ2DY008IsSVM3aNDnOjpwzKN60kqxUEfHb8ORIW8KJMzcJ3L8fXH
 vDkHVUwomUuBDN/ZOODp4w5hu8fKuyQuPPptydVvvtFxZjCiyYDtYO5
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support for Battery Status & Battery Caps messages in response to
Get_Battery_Status & Get_Battery_Cap request is required by USB PD devices
powered by battery, as per "USB PD R3.1 V1.8 Spec", "6.13 Message
Applicability" section. This patchset adds support for these AMSes
to achieve greater compliance with the spec.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
Amit Sunil Dhamne (5):
      dt-bindings: connector: add fixed-batteries property
      power: supply: core: add function to get supplies from fwnode
      usb: typec: tcpm: Add support for Battery Status response message
      power: supply: core: add vendor and product id properties
      usb: typec: tcpm: Add support for Battery Cap response message

 Documentation/ABI/testing/sysfs-class-power        |  20 ++
 .../bindings/connector/usb-connector.yaml          |   8 +
 .../devicetree/bindings/usb/maxim,max33359.yaml    |   1 +
 Documentation/power/power_supply_class.rst         |  11 ++
 drivers/power/supply/power_supply_core.c           |  60 ++++++
 drivers/power/supply/power_supply_sysfs.c          |   2 +
 drivers/usb/typec/tcpm/tcpm.c                      | 217 ++++++++++++++++++++-
 include/linux/power_supply.h                       |   7 +
 include/linux/usb/pd.h                             |  65 ++++++
 9 files changed, 388 insertions(+), 3 deletions(-)
---
base-commit: 80e54e84911a923c40d7bee33a34c1b4be148d7a
change-id: 20250311-batt_ops-be1bd71ca254

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

