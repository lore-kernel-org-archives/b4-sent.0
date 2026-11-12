From: =?utf-8?q?Eren_=C3=96zen?= <erenozen@protonmail.com>
Date: Thu, 12 Nov 2026 12:12:26 +0300
Subject: [PATCH] i2c: piix4: Don't register SPDs on the AUX bus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261112-piix4-aux-spd-v1-1-5b23f779122e@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/x3MQQrDIBAF0KsMf52BjpEKXiV0IWbSzsaKkiIE7
 x7oO8C70LWZdkS60PRn3b4FkWQh5E8qb2XbEQnu4Z4i4riaDc/pHNzrznkN6+G95KQBC6E2PWz
 8v+015w0W8zIhXwAAAA==
X-Change-ID: 20261112-piix4-aux-spd-c373f441cae7
To: Jean Delvare <jdelvare@suse.com>, Andi Shyti <andi.shyti@kernel.org>, 
 =?utf-8?q?Thomas_Wei=C3=9Fschuh?= <linux@weissschuh.net>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-i2c@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Eren_=C3=96zen?= <erenozen@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794474750; l=4067;
 i=erenozen@protonmail.com; s=20261110; h=from:subject:message-id;
 bh=6kfkLlIfH8+CbcTJypTTa9NTgrrHzjl5qgdqOi0irDk=;
 b=uFHh8UbZmtqEUf9AUtyTQ+YXfsHTGad2EelhJW4jiw0kSu23yGXhOJYfJe7ktIdBVQqhcP5CC
 kPfHzcdKpq4A+vVmJ7csqK6WGQXUVkjMDEnaGTEVVsATaKvcIKKSQUM
X-Developer-Key: i=erenozen@protonmail.com; a=ed25519;
 pk=tPAwfVmIbYF3QziJ3LcoTIZDU12BsjVK+EkAB9nN1gA=
X-Endpoint-Received: by B4 Relay for erenozen@protonmail.com/20261110 with auth_id=1479
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit de4f2f52f932 ("i2c: piix4: Register SPDs") only meant to probe
for SPD EEPROMs on port 0 of the main SMBus, because the AUX bus can
report every address as present and return 0 for every read. It checks
"port == 0" in piix4_add_adapter(), but the AUX adapter is also added
with port 0, so the SPDs are probed on the AUX bus as well.

On a Huawei MateBook 16 (AMD Ryzen 5000 "Cezanne", FCH SMBus
[1022:790b], two DDR4 devices that DMI lists as "Row Of Chips") this
creates two ee1004 devices on the AUX adapter, and every byte read from
them is 0x00:

  i2c i2c-10: Successfully instantiated SPD at 0x50
  i2c i2c-10: Successfully instantiated SPD at 0x51
  ee1004 10-0050: 512 byte EE1004-compliant SPD EEPROM, read-only
  ee1004 10-0051: 512 byte EE1004-compliant SPD EEPROM, read-only

The AUX bus on this machine behaves as described above: a byte read
from any of the unused SPD addresses 0x52-0x57 is also acknowledged and
returns 0x00. Userspace that reads SPD data through the ee1004 driver,
such as decode-dimms, then sees two all-zero EEPROMs that don't exist.

Don't register SPDs for the AUX adapter, as the comment above the check
already says.

The problem was found, and this change written, with an AI coding
assistant (Claude, claude-opus-5-5) that went through this laptop's
kernel logs. I reviewed the change and tested it on the laptop.

Fixes: de4f2f52f932 ("i2c: piix4: Register SPDs")
Signed-off-by: Eren Özen <erenozen@protonmail.com>
---
Tested on the Huawei MateBook 16 from the commit message (Fedora
7.2.15 kernel, i2c-piix4 rebuilt with this change and swapped in at
runtime):

  stock:   ee1004 at 10-0050 and 10-0051 on the AUX adapter,
           all 512 bytes of both read as 0x00
  patched: no SPD devices on the AUX adapter; SPD probing on
           port 0 of the main adapter is unchanged
  stock again: the two ee1004 devices come back

What I could not test:
- Only this one machine. I don't have a system with real SPD EEPROMs
  on the AUX bus. In the reports I found on lore, real SPDs on AMD
  boards are on port 0 of the main adapter, which is still probed.
- The patched module was built for the Fedora 7.2.15 kernel, not
  from a kernel booted from i2c/i2c-fixes. i2c-piix4.c is the same
  in both. The patch itself was compile-tested with W=1 on
  i2c/i2c-fixes.

How the AI assistant was used: I asked Claude Code (claude-opus-5-5)
to find kernel bugs that I could reproduce on this laptop. It went
through 140 boots of my kernel logs, found the bogus ee1004
devices, traced them to this check, checked lore for earlier reports,
and wrote the change, the changelog and the test scripts. I ran the
tests that needed root and reviewed the result.

A separate issue on this machine, not changed by this patch: the SPD
probe on main port 0 leaves HOST_BUSY set, so every boot logs "SMBus
Timeout!" followed by "Failed! (01)". With SPD probing disabled
completely (debug build only), port 0 shows no errors at all. DMI
describes the memory as "Row Of Chips", so there may be no SPD
EEPROM to find there. I'd be happy to look into that separately if
it is of interest.

The patch is based on i2c/i2c-fixes, and the file is the same in
i2c/i2c and in mainline.
---
 drivers/i2c/busses/i2c-piix4.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/i2c/busses/i2c-piix4.c b/drivers/i2c/busses/i2c-piix4.c
index 7b6a4e201b..1e89cd817d 100644
--- a/drivers/i2c/busses/i2c-piix4.c
+++ b/drivers/i2c/busses/i2c-piix4.c
@@ -970,7 +970,7 @@ static int piix4_add_adapter(struct pci_dev *dev, unsigned short smba,
 	 * devices present and all reads return "0".
 	 * This would allow the ee1004 to be probed incorrectly.
 	 */
-	if (port == 0)
+	if (port == 0 && padap != &piix4_aux_adapter)
 		i2c_register_spd_write_enable(adap);
 
 	*padap = adap;

---
base-commit: 25e7ab89f4774b0f842cee0e8a20c11f755924d5
change-id: 20261112-piix4-aux-spd-c373f441cae7

Best regards,
-- 
Eren Özen <erenozen@protonmail.com>

