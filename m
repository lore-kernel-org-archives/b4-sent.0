From: Amit Sunil Dhamne <amitsd@google.com>
Subject: [PATCH v2 0/5] Add support for Battery Status & Battery Caps AMS
 in TCPM
Date: Wed, 07 May 2025 18:00:21 -0700
Message-Id: <20250507-batt_ops-v2-0-8d06130bffe6@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACUCHGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDI1MDY0ND3aTEkpL4/IJi3aRUw6QUc8PkRCNTEyWg8oKi1LTMCrBR0bG1tQD
 o5/1GWgAAAA==
X-Change-ID: 20250311-batt_ops-be1bd71ca254
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Sebastian Reichel <sre@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <len.brown@intel.com>, 
 Pavel Machek <pavel@kernel.org>
Cc: Kyle Tso <kyletso@google.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-pm@vger.kernel.org, Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746666154; l=1861;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=LRcV+pKioj0dnQiQ87GE22M3+IfV3Fs50YQalR4s3E0=;
 b=3Id+Nk6+E6cUAu6NLSo6T6dh5n72Vz78BzucEQ2NbPWm4zzcW9Av99ytXVakATFYyAJxyWdry
 7zaAHUj5dYkBMJpnELQcs7AoFNoVeswI2MeGakLMn6l4h9X2ehao/qt
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
Changes in v2:
  - Instead of introducing new "fixed-batteries" property to pass
    reference to FG, use OF graph by extending "ports" property
    definition. (suggested by Krzysztof).
  - Demonstration of binding usage in gs101-oriole will be in a
    different patchset.

---
Amit Sunil Dhamne (5):
      dt-bindings: connector: extend ports property to model power connections
      power: supply: core: add helper to get power supply given a fwnode
      usb: typec: tcpm: Add support for Battery Status response message
      power: supply: core: add vendor and product id properties
      usb: typec: tcpm: Add support for Battery Cap response message

 Documentation/ABI/testing/sysfs-class-power        |  19 +-
 .../bindings/connector/usb-connector.yaml          |  20 +-
 .../devicetree/bindings/usb/maxim,max33359.yaml    |  25 +++
 Documentation/power/power_supply_class.rst         |  11 ++
 drivers/power/supply/power_supply_core.c           |  30 +++
 drivers/power/supply/power_supply_sysfs.c          |   2 +
 drivers/usb/typec/tcpm/tcpm.c                      | 208 ++++++++++++++++++++-
 include/linux/power_supply.h                       |   5 +
 include/linux/usb/pd.h                             |  65 +++++++
 9 files changed, 371 insertions(+), 14 deletions(-)
---
base-commit: 80e54e84911a923c40d7bee33a34c1b4be148d7a
change-id: 20250311-batt_ops-be1bd71ca254

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

