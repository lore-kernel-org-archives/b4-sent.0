From: Pawel Laszczak <pawell@cadence.com>
Subject: [PATCH v9 0/2] usb: cdns3: support configurations without DRD
 block
Date: Thu, 21 May 2026 10:16:22 +0200
Message-Id: <20260521-no_drd_config_v9-v9-0-2512cef10104@cadence.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFa/DmoC/yXMSwqAIBRA0a3EGyfYF2wrEeLnVa+BhlYE0d6zG
 p7BvRdEDIQRuuyCgAdF8i5B5BmYWbkJGdlkKHnZ8qYQzHlpg5XGu5EmeQimRdFopeoKNYeUrQF
 HOr9lP/yOu17QbO8H7vsBGdalR3QAAAA=
X-Change-ID: 20260519-no_drd_config_v9-b915baa43eb0
To: Peter Chen <peter.chen@kernel.org>, Roger Quadros <rogerq@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Pawel Laszczak <pawell@cadence.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, kernel test robot <lkp@intel.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779351391; l=4730;
 i=pawell@cadence.com; h=from:subject:message-id;
 bh=30DopE8A0+MuAJawRPhY3T0K2+zbu52aiZ71gD+Krpc=;
 b=xppJ9QL6VhG7iLIKEfM5jdYn/SXDJLlCR+xnSokRv1ppemfH8hJTXv/HlHeVvpu6N4jcxq3E4
 xBu2K1/+hiDCOUMPgb7vMmNPgcOZeDVfICkB7OEKOvnf7492CnfROg1
X-Developer-Key: i=pawell@cadence.com; a=ed25519;
 pk=EUPBvLO9CDg7j6defeDl2iqi+z5Ivqu4Z46aiqe7dYc=
X-Endpoint-Received: by B4 Relay for pawell@cadence.com/default with auth_id=707
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for Cadence USBSSP controllers in hardware
layouts where the Dual-Role Device (DRD) register block is either
missing or inaccessible.

In such configurations, the controller is hardwired to a single role
(either host or device) and the driver must skip all OTG/DRD register
accesses to avoid bus errors or incorrect role detection.

The solution introduces a new 'cdns,cdnsp' compatible string
that can be passed via DT or software nodes.
When set, the driver:
1. Skips DRD register mapping and IRQ requests.
2. Uses a different BAR indexing logic for PCI-based configurations
   (32-bit addressing layout).
3. Hardwires the role based on 'dr_mode'.

Signed-off-by: Pawel Laszczak <pawell@cadence.com>
---
Note: This series is based on current linux-next. I am aware of Peter
Chen's recent refactoring series ("usb: cdns3: plat: Expose platform
core driver as library"). Although there is a minor conflict in
cdns3-plat.c, Peter has already provided an Acked-by for this version.
I am happy to provide a rebased v10 as soon as Peter's changes land in
linux-next if required.
---
v9:
- Dropped the "cdns,cdnsp-no-drd" string to avoid generic property-like 
  naming as requested by Conor.
- Introduced the clean generic fallback "cdns,cdnsp"
- Updated the patch description and commit message to reflect the new naming.

v8:
- Update commit message to reflect schema changes.
- Removed 'cdns,no-drd' boolean property as per Rob Herring's suggestion.
- Introduced a new compatible string 'cdns,cdnsp-no-drd' for controller
  variants that lack the DRD/OTG register block.
- Use 'cdns,cdnsp-no-drd' compatible string to trigger no-DRD logic.
- Update PCI glue layer to inject the new compatible string.

v7:
- Rename 'no_drd' to 'cdns,no-drd' (added vendor prefix).
- Update commit message to reflect property renaming and schema changes.
- Simplify 'reg-names' using a single enum for items.
- Revert 'interrupt-names' to a list of constants for strict ordering.
- Move 'reg' item descriptions to if/else blocks for better accuracy.
- Clean up 'if' logic (remove redundant 'true' check and 'dr_mode'
  requirement).
- Add explicit 'items' list for 'interrupt-names' in the 'else' block.
- Fix "uninitialized variable" warning in cdns_drd_host_on() by
  initializing 'ret' to 0.

v6:
- Fixed validation error for 'interrupt-names' by correcting
  the items definition.
- Adjusted 'minItems'/'maxItems' to properly support the optional
 'wakeup' interrupt.
- Fixed 'too long' schema error in examples.

v5:
- Implemented strict conditional validation using if-then-else logic.
- Enforced 2 register/interrupt items and required 'dr_mode'
  (host or peripheral) when 'no_drd' is present.
- Enforced the standard 3 register/interrupt items (otg, host, dev)
  when 'no_drd' is absent to ensure backward compatibility.
- Updated 'reg-names' and 'interrupt-names' to use enums in the main
  properties section to support flexible resource ordering during
  validation.

v4:
  - Added DT binding documentation for the 'no_drd' property.
  - Relaxed 'reg' and 'interrupts' requirements in the DT schema (minItems 2)
    to allow configurations where the OTG/DRD register block is missing.
  - Moved PCI_DEVICE_ID_CDNS_UDC_USBSSP from pci_ids.h to cdnsp-pci.c
    to keep the global PCI ID list clean.

v3:
  - Improved descriptions and comments for better clarity.
  - Introduced the 'no_drd' property to indicate missing DRD register block.
  - Added support for fixed host-only and device-only configurations.
  - Ensured cdns_otg_disable_irq is called only when no_drd is false.
  - Updated cdns_drd_gadget_on/off to ensure PHY mode is correctly
    handled even if DRD is disabled.

v2:
  - Changed otg_irq to be optional.
  - Added cdns->no_drd check in cdns_power_is_lost.
  - Added cdns->no_drd check in cdns_get_id.

---
Pawel Laszczak (2):
      dt-bindings: usb: cdns3: Add cdns,cdnsp compatible string
      usb: cdnsp: Add support for device-only configuration

 .../devicetree/bindings/usb/cdns,usb3.yaml         | 63 ++++++++++++++++++----
 drivers/usb/cdns3/cdns3-plat.c                     | 30 +++++++----
 drivers/usb/cdns3/cdnsp-pci.c                      | 48 +++++++++++++----
 drivers/usb/cdns3/core.c                           |  3 +-
 drivers/usb/cdns3/core.h                           |  4 ++
 drivers/usb/cdns3/drd.c                            | 45 ++++++++++++++--
 6 files changed, 159 insertions(+), 34 deletions(-)
---
base-commit: 80dd246accce631c328ea43294e53b2b2dd2aa32
change-id: 20260519-no_drd_config_v9-b915baa43eb0

Best regards,
--  
Pawel Laszczak <pawell@cadence.com>

