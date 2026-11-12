From: Paul Sajna <sajattack@postmarketos.org>
Subject: [PATCH v5 0/3] leds: aw2013: Add AW2027 support
Date: Thu, 12 Nov 2026 14:22:55 -0700
Message-Id: <20261112-aw2013-aw20xx-rename-v5-0-b2c5e323a90a@postmarketos.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XRwU7DMAwG4FeZcibIdpZm3Yn3QBySxt0itGYkp
 RRNfXfSgoADESfrt5TPlnMTmVPgLI67m0g8hRziUIK+24nubIcTy+BLFgTUQAtG2jcCVFuZZ5l
 4sBeWvielOt0Sdo0oT6+J+zBv7ONTyeeQx5jetykTrt1/wAklyK61xvdI1gA+XGMeLzY98xjzf
 UwnsboTfVsIoCsWFQvhwJ0rexqjK5b6ZSFVLLXuZR323oMG11Ss/Y9VJlesvUR5oEZT65idpj+
 s5fOYiV9ey9eMXxddlg/hLym1uAEAAA==
X-Change-ID: 20260907-aw2013-aw20xx-rename-df233c5921c6
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Nikita Travkin <nikitos.tr@gmail.com>, 
 Alexey Min <alexeymin@minlexx.ru>, David Heidelberg <david@ixit.cz>, 
 Griffin Kroah-Hartman <griffin@kroah.com>
Cc: Nikita Travkin <nikita@trvn.ru>, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 Paul Sajna <sajattack@postmarketos.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794518585; l=3073;
 i=sajattack@postmarketos.org; s=20250413; h=from:subject:message-id;
 bh=ghx1yKBekh/GVJRfqOPS1UW6mRfmE2JnepEDR+3pOo8=;
 b=JaySK5geGCYVAKF4nLZ1ABXHCv8UM0ihMNy1g7Hb1AL8yHFBjBHVyZDGo8rO338MrgSSoA78J
 ZD4QUvo53bQBD9PaQNvvgtk+2bK7sfQSsAa6QaF8aXyfIWwd/JEX6tV
X-Developer-Key: i=sajattack@postmarketos.org; a=ed25519;
 pk=ZFE/UBqiz9Wr8b+zBL27opOjw5x5ket5JFqks/VQGeM=
X-Endpoint-Received: by B4 Relay for sajattack@postmarketos.org/20250413 with auth_id=1505
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Refer to PATCH 2 for a full description of the similarities and
differences between AW2013 and AW2027.

I'm hoping the sashiko reviews about unbalanced regulators that I was
struggling to fix are covered by
https://lore.kernel.org/linux-leds/20261021123406.3163547-1-lee@kernel.org/
and I can drop my failed attempts to fix them.
Let me know if I misunderstood.

I'll do my best to address all of Sashiko's comments, but it might take
me some time to circle back, don't bother reviewing until I've done
this.

This PATCH resulted out of discussions pertaining to
sdm660-mainline/linux, a close-to-mainline fork for Qualcomm Snapdragon 660
devices, specifically for the BlackBerry KEY2 Keyboard Backlight,
in the following GitHub PR: https://github.com/sdm660-mainline/linux/pull/218

Signed-off-by: Paul Sajna <sajattack@postmarketos.org>
---
Changes in v5:
- Drop move of chip->num_leds
- Make aw2013_microamp_to_imax more readable
- rebase to next-20261112 for Lee's changes
- Link to v4: https://lore.kernel.org/linux-leds/20261108-aw2013-aw20xx-rename-v4-0-826529beeb52@postmarketos.org/

Changes in v4:
- Drop sashiko fixes covered by https://lore.kernel.org/linux-leds/20261021123406.3163547-1-lee@kernel.org/
- Rename the chip id register value to reflect that it covers more chips
  (https://www.awinic.com/en/driver/AW2027DNR/640)
- Address preliminary review comments from Lee Jones
- Link to v3: https://lore.kernel.org/r/20261012-aw2013-aw20xx-rename-v3-0-cab1fdd050b6@postmarketos.org

Changes in v3:
- Drop rename
- Capitalize commit subject
- Extra tweaks to cleanup patches (preventing more unbalanced regulator
  stuff)
- Whitespace fiddling
- Link to v2: https://lore.kernel.org/r/20261005-aw2013-aw20xx-rename-v2-0-108ecbdf2775@postmarketos.org

Changes in v2:
- Reduce renames to internal driver scope, to prevent breaking compat
- Address Sashiko Review Comments
- Split renames into a separate commit to make the actual changes easier
to identify
- Change from RFC to PATCH
- Link to v1: https://lore.kernel.org/r/20260907-aw2013-aw20xx-rename-v1-0-c9a7df12a701@postmarketos.org

To: Lee Jones <lee@kernel.org>
To: Pavel Machek <pavel@kernel.org>
To: Griffin Kroah-Hartman <griffin@kroah.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Nikita Travkin <nikitos.tr@gmail.com>
Cc: linux-leds@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Paul Sajna (3):
      dt-bindings: leds: aw2013: Add awinic,aw2027 compatible
      leds: aw2013: Add AW2027 support
      leds: aw2013: Use dev_err_probe

 .../devicetree/bindings/leds/leds-aw2013.yaml      |   6 +-
 drivers/leds/leds-aw2013.c                         | 175 +++++++++++++++++----
 2 files changed, 146 insertions(+), 35 deletions(-)
---
base-commit: 6d582d78fad9d828e575ca0cdcff8ea47a77220b
change-id: 20260907-aw2013-aw20xx-rename-df233c5921c6

Best regards,
--  
Paul Sajna <sajattack@postmarketos.org>

