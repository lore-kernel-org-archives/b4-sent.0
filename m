From: Ciro Pedrini <ciro.pedrini@gmail.com>
Subject: [PATCH RFC 0/2] Keyboard lighting for the Lenovo Legion Pro 7 Gen
 10
Date: Mon, 09 Nov 2026 22:50:20 +0000
Message-Id: <20261109-legion-lighting-rfc-v1-0-a87e1db8c5e3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQrCMBBFr1Jm7UATaUG3ggdwKy7SZJIMlKlMi
 hRK7+7o8n3+ezs0UqYG124HpQ83XsTAnTqINUgh5GQMvvejc/0FZyp2wZlLXVkKao6Y4tm7cUh
 58AnMfCtl3v7VJzzuN3jZOIVGOGmQWH/BvCgKbSscxxfMPDwlhQAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794264688; l=4129;
 i=ciro.pedrini@gmail.com; h=from:subject:message-id;
 bh=NVJmw8/xUXqWPd+UKqSe+SQ9Beve4dYcB85vbCBj+pk=;
 b=XJ/ql3sKNq4B/mbUrZoZbODwcOHmfXH4WZOHZhVvUNZQbZ1YAvAvmcHcP9302GE+oOZrB/y4m
 g8bVpugl+cNDnNCNP7IQYhLF2x3mqF1nPOtj9nukFshTTlUec19Mrve
X-Developer-Key: i=ciro.pedrini@gmail.com; a=ed25519;
 pk=TOSFlPBon1xBHfTrhODxatabgwEJdgKEzG3jMoMQcbc=
X-Endpoint-Received: by B4 Relay for ciro.pedrini@gmail.com/default with auth_id=1468
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The keyboard and chassis lighting of the Lenovo Legion Pro 7 16IAX10H
(2025) has no Linux support today: on my unit nothing ever lit, because
the keyboard controller's brightness was 0 from the factory and nothing on
Linux exposes it. This series makes it a regular keyboard backlight.

The lighting is two USB HID devices:

- 048d:c197, the ITE 8258 keyboard controller: the built-in keyboard,
  plus a vendor protocol on feature report 0x07 (960 bytes) with a
  hardware brightness (0..9, stored), the controller's own effects
  (stored profiles), and a switch that hands the LEDs to the LampArray
  below (also stored). Fn+Up/Down/Space are handled by the controller,
  which reports the result on a vendor input report.

- 048d:c193 interface 1, a standard HID LampArray: 319 lamps (keys, front
  strip, rear vents, lid logo) with positions and key usages. It shows
  nothing until the controller hands the LEDs over, its colours are scaled
  by the controller's brightness, and after resume from S3 the kernel
  resets it and it comes back in autonomous mode.

Patch 1 makes ideapad-laptop ignore the EC's copies of those three
hotkeys, which reach userspace as KEY_UNKNOWN today.

Patch 2 adds hid-lenovo-legion, binding both devices: one multicolor LED
(<name>:rgb:kbd_backlight) whose brightness is the controller's, with
brightness_hw_changed from the hotkeys, and whose colour goes to every
lamp. lighting_mode selects "firmware" (default: the controller's effects;
the driver leaves the LEDs alone, so a userspace tool can drive the
LampArray over hidraw) or "color". Per-key control stays in userspace.

This is an RFC because of its shape: one driver spanning two USB devices,
paired by their USB bus. Is that acceptable, or would you rather have it
differently, e.g. a vendor hook in the generic LampArray helper that Aaron
and Werner are working on ("HID: generic: add LampArray support", v7),
which on this machine would register a kbd_backlight that does nothing
visible? The two patches touch two subsystems; I'm happy to split them.

Tested on the 16IAX10H (83F5, BIOS Q7CN77WW, Spanish ISO keyboard) with
7.2, as modules: brightness from sysfs and KDE, the hotkeys' OSD, colours
on every zone, suspend/resume in both modes, a userspace LampArray client
in "firmware" mode, unbinding back to hid-generic. The series is based on
v7.4-rc2 and builds there with W=1.

I worked out the protocol from the device itself (usbmon captures, the
LampArray's attributes) and from analysing the vendor's Windows software
for interoperability. The patches were prepared with Claude Code (Claude
Opus 5.5), see the Assisted-by tags; I reviewed and tested them.
checkpatch reports those tags (non-standard signature, no email address),
and a MAINTAINERS hint for the new files that patch 2 already adds.

To: Mark Pearson <mpearson-lenovo@squebb.ca>
To: Derek J. Clark <derekjohn.clark@gmail.com>
To: Rong Zhang <i@rong.moe>
To: Ike Panhc <ikepanhc@gmail.com>
To: Hans de Goede <hansg@kernel.org>
To: Ilpo Järvinen <ilpo.jarvinen@linux.intel.com>
To: Jiri Kosina <jikos@kernel.org>
To: Benjamin Tissoires <bentiss@kernel.org>
Cc: platform-driver-x86@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-input@vger.kernel.org

---
Ciro Pedrini (2):
      platform/x86: ideapad-laptop: Ignore keyboard backlight hotkeys
      HID: lenovo-legion: Add keyboard lighting driver for Legion Gen 10

 .../testing/sysfs-class-led-driver-lenovo-legion   |  20 +
 MAINTAINERS                                        |   2 +
 drivers/hid/Kconfig                                |  13 +
 drivers/hid/Makefile                               |   1 +
 drivers/hid/hid-ids.h                              |   2 +
 drivers/hid/hid-lenovo-legion.c                    | 662 +++++++++++++++++++++
 drivers/platform/x86/lenovo/ideapad-laptop.c       |   4 +
 7 files changed, 704 insertions(+)
---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261109-legion-lighting-rfc-dc32165df52d

Best regards,
-- 
Ciro Pedrini <ciro.pedrini@gmail.com>

