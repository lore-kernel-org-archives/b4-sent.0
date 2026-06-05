From: Herman van Hazendonk <github.com@herrie.org>
Subject: [PATCH v2 0/2] power: supply: max8903: add DC and USB input
 current-limit GPIO controls
Date: Fri, 05 Jun 2026 11:18:11 +0200
Message-Id: <20260605-submit-power-max8903-dc-limit-v2-0-0c5396e98f14@herrie.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFOUImoC/x3MTQqEMAxA4atI1hOIFYt6FZlFrFED/tHOqCDe3
 erye4t3QhCvEqBKTvCyadBljjCfBNzAcy+obTQYMpYs5Rj+zaQ/XJddPE58FCVl2Doc9cnMVvK
 UraMyg/hYvXR6vP/6e103LdD5yW8AAAA=
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780651091; l=3526;
 i=github.com@herrie.org; s=20240417; h=from:subject:message-id;
 bh=PgFIrdPiYEuUXNFSOa6IHQ/Mq4Zwsl31OM6oXB7RwCg=;
 b=rKqMdlkUUCxwNQ6qfLr4sWLiKNWPvhisvJwNYX0JzzoZj4dDFnnCOM1dw7VgnurgXrknXc1UB
 KUVUAUbwZRPBuOhQByJZ7B/MQKVhtGcc1UgsBp9a5u4PXWhafb2zvuh
X-Developer-Key: i=github.com@herrie.org; a=ed25519;
 pk=YYxdq8fb5O9vhkW3n2dCH044FPZZO5718v/du7fRhFw=
X-Endpoint-Received: by B4 Relay for github.com@herrie.org/20240417 with auth_id=809
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

v2 addresses two rounds of reviewer feedback on v1.

Sebastian Reichel (1 finding):
 - Drop usb-current-limit-values DT property. The IUSB pin is
   silicon-fixed at 100/500 mA per the MAX8903 datasheet Pin
   Description ("Drive IUSB logic-low to set the USB current limit
   to 100mA. Drive IUSB logic-high to set the USB current limit to
   500mA."), so there's nothing board-specific to expose. The two
   values are bound to MAX8903_USB_CURRENT_LIMIT_{LOW,HIGH}_UA
   #defines in the driver with the datasheet quote in a header
   comment; usb-current-limit-gpios stays as the board parameter.

Kernel test robot / dt-schema reviewer (8 findings):
 - Binding: add dependentRequired so dc-current-limit-gpios and
   dc-current-limit-mapping are required together; incomplete DTs
   cannot pass dtschema with only one half of the pair.
 - Binding: rename example node "charger-with-current-limit" to the
   generic "charger" per the Devicetree Specification.
 - Driver get_property: when DC is online the hardware draws from
   DC regardless of USB state. Never fall through to reporting the
   USB cap; refuse with -ENODATA when DC GPIOs aren't configured
   rather than mis-describe the active source. The set path mirrors
   this policy.
 - Driver set_dc_current_limit: drop bitmap_from_arr32(values,
   &u32_var, 32). On 64-bit, the macro reinterprets its u32* source
   as unsigned long* and reads past the on-stack scalar; replace
   with bitmap_zero() + values[0] = gpio_value (the lowest ndescs
   bits, parse-time bounded to < 32).
 - Driver set_property: reject val->intval < 0 explicitly. The
   helpers take a u32 and a negative widen would bypass the upper
   bounds check, silently programming the maximum permitted current.
 - Driver IRQs: extend source_lock over the full
   read-modify-evaluate block in max8903_dcin() and max8903_usbin().
   With the old scope, simultaneous DC and USB plug events could
   race in the cen enable calculation and write the wrong bit.
 - Driver parse_dc_current_limit: switch the scratch map[] buffer
   from devm_kcalloc to kmalloc_array + explicit kfree on every
   return path; the buffer is only used during parse.
 - Driver parse_dc_current_limit: reject ndescs >= 32 at parse time
   to keep BIT(ndescs) well-defined on 32-bit. Defensive against a
   DT that somehow slipped past dtschema's maxItems=4 cap.

Tested on a HP TouchPad (APQ8060, MSM8x60 family) post-rework: all
4 interconnect fabrics still probe; max8903_charger enumerates and
binds; INPUT_CURRENT_LIMIT writes program the expected GPIO bit
patterns on both the DC resistor mux (verified against on-board
MAX8903B IDC wiring) and IUSB; USB link still up; no WARN/BUG/Oops.

The DTS hookup that wires these GPIOs to the MAX8903 on the HP
TouchPad will be sent separately to the ARM/DTS tree.

Signed-off-by: Herman van Hazendonk <github.com@herrie.org>
---
Herman van Hazendonk (2):
      dt-bindings: power: supply: maxim,max8903: add DC and USB input current-limit controls
      power: supply: max8903: add DC and USB input current-limit GPIO controls

 .../bindings/power/supply/maxim,max8903.yaml       |  53 +++
 drivers/power/supply/max8903_charger.c             | 415 ++++++++++++++++++++-
 2 files changed, 451 insertions(+), 17 deletions(-)
---
base-commit: 944125b4c454b58d2fe6e35f1087a932b2050dff
change-id: 20260605-submit-power-max8903-dc-limit-aa6e51a6c093

Best regards,
-- 
Herman van Hazendonk <github.com@herrie.org>

