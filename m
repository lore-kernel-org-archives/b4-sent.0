From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Subject: [PATCH 0/3] power: supply: smb347: Set the USB input current limit
 from APSD
Date: Sat, 21 Nov 2026 10:30:19 +0100
Message-Id: <20261121-upstream-smb347-apsd-v1-0-ca46b92bfd44@tsv-stahl-riesa.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw6CMBBG4Vchs3aSthC8vIpx0dK/OiZg0wFDQ
 nh3qy6/xTkbKYpA6dJsVPAWlddUYQ8NDQ8/3cESq8kZ11vrDC9Z5wI/so6h7Y7ss0Y+n0KHiBR
 Mn6imuSDJ+tteb3/rEp4Y5u+L9v0D5pBk/ngAAAA=
X-Change-ID: 20261120-upstream-smb347-apsd-98b4edefb06f
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Heidelberg <david@ixit.cz>, 
 Dmitry Osipenko <digetx@gmail.com>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Bruce Robertson <brucer42@gmail.com>, 
 =?utf-8?q?Martin_J=C3=BCcker?= <martin.juecker@gmail.com>, 
 Mithil Bavishi <bavishimithil@gmail.com>, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795253429; l=4716;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=zJJFsIHeF0nNs/Qr8JrDVzgaMQ38hgsj9MNYB8mXUXs=;
 b=x3mGOu2jLHpQOXQE7f1Sb90bPcB6cAQwU76+6BZiAA5DNRn7U6d/ggy57jCC2syOEA8Ge+T8D
 T2lQL9CvwxfAQSl3mIWKLx80el+iy95iBWRDJRNiawl5qW+W1jLX77f
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SMB347 driver programs the USB input current limit once at probe
from "summit,usb-current-limit-microamp". Boards either leave it at the
chip's NVM default, which is 900 mA on the Nexus 7 (2012), or set it to
1800 mA (exynos4412-p4note, omap4-samsung-espresso10). The first makes
the original 2 A charger no faster than a PC port, the second loads PC
ports with 1.8 A.

The charger detects the port type itself (APSD). This series reads the
result after the input became valid, sets the limit for the port type
(SDP 500 mA, CDP 1.5 A, DCP the DT value or 1.5 A) and reports it as
POWER_SUPPLY_PROP_USB_TYPE. Patch 1 updates the binding text, patch 2
makes the registers readable, patch 3 does the detection.

Measured on a Nexus 7 (2012, E1565), median current into the battery
(bq27541) over 5-30 minutes, battery charge in brackets:

                       before (NVM 900 mA)  this series
  laptop port (CDP)    505 mA (84-89 %)     640 mA (85-90 %)    1.5 A
  2 A charger (DCP)    561 mA (84-86 %)     968 mA (74-78 %)    1.5 A
                                            972 mA (79-82 %)    1.8 A *
  same, display off    596 mA (31-33 %)    1161 mA (37-39 %)    1.5 A
                                           1147 mA (45-47 %)    1.8 A *

  * with summit,usb-current-limit-microamp = <1800000> added to the
    grouper DT for the test; it gives no gain over 1.5 A, so this
    series does not touch the grouper DT.

The display was on unless noted.

The laptop port turned out to be a CDP. A PC port detected as SDP was
not available for testing. With 1800 mA in the device tree and without
this series, AICL ended once at the lowest step directly after boot at
the laptop port (the battery got 120 mA); with the series it did not
happen in seven boots and several reconnections. Directly after probe the
charger NAKs the write to CFG_VARIOUS_FUNCTION; patch 3 therefore does
the first detection 500 ms after probe, as after a new connection.
A quick move from the laptop port to the charger once left the driver
with the CDP limit (two interrupts, input state unchanged in the
driver), so patch 3 detects the port type after every USB input
interrupt; quick moves in both directions work with that.

There is no public datasheet with the register map that I could find.
The STAT_D, AICL and APSD bits are taken from the Android 3.1 kernel for
the Nexus 7 [1], which uses them the same way (900 mA for SDP, 1800 mA
for the other types). That is why only the SMB347 uses APSD, and
SMB345/SMB358 stay as they are.

Questions:

- Is 500 mA for an SDP acceptable? It is the USB 2.0 value, but less
  than the NVM default of 900 mA on the Nexus 7 and than the 1800 mA
  p4note and espresso10 use today at a PC port.
- APSD result "other" (non-BC 1.2 chargers) gets 500 mA here; the
  Android driver uses the charger limit. Is someone able to check the
  meaning of the remaining STAT_D values on SMB345/SMB358?

Bruce Robertson posted an RFC for a Rust SMB347 driver [2], which does
not handle interrupts or USB OTG yet. This series is for the existing C
driver; I am happy to test the Rust driver on the Nexus 7 as well.

Tested with v7.4-rc3 on a Nexus 7 (2012, E1565) at a laptop port (CDP)
and the original 2 A charger (DCP), including unplugging, replugging and
quick moves between them.
An SDP, chargers reported as "other" and USB host mode (OTG) were not
tested. The series is build tested on top of power-supply for-next.

Tool use (see Documentation/process/generated-content.rst): the patches,
their changelogs and this cover letter were prepared with an LLM coding
assistant (Claude Code). It compared the Android and mainline drivers,
wrote the code and drafted the texts from my measurements and
instructions. I reviewed the changes and ran all tests on the device.

[1] drivers/power/smb347-charger.c, branch
    android-tegra3-grouper-3.1-lollipop-release of
    https://android.googlesource.com/kernel/tegra
[2] https://lore.kernel.org/all/20260708214738.25008-1-brucer42@gmail.com/

---
Patrick Fischer (3):
      dt-bindings: power: supply: summit,smb347: Clarify the USB current limit
      power: supply: smb347: Make the APSD and AICL registers readable
      power: supply: smb347: Set the USB input current limit from APSD

 .../power/supply/summit,smb347-charger.yaml        |   5 +-
 drivers/power/supply/smb347-charger.c              | 258 ++++++++++++++++++++-
 2 files changed, 260 insertions(+), 3 deletions(-)
---
base-commit: abbe0a96bdbadae9e29489a1528fa436c55aca25
change-id: 20261120-upstream-smb347-apsd-98b4edefb06f

Best regards,
--  
Patrick Fischer <admin@tsv-stahl-riesa.de>

