From: Armandas Kvietkus <armandas.kvietkus@proton.me>
Subject: [PATCH 0/2] Add Maxim DS28E16 battery cycle counter
Date: Tue, 24 Nov 2026 18:43:19 +0100
Message-Id: <20261124-ds28e16-v1-0-bed431df0578@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyMT3ZRiI4tUQzPdlORUgxRjC8NUQ6MUJaDqgqLUtMwKsEnRsRB+cWl
 SVmpyCUi7Um0tAEZkbdtrAAAA
X-Change-ID: 20261124-ds28e16-dce0d381e12d
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Armandas Kvietkus <armandas.kvietkus@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795542200; l=900;
 i=armandas.kvietkus@proton.me; h=from:subject:message-id;
 bh=rBhlGjEYg12dV0lDhTkpZrORnOq6vZZO6CMKjetk0D8=;
 b=uA7zolE9PS3KyALvplvduaDIe7FbFcploKcC0fsVH7/impjS8IqYkMYUtnlFzztS6Ml/mamDJ
 J9VXuaaQGeuAZyQGgBO0sS8RMCdlcOloWoGgg6tEv1+1x/KPhABRyky
X-Developer-Key: i=armandas.kvietkus@proton.me; a=ed25519;
 pk=wuqmImJ9sKlDVcwALOvfGhjj7G8EBjjM4TpCdmlrAf8=
X-Endpoint-Received: by B4 Relay for armandas.kvietkus@proton.me/default with auth_id=974
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DS28E16 is a battery authenticator that keeps the cycle count of the
pack in a decrement counter. This adds a binding and a power supply
driver that reads the count and lets userspace step it by one.

---
Armandas Kvietkus (2):
      dt-bindings: power: supply: Add Maxim DS28E16
      power: supply: Add Maxim DS28E16 battery cycle counter driver

 .../bindings/power/supply/maxim,ds28e16.yaml       |  39 +++
 MAINTAINERS                                        |   7 +
 drivers/power/supply/Kconfig                       |  11 +
 drivers/power/supply/Makefile                      |   1 +
 drivers/power/supply/ds28e16_battery.c             | 335 +++++++++++++++++++++
 5 files changed, 393 insertions(+)
---
base-commit: abbe0a96bdbadae9e29489a1528fa436c55aca25
change-id: 20261124-ds28e16-dce0d381e12d

Best regards,
--  
Armandas Kvietkus <armandas.kvietkus@proton.me>

