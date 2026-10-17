From: Dennis Nilsson <kontakt@dennisnilsson.se>
Subject: [PATCH 0/2] platform/x86: acer-wmi: Add Nitro AN16-41 support and
 handle its mode key
Date: Sat, 17 Oct 2026 10:33:57 +0200
Message-Id: <20261017-acer-nitro-an16-41-v1-0-c2e7a0ee7303@dennisnilsson.se>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQ6CMAyA4VchPdukHROir2I4jFm0HgbpgJAQ3
 t2hx+/w/ztkMZUM92oHk1WzjqmALxXEd0gvQX0WgyPXMHGLIYph0tlGDIkb9IzX2lHrb0SD76G
 Ek8mg22/66P7OS/+ROJ8nOI4vCzkwIHYAAAA=
X-Change-ID: 20261017-acer-nitro-an16-41-532074900f4b
To: "Lee, Chun-Yi" <jlee@suse.com>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dennis Nilsson <kontakt@dennisnilsson.se>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792226037; l=1115;
 i=kontakt@dennisnilsson.se; s=20261017; h=from:subject:message-id;
 bh=5rWtNt1vL+mrQkDtba5N98fbbX9UeGo0VrHEVuJypWM=;
 b=QXK3HUbXbx2leig3lU1IWwnNVqw0QJINfGUEnvlRXoNcNcBXFBM4Fd+a0c+XqWUGkCtcPAzV1
 BgiAj1terE0CYnoFaN2rwvTBCr3d9F4C7uvuwMKnKsRcxxpjuG0fZtc
X-Developer-Key: i=kontakt@dennisnilsson.se; a=ed25519;
 pk=H+jadpTa8sEscQhkbeWZC2woL8j7NYwN5m1YCjkHJRQ=
X-Endpoint-Received: by B4 Relay for kontakt@dennisnilsson.se/20261017 with auth_id=1223
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Acer Nitro AN16-41 supports the Predator Sense v4 platform profile,
hwmon sensors and fan control, but needs predator_v4=1 to expose them,
and its mode key does nothing because it reports key_num 0x4, which the
driver only treats as a turbo button.

Patch 1 routes key_num 0x4 to the platform profile cycle on machines
without the turbo LED capability, where it was previously a no-op.
Patch 2 adds a DMI quirk for the AN16-41.

Both patches were tested together on an AN16-41 (BIOS V1.03) running
7.0: the quirk matches without module parameters, all five profiles
cycle from the mode key, and pwm works in custom, maximum and automatic
mode.

---
Dennis Nilsson (2):
      platform/x86: acer-wmi: Cycle platform profile on mode key 0x4
      platform/x86: acer-wmi: Add support for Acer Nitro AN16-41

 drivers/platform/x86/acer-wmi.c | 18 ++++++++++++++++--
 1 file changed, 16 insertions(+), 2 deletions(-)
---
base-commit: ea40f1e9f07aab937b9a217633be7a1f66260394
change-id: 20261017-acer-nitro-an16-41-532074900f4b

Best regards,
--  
Dennis Nilsson <kontakt@dennisnilsson.se>

