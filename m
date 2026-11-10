From: Ciro Pedrini <ciro.pedrini@gmail.com>
Subject: [PATCH v2 0/2] Keyboard backlight for the Lenovo Legion Pro 7 Gen
 10
Date: Tue, 10 Nov 2026 20:29:46 +0000
Message-Id: <20261110-legion-lighting-rfc-v2-0-845726afb71c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQqDMBBFr1Jm3SkmorVd9R7FRUwmyYAmJRGxi
 Hdv9ABdPvjvvw0yJaYMz8sGiRbOHEMBeb2A9io4QjaFQVayFaJ64EiuTHBk52cODpPVaHQtRds
 Y20gDxfwksryer+++8KAy4ZBU0P74sjFhoHU+pp7zHNP37C/iEP6nFoEVqu5Owgydbqh+uUnxe
 NNxgn7f9x+LpVSi0QAAAA==
X-Change-ID: 20261109-legion-lighting-rfc-dc32165df52d
To: Mark Pearson <mpearson-lenovo@squebb.ca>, 
 "Derek J. Clark" <derekjohn.clark@gmail.com>, Rong Zhang <i@rong.moe>, 
 Ike Panhc <ikepanhc@gmail.com>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: Werner Sembach <wse@tuxedocomputers.com>, 
 Aaron Erhardt <aer@tuxedocomputers.com>, 
 platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-input@vger.kernel.org, Ciro Pedrini <ciro.pedrini@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794342675; l=3251;
 i=ciro.pedrini@gmail.com; h=from:subject:message-id;
 bh=TWaA0/dEi6NcvvOs40KXYLN4ENJQ/0lyBsZMKYnlTJc=;
 b=1TcG+RN50h5+HvR6XV9fKXHJkmEs7n5isWh/z/1JzFyWu221WZpzwKh8dzpjSJeCHp69KQbO3
 2gOC/6hHMofBN9LVYtu1dDn17VgJ+EuIi27cDkI4Z1Ba53VtU2kICDn
X-Developer-Key: i=ciro.pedrini@gmail.com; a=ed25519;
 pk=TOSFlPBon1xBHfTrhODxatabgwEJdgKEzG3jMoMQcbc=
X-Endpoint-Received: by B4 Relay for ciro.pedrini@gmail.com/default with auth_id=1468
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This is v2 of the Legion keyboard lighting series. After Rong's comments
it's a lot smaller: it only handles the keyboard controller (048d:c197)
now, and exposes its brightness as a normal kbd_backlight LED. The
LampArray (048d:c193) is left for a generic LampArray driver.

Some background in case you missed v1: on my laptop the keyboard
backlight never turned on under Linux. The controller's brightness was 0
from the factory and nothing on Linux could change it. The controller
has a vendor feature report (0x07) with a stored brightness from 0 to 9,
and that brightness dims every LED of the machine. Fn+Up/Down/Space are
handled by the firmware, which also sends the new brightness on a vendor
input report.

Patch 1 stops ideapad-laptop from sending KEY_UNKNOWN for those three
keys. Patch 2 is the driver: the brightness as kbd_backlight, plus
brightness_hw_changed for the hotkeys so the desktop OSD works.

Derek, Mark: I put the driver under your "LENOVO HID drivers" entry, and
I already did that in v1 without asking you, sorry. Is that OK with you?
If not, I'll add a separate entry.

I tested it on my 16IAX10H (83F5, BIOS Q7CN77WW) with 7.2: brightness
from sysfs and KDE, the hotkeys and the OSD, suspend/resume, unbind and
rebind. It's based on pdx86 for-next and builds with W=1.

About how this was made: I found the protocol with usbmon captures and
by looking at Lenovo's Windows software. I wrote the code with help from
Claude Code (Claude Opus 5.5). I went through all of it and tested it
myself, and each patch has a short note about it below the ---.

Ilpo, Rong: thanks a lot for taking the time to review v1 so carefully.
Looking back, it was rougher than it should have been. If you see
anything else that needs fixing, I'm happy to keep working on it.

Thanks,
Ciro

---
Changes in v2:
- Only the keyboard controller (c197) now, as Rong suggested. No
  LampArray, no colours, no lighting_mode, just a kbd_backlight LED.
- Ilpo's comments: struct with __le16 for the request, guard(),
  devm_mutex_init(), no magic numbers, includes.
- Removed the "ready" flag, its spinlock and the work item. raw_event
  can't run during probe/remove, so it notifies the LED directly.
- Keep led_cdev.brightness in sync with the hotkeys (from the Sashiko
  review).
- Moved the note about the AI tool out of the changelogs, below the ---.
- Link to v1: https://lore.kernel.org/r/20261109-legion-lighting-rfc-v1-0-a87e1db8c5e3@gmail.com

---
Ciro Pedrini (2):
      platform/x86: ideapad-laptop: Ignore keyboard backlight hotkeys
      HID: lenovo-legion: Add keyboard backlight driver for Legion Gen 10

 MAINTAINERS                                  |   1 +
 drivers/hid/Kconfig                          |  13 ++
 drivers/hid/Makefile                         |   1 +
 drivers/hid/hid-ids.h                        |   1 +
 drivers/hid/hid-lenovo-legion.c              | 261 +++++++++++++++++++++++++++
 drivers/platform/x86/lenovo/ideapad-laptop.c |   4 +
 6 files changed, 281 insertions(+)
---
base-commit: a514d723595bd8e5ce926a7fea148ceb3c26915c
change-id: 20261109-legion-lighting-rfc-dc32165df52d

Best regards,
-- 
Ciro Pedrini <ciro.pedrini@gmail.com>

