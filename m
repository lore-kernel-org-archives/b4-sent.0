From: Wayne Ho <wayneho219@gmail.com>
Subject: [PATCH 0/2] Documentation: ABI: leds: document shared trigger
 attributes
Date: Thu, 01 Oct 2026 14:45:10 +0800
Message-Id: <20261001-docs-leds-abi-trigger-attrs-v1-0-54f0529bf0f6@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQqDMAyA4VeRnBdoe5Dpq4wdahO7DNGRdCKI7
 27njt9/+HcwVmGDvtlBeRWTZa7wtwbSK86ZUagaggutd84jLclwYjKMg2BRyZkVYylaS3BMXdv
 dPRHUw0d5lO26P55/23d4cyq/JRzHCaHdwIp/AAAA
X-Change-ID: 20261001-docs-leds-abi-trigger-attrs-a20ed96981dd
To: Pavel Machek <pavel@kernel.org>, Lee Jones <lee@kernel.org>
Cc: linux-leds@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790837130; l=1201;
 i=wayneho219@gmail.com; s=20261001; h=from:subject:message-id;
 bh=b8SsPNCMf2P/rDCw8LMLQ920RO5dT0DnJ5JXyQUF93s=;
 b=F+x7/1B3ov1YqCJCzfEEzKMhgItTkQNGQ0b/IDpf9DkVqSKxhvucxbt8ic3WNvVR8e8gf4N5G
 BA/7qNrz+G8AH+MxOa+qs8xE9bobh5FfM7+Qd/AAKPY/1uThVCBoZH+
X-Developer-Key: i=wayneho219@gmail.com; a=ed25519;
 pk=j25LRSikYRlv0PpovZSgSrCQwsy7WDzIYum/mydUa3A=
X-Endpoint-Received: by B4 Relay for wayneho219@gmail.com/20261001 with auth_id=1093
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The delay_on, delay_off and invert attributes are created by several
LED triggers, but only the oneshot variants are documented. Adding a
separate ABI file per trigger would make get_abi.py report the same
sysfs path as defined more than once, so patch 2 moves these entries
to sysfs-class-led and describes each trigger's behaviour there.

Patch 1 is a small preparatory fix: the existing inverted entry still
mentions the gpio trigger, which no longer creates that attribute.

Checked with tools/docs/get_abi.py validate (no new warnings) and
scripts/checkpatch.pl (clean).

Signed-off-by: Wayne Ho <wayneho219@gmail.com>
---
Wayne Ho (2):
      Documentation: ABI: leds: inverted is specific to the backlight trigger
      Documentation: ABI: leds: document timer, heartbeat and activity attributes

 Documentation/ABI/testing/sysfs-class-led          | 73 +++++++++++++++++++++-
 .../ABI/testing/sysfs-class-led-trigger-oneshot    | 29 ---------
 2 files changed, 70 insertions(+), 32 deletions(-)
---
base-commit: 5dd1818b15d98d4a20806cd00b1b40320b06004f
change-id: 20261001-docs-leds-abi-trigger-attrs-a20ed96981dd

Best regards,
--  
Wayne Ho <wayneho219@gmail.com>

