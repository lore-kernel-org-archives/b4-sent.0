From: Amit Sunil Dhamne <amitsd@google.com>
Subject: [PATCH v10 0/6] Introduce MAX77759 charger driver
Date: Tue, 31 Mar 2026 23:22:15 +0000
Message-Id: <20260331-max77759-charger-v10-0-76f59233c369@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAChXzGkC/3XSS27DIBAA0KtErOMKBmaArnqPKgt+diw1cWVXV
 qrIdy9OW9kVdMmgefOBO5vS2KeJPR/ubExzP/XDNR8EPx5YOLtrl5o+5gADDigEx+biblprtE2
 +Hrs0NgbBE1AkEo7ltPcxtf3tYb6e8vncTx/D+PkoMYs1+oOBLLFZNLwhD0l50+oW1Us3DN1be
 grDha3aDJsAwlQEyAJ4QGsNd2SoEOROAF0RZBZQJSLVYnAWCkH9CsRzExVBrVNYBVIFE1MUhYC
 bALy2B8yCRy4tSk0O20KgnSBURaB1DyZw66PTypeb1HuhtkmdhWSi5ToksgELwewEqPVgVsEb8
 hE1TzbshePhO1OK/zIBKOTRTdCxfAO71ZZQ+ZazzYJShmIEq138U/u0LMsXmnMe1fwCAAA=
X-Change-ID: 20251105-max77759-charger-852b626d661a
To: =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jagan Sridharan <badhri@google.com>, Mark Brown <broonie@kernel.org>, 
 Matti Vaittinen <mazziesaccount@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Sebastian Reichel <sre@kernel.org>, Amit Sunil Dhamne <amitsd@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-usb@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 RD Babiera <rdbabiera@google.com>, Kyle Tso <kyletso@google.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774999352; l=10670;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=xrHMl7PzQE+M0LSv6NXEKGHOeSB6YtsB/EXUXuyzHIU=;
 b=VQ4+ZDAPkr2wBthukXkfOAKgEk8Wz0q0nZkxms2VgtYIjdLqkBrjYo2bZg0AmZhR9UuHeUyi6
 G+DDj3x/SMIDz05MjMD5sGw9Io/N2GqLHifgz/TRxMaondK9uWLkPes
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MAX77759 PMIC is used in Pixel 6 and 6 Pro (Oriole/Raven) boards.
One of the functions of the MAX77759 PMIC is a battery charger. This
patchset introduces a driver for this function. One of the unique
features of this charger driver is that it works with a USB input where
the Type-C controller is TCPCI based.

Changes to the board files will follow soon once this patchset is reviewed.

For reference to the MAX77759 MFD based patchset (present in upstream):
https://lore.kernel.org/all/20250509-max77759-mfd-v10-0-962ac15ee3ef@linaro.org/

Dependency list for patches (directionality indicates depends on):
[6] -> [5] -> [4] & [3]

The changes need to be applied in order. In this case this probably
would be the USB subsystem as that's the leaf in the dependency list.

---
Kernel-doc output for include/linux/mfd/max77759.h (partial and only for
the changes introduced by me:

.. c:enum:: max77759_chgr_chgin_dtls_status

  Charger Input Status

.. container:: kernelindent

    **Constants**

    ``MAX77759_CHGR_CHGIN_DTLS_VBUS_UNDERVOLTAGE``
      Charger input voltage (Vchgin) < Under Voltage Threshold (Vuvlo)

    ``MAX77759_CHGR_CHGIN_DTLS_VBUS_MARGINAL_VOLTAGE``
      Vchgin > Vuvlo and Vchgin < (Battery Voltage (Vbatt) + system voltage (Vsys))

    ``MAX77759_CHGR_CHGIN_DTLS_VBUS_OVERVOLTAGE``
      Vchgin > Over Voltage threshold (Vovlo)

    ``MAX77759_CHGR_CHGIN_DTLS_VBUS_VALID``
      Vchgin > Vuvlo, Vchgin < Vovlo and Vchgin > (Vsys + Vbatt)

.. c:enum:: max77759_chgr_bat_dtls_states

  Battery Details

.. container:: kernelindent

    **Constants**

    ``MAX77759_CHGR_BAT_DTLS_NO_BATT_CHG_SUSP``
      No battery and the charger suspended

    ``MAX77759_CHGR_BAT_DTLS_DEAD_BATTERY``
      Vbatt < Vtrickle

    ``MAX77759_CHGR_BAT_DTLS_BAT_CHG_TIMER_FAULT``
      Charging suspended due to timer fault

    ``MAX77759_CHGR_BAT_DTLS_BAT_OKAY``
      Battery okay and Vbatt > Min Sys Voltage (Vsysmin)

    ``MAX77759_CHGR_BAT_DTLS_BAT_UNDERVOLTAGE``
      Battery is okay. Vtrickle < Vbatt < Vsysmin

    ``MAX77759_CHGR_BAT_DTLS_BAT_OVERVOLTAGE``
      Battery voltage > Overvoltage threshold

    ``MAX77759_CHGR_BAT_DTLS_BAT_OVERCURRENT``
      Battery current exceeds overcurrent threshold

    ``MAX77759_CHGR_BAT_DTLS_BAT_ONLY_MODE``
      Battery only mode and battery level not available

.. c:enum:: max77759_chgr_chg_dtls_states

  Charger Details

.. container:: kernelindent

    **Constants**

    ``MAX77759_CHGR_CHG_DTLS_PREQUAL``
      Charger in prequalification mode

    ``MAX77759_CHGR_CHG_DTLS_CC``
      Charger in fast charge const curr mode

    ``MAX77759_CHGR_CHG_DTLS_CV``
      Charger in fast charge const voltage mode

    ``MAX77759_CHGR_CHG_DTLS_TO``
      Charger is in top off mode

    ``MAX77759_CHGR_CHG_DTLS_DONE``
      Charger is done

    ``MAX77759_CHGR_CHG_DTLS_RSVD_1``
      Reserved

    ``MAX77759_CHGR_CHG_DTLS_TIMER_FAULT``
      Charger is in timer fault mode

    ``MAX77759_CHGR_CHG_DTLS_SUSP_BATT_THM``
      Charger is suspended as battery removal detected

    ``MAX77759_CHGR_CHG_DTLS_OFF``
      Charger is off. Input invalid or charger disabled

    ``MAX77759_CHGR_CHG_DTLS_RSVD_2``
      Reserved

    ``MAX77759_CHGR_CHG_DTLS_RSVD_3``
      Reserved

    ``MAX77759_CHGR_CHG_DTLS_OFF_WDOG_TIMER``
      Charger is off as watchdog timer expired

    ``MAX77759_CHGR_CHG_DTLS_SUSP_JEITA``
      Charger is in JEITA control mode
---

To: Sebastian Reichel <sre@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: André Draszik <andre.draszik@linaro.org>
To: Lee Jones <lee@kernel.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
To: Badhri Jagan Sridharan <badhri@google.com>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>
To: Peter Griffin <peter.griffin@linaro.org>
To: Tudor Ambarus <tudor.ambarus@linaro.org>
To: Alim Akhtar <alim.akhtar@samsung.com>
To: Mark Brown <broonie@kernel.org>
To: Matti Vaittinen <mazziesaccount@gmail.com>
To: Andrew Morton <akpm@linux-foundation.org>
Cc: linux-kernel@vger.kernel.org
Cc: linux-pm@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-usb@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-samsung-soc@vger.kernel.org
Cc: RD Babiera <rdbabiera@google.com>
Cc: Kyle Tso <kyletso@google.com>
Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
Changes in v10:
- Fixed comment style (/* -> /**) to make it a kernel-doc comment. (Lee
  Jones)
- Link to v9: https://lore.kernel.org/r/20260325-max77759-charger-v9-0-4486dd297adc@google.com

Changes in v9:
- Fixed nits in mfd/max77759.* (Lee Jones)
  - s/max77759_chrg_irq_chip/max77759_chgr_irq_chip
  - s/bettery/battery
  - Fix alignment in descriptions in kerneldoc comments
- Link to v8 resend: https://lore.kernel.org/r/20260314-max77759-charger-v8-0-226ca5f8c7d2@google.com
- Link to v8: https://lore.kernel.org/all/20260224-max77759-charger-v8-0-eb86bd570e9c@google.com/

Changes in v8:
- Add an newline char at the end of dev_* prints. (André Draszik)
- Return PTR_ERR() instead of -EPROBE_DEFER when devm_power_supply_register()
  fails in max77759 charger probe. (André Draszik)
- Link to v7: https://lore.kernel.org/r/20260218-max77759-charger-v7-0-e8d907ce69c5@google.com

Changes in v7:
- Add register relock for protected registers in fail path. (André Draszik)
- Switch to usage of scoped_guard instead of guard. (LKP test bot)
- Link to v6: https://lore.kernel.org/r/20260214-max77759-charger-v6-0-28c09bda74b4@google.com

Changes in v6:
-  Linear Range usage (André Draszik):
  - Dedicate individual arrays for inlim, chgcc & chg_cv_prm to simplify
    code.
  - Use numerical values instead of macros for linear_range array init.
  - Remove macros defining current and voltage limits due to above.
  - Didn't use Reviewed-by tag for Patch 3 due to the above.
  - Add new linear_ranges api to leverage it for obtaining selector
    values.
  - Improve voltage and current getters and setters functions by leveraging
    existing and new linear_ranges API.
- IRQ related changes (André Draszik)
  - Dedicated names for individual irqs.
  - Refactor irq handlers.
  - Ratelimit prints
- Retry mechanism (André Draszik):
  - Initialize error retry counter to 0 when psy work is scheduled on a
    new notifier event.
  - Protect the counter using a lock.
  - Add appropriate prints.
- Link to v5: https://lore.kernel.org/r/20260203-max77759-charger-v5-0-b50395376a5f@google.com

Changes in v5:
- Use linear_range library instead of reinventing it. (André Draszik)
  - This requires a selector_max value so modified mfd/max77759.h to
    include it for CHGCC and CHG_ILIM.
  - Removed "reviewed-by" for Patch 3 (mfd) due to above
- Use asnyc probe type. (André Draszik)
- Retry mechanism for psy_work. (André Draszik)
- Minor nits (André Draszik):
  - Use named initializers for instantiating structs.
  - Use static qualifier for `psy_name` variable.
  - Refactor if-else ladder to remove else handling if return in prior
    "if" loop.
  - Remove redundant `unlikely`.
- Link to v4: https://lore.kernel.org/r/20260121-max77759-charger-v4-0-694234c8ded1@google.com

Changes in v4:
- Removed a stray tabspace in mfd/max77759.h. (André Draszik)
- Fixed the following issues in Patch 4/5 (André Draszik):
  - Re-order Kconfig entry
  - Refactored to not use global variable
  - Use of clamp() to clamp values instead of duplicating logic
  - Return IRQ_NONE for unhandled irqs or error conditions
  - Remove debug messages in irq handler
  - Refactor code to use dev_err_probe in *_init_irqhandler()
  - Remove unneeded irq_flags
  - Check return values of regmap ops
  - Other nits like newlines, not using greedy init, using print stmnts
- Link to v3: https://lore.kernel.org/r/20251227-max77759-charger-v3-0-54e664f5ca92@google.com

Changes in v3:
- Had incorrectly folded the charger sub-device with the pmic parent.
  Corrected it. (Krzysztof Kozlowski)
- Link to v2: https://lore.kernel.org/r/20251218-max77759-charger-v2-0-2b259980a686@google.com

Changes in v2:
- Fold charger binding in maxim,max77759-charger.yaml to its parent
  node. (Krzysztof Kozlowski)
- Renamed regulator supplier & consumer. (Krzysztof Kozlowski & Heikki
  Krogerus)
- Removed explicit setting of irq trigger types in max77759 driver.
  (André Draszik & Krzysztof Kozlowski)
- Complete bit definitions for IRQ registers. (André Draszik)
- Consolidate all bit definitions for charger IP in mfd/max77759.h.
  (André Draszik)
- Modify the handling of charger IRQs such that regmap IRQ chip handles
  masking, de-mux and acking of interrupts. (André Draszik)
- Remove unused macro definitions relating to Charger modes in tcpci
  maxim driver (André Draszik)
- Add dependency on Regulator class in Kconfig definition for max77759
  chg. (Kernel Test Robot)
- Link to v1: https://lore.kernel.org/r/20251123-max77759-charger-v1-0-6b2e4b8f7f54@google.com

---
Amit Sunil Dhamne (6):
      dt-bindings: mfd: maxim,max77759: reference power-supply schema and add regulator property
      dt-bindings: usb: maxim,max33359: Add supply property for vbus
      mfd: max77759: add register bitmasks and modify irq configs for charger
      lib/linear_ranges: Add linear_range_get_selector_high_array
      power: supply: max77759: add charger driver
      usb: typec: tcpm/tcpci_maxim: deprecate WAR for setting charger mode

 .../devicetree/bindings/mfd/maxim,max77759.yaml    |  16 +-
 .../devicetree/bindings/usb/maxim,max33359.yaml    |   4 +
 MAINTAINERS                                        |   6 +
 drivers/mfd/max77759.c                             |  95 ++-
 drivers/power/supply/Kconfig                       |  11 +
 drivers/power/supply/Makefile                      |   1 +
 drivers/power/supply/max77759_charger.c            | 774 +++++++++++++++++++++
 drivers/usb/typec/tcpm/tcpci_maxim.h               |   1 +
 drivers/usb/typec/tcpm/tcpci_maxim_core.c          |  54 +-
 include/linux/linear_range.h                       |   3 +
 include/linux/mfd/max77759.h                       | 166 ++++-
 lib/linear_ranges.c                                |  36 +
 12 files changed, 1106 insertions(+), 61 deletions(-)
---
base-commit: ecc64d2dc9ff9738d2a896beb68e02c2feaf9a02
change-id: 20251105-max77759-charger-852b626d661a

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

