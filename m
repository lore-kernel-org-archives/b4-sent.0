From: Thomas Antoine <t.antoine@uclouvain.be>
Subject: [PATCH v6 0/2] MAX77759 Fuel Gauge driver support
Date: Mon, 15 Sep 2025 12:14:09 +0200
Message-Id: <20250915-b4-gs101_max77759_fg-v6-0-31d08581500f@uclouvain.be>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAPHmx2gC/4XRwWrDMAwG4FcpPs9DtuU47mnvMUqxEzk1bMlmN
 6al5N3ndhuF0bCL4BfoE0gXlilFymy7ubBEJeY4jTU0TxvWHdw4EI99zUyCRFEL98iHLEDs393
 JGKPtPgwcQZJUwqFXitXRj0Qhnm7s667mQ8zHKZ1vW4q4dv8Bi+DAbdvL4IwPpOBl7t6mubg4P
 ntiV7PIX0eDWHVkdVpjtXWevAnhgYN3R0u14mB1PFoLSEo7hQ+c5u60gCuOrg4oh0BNB6T6P87
 yfbxEn3N9xfHngsvyBQrqcxyoAQAA
X-Change-ID: 20241202-b4-gs101_max77759_fg-402e231a4b33
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sebastian Reichel <sre@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>
Cc: linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, Thomas Antoine <t.antoine@uclouvain.be>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757931256; l=7205;
 i=t.antoine@uclouvain.be; s=20241202; h=from:subject:message-id;
 bh=SIEs9n6hrG+yng86tGVw2VfwaKQOVNscQokfGNTf4Hk=;
 b=g2M3SOd04Q0Pg8cjMAaTjzMFSeU0J/YFyAfuve6C1EkvzBBgrOEKN7b+02evxbVmn/6MmWZ/9
 WYbfdWoq0xsDkZuMXzrJ4sZ006ZFo5lmC3NUpIxwcVH+Z38WE9AD/sx
X-Developer-Key: i=t.antoine@uclouvain.be; a=ed25519;
 pk=sw7UYl31W1LTpgWRiX4xIF5x6ok7YWZ6XZnHqy/d3dY=
X-Endpoint-Received: by B4 Relay for t.antoine@uclouvain.be/20241202 with auth_id=289
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The gs101-oriole (Google Pixel 6) and gs101-raven (Google Pixel 6 Pro)
have a Maxim MAX77759 which provides a fuel gauge functionality based
on the MAX M5 fuel gauge.

Add a driver for the fuel gauge of the Maxim MAX77759 based on the
one for the Maxim MAX1720x which also uses the MAX M5 fuel gauge.

A future patch will add both gs101-oriole and gs101-raven as clients.

Signed-off-by: Thomas Antoine <t.antoine@uclouvain.be>
---
Changes in v6:
- Remove devicetree and defconfig changes from patch
- Driver: Check return of power_supply_get_battery_info (Peter Griffin)
- Binding: Fix properties order of the example and add power supply ref
(Krzysztof Kozlowski)
- Link to v5: https://lore.kernel.org/all/20250804-b4-gs101_max77759_fg-v5-0-03a40e6c0e3d@uclouvain.be

Changes in v5:
- Separate MAX77759 from MAX1720x for clarity
- Remove voltage reporting
- Add initialization of the chip
- Add device dependent initialization data
- Add access to eeprom for access to non-volatile backup data.
- Link to v4: https://lore.kernel.org/r/20250523-b4-gs101_max77759_fg-v4-0-b49904e35a34@uclouvain.be

Changes in v4:
- Make first patch standalone
- Separate MAX77759 defines from MAX1720x defines (Dimitri Fedrau)
- Inline device name property (Dimitri Fedrau)
- Separate MAX77759 capacity lsb logic from the MAX1720x capacity
  computation (Dimitri Fedrau)
- Use device_property_read_u32 instead of of_property_read_u32
  (Sebastian Reichel)
- Removed leftover debugs
- Move shunt-resistor-micro-ohms to out of allOf:if: (Krzysztof Kozlowski)
- Fix reg-names constraints
- Fix style errors
- Link to v3: https://lore.kernel.org/r/20250421-b4-gs101_max77759_fg-v3-0-50cd8caf9017@uclouvain.be

Changes in v3:
- Update base tree to avoid conflicts
- Fix capacity computation for max1720x
- Add separate properties for the max7759 to disable non-functional ones
- Take TASKPERIOD into account for voltage computation of max77759
- Simplify vcell computation (Dimitri Fedrau)
- Switch has_nvmem to bool and keep it only in chip_data (Dimitri Fedrau)
- Drop the yes_range from the write table (Sebastian Reichel)
- Add test_power_supply_properties.sh to cover letter (Sebastian Reichel)
- Switch back some changes to binding and actually use allOf:if: to
  restrict constraints (Krzysztof Kozlowski)
- Fix style errors
- Link to v2: https://lore.kernel.org/r/20250102-b4-gs101_max77759_fg-v2-0-87959abeb7ff@uclouvain.be

Changes in v2:
- Add fallback for voltage measurement (André Draszik)
- Add regmap for the max77759 (André Draszik)
- Add chip identification for the max77759 (André Draszik, Peter Griffin)
- Move RSense value to a devicetree property shunt-resistor-micro-ohms
  (Dimitri Fedrau, André Draszik)
- Use allOf:if to narrow binding per variant (Krzysztof Kozlowski)
- Remove binding example (Krzysztof Kozlowski)
- Change defconfig order to follow savedefconfig (Krzysztof Kozlowski)
- Fix style errors
- Link to v1: https://lore.kernel.org/r/20241202-b4-gs101_max77759_fg-v1-0-98d2fa7bfe30@uclouvain.be

tools/testing/selftests/power_supply/test_power_supply_properties.sh:
gs101-oriole:
  # Testing device max77759-fg
  ok 1 max77759-fg.exists
  ok 2 max77759-fg.uevent.NAME
  ok 3 max77759-fg.sysfs.type
  ok 4 max77759-fg.uevent.TYPE
  ok 5 max77759-fg.sysfs.usb_type # SKIP
  ok 6 max77759-fg.sysfs.online # SKIP
  # Reported: '1' ()
  ok 7 max77759-fg.sysfs.present
  ok 8 max77759-fg.sysfs.status # SKIP
  # Reported: '99' % ()
  ok 9 max77759-fg.sysfs.capacity
  ok 10 max77759-fg.sysfs.capacity_level # SKIP
  # Reported: 'MAX77759' ()
  ok 11 max77759-fg.sysfs.model_name
  # Reported: 'Maxim Integrated' ()
  ok 12 max77759-fg.sysfs.manufacturer
  ok 13 max77759-fg.sysfs.serial_number # SKIP
  ok 14 max77759-fg.sysfs.technology # SKIP
  ok 15 max77759-fg.sysfs.cycle_count # SKIP
  ok 16 max77759-fg.sysfs.scope # SKIP
  ok 17 max77759-fg.sysfs.input_current_limit # SKIP
  ok 18 max77759-fg.sysfs.input_voltage_limit # SKIP
  ok 19 max77759-fg.sysfs.voltage_now # SKIP
  ok 20 max77759-fg.sysfs.voltage_min # SKIP
  ok 21 max77759-fg.sysfs.voltage_max # SKIP
  ok 22 max77759-fg.sysfs.voltage_min_design # SKIP
  ok 23 max77759-fg.sysfs.voltage_max_design # SKIP
  # Reported: '1562' uA (1.562 mA)
  ok 24 max77759-fg.sysfs.current_now
  ok 25 max77759-fg.sysfs.current_max # SKIP
  ok 26 max77759-fg.sysfs.charge_now # SKIP
  # Reported: '4562000' uAh (4.562 Ah)
  ok 27 max77759-fg.sysfs.charge_full
  # Reported: '4524000' uAh (4.524 Ah)
  ok 28 max77759-fg.sysfs.charge_full_design
  ok 29 max77759-fg.sysfs.power_now # SKIP
  ok 30 max77759-fg.sysfs.energy_now # SKIP
  ok 31 max77759-fg.sysfs.energy_full # SKIP
  ok 32 max77759-fg.sysfs.energy_full_design # SKIP
  ok 33 max77759-fg.sysfs.energy_full_design # SKIP

  gs101-raven:
  # Testing device max77759-fg
  ok 1 max77759-fg.exists
  ok 2 max77759-fg.uevent.NAME
  ok 3 max77759-fg.sysfs.type
  ok 4 max77759-fg.uevent.TYPE
  ok 5 max77759-fg.sysfs.usb_type # SKIP
  ok 6 max77759-fg.sysfs.online # SKIP
  # Reported: '1' ()
  ok 7 max77759-fg.sysfs.present
  ok 8 max77759-fg.sysfs.status # SKIP
  # Reported: '100' % ()
  ok 9 max77759-fg.sysfs.capacity
  ok 10 max77759-fg.sysfs.capacity_level # SKIP
  # Reported: 'MAX77759' ()
  ok 11 max77759-fg.sysfs.model_name
  # Reported: 'Maxim Integrated' ()
  ok 12 max77759-fg.sysfs.manufacturer
  ok 13 max77759-fg.sysfs.serial_number # SKIP
  ok 14 max77759-fg.sysfs.technology # SKIP
  ok 15 max77759-fg.sysfs.cycle_count # SKIP
  ok 16 max77759-fg.sysfs.scope # SKIP
  ok 17 max77759-fg.sysfs.input_current_limit # SKIP
  ok 18 max77759-fg.sysfs.input_voltage_limit # SKIP
  ok 19 max77759-fg.sysfs.voltage_now # SKIP
  ok 20 max77759-fg.sysfs.voltage_min # SKIP
  ok 21 max77759-fg.sysfs.voltage_max # SKIP
  ok 22 max77759-fg.sysfs.voltage_min_design # SKIP
  ok 23 max77759-fg.sysfs.voltage_max_design # SKIP
  # Reported: '4375' uA (4.375 mA)
  ok 24 max77759-fg.sysfs.current_now
  ok 25 max77759-fg.sysfs.current_max # SKIP
  ok 26 max77759-fg.sysfs.charge_now # SKIP
  # Reported: '4676000' uAh (4.676 Ah)
  ok 27 max77759-fg.sysfs.charge_full
  # Reported: '4904000' uAh (4.904 Ah)
  ok 28 max77759-fg.sysfs.charge_full_design
  ok 29 max77759-fg.sysfs.power_now # SKIP
  ok 30 max77759-fg.sysfs.energy_now # SKIP
  ok 31 max77759-fg.sysfs.energy_full # SKIP
  ok 32 max77759-fg.sysfs.energy_full_design # SKIP
  ok 33 max77759-fg.sysfs.energy_full_design # SKIP

---
Thomas Antoine (2):
      power: supply: add support for MAX77759 fuel gauge
      dt-bindings: power: supply: add support for MAX77759 fuel gauge

 .../bindings/power/supply/maxim,max77759.yaml      |  78 +++
 drivers/power/supply/Kconfig                       |  14 +
 drivers/power/supply/Makefile                      |   1 +
 drivers/power/supply/max77759_battery.c            | 652 +++++++++++++++++++++
 4 files changed, 745 insertions(+)
---
base-commit: 590b221ed4256fd6c34d3dea77aa5bd6e741bbc1
change-id: 20241202-b4-gs101_max77759_fg-402e231a4b33

Best regards,
-- 
Thomas Antoine <t.antoine@uclouvain.be>

