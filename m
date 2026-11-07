From: Michiel van Beers <michielvanbeers@gmail.com>
Subject: [PATCH 0/2] backlight: lm3630a: Add a per-bank full-scale current
 limit
Date: Sat, 07 Nov 2026 13:13:53 +0100
Message-Id: <20261107-lm3630a-led-max-microamp-v1-0-ec9e441d9b2c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAEW72oC/yXMTQ6CMBBA4auQWTtJf9IavIpxMQ6jjqFAWjQkh
 LtbZPkt3luhSFYpcGlWyPLVouNQYU8N8IuGp6B21eCMi9aaM/bJR28Ie+kw0YJJOY+UJuTYehc
 8tYED1HzK8tDlv77eDpfP/S087z/Yth88vuKufAAAAA==
X-Change-ID: 20261107-lm3630a-led-max-microamp-c693253a95c5
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Pavel Machek <pavel@kernel.org>, 
 Griffin Kroah-Hartman <griffin@kroah.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Helge Deller <deller@gmx.de>
Cc: dri-devel@lists.freedesktop.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fbdev@vger.kernel.org, Michiel van Beers <michielvanbeers@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794053659; l=2212;
 i=michielvanbeers@gmail.com; s=20261107; h=from:subject:message-id;
 bh=M8fM/pimHRx8tpjVsk5Qa5piBItoVw829MhvZQytYiY=;
 b=Gp+M1tpl6Uxw25mEvIymG6qpZ0SfxBhMKPsshgAvw8ZW14OheuknsDPXJOABSPArSVTpM3oNI
 5E8agsqLbrHCkhDIvs1z+fbyG3B5uPxRpD5UocdI741zOZmoIoQbDI9
X-Developer-Key: i=michielvanbeers@gmail.com; a=ed25519;
 pk=C+lOje7u3+2x3o2NLMXrwz2veP2++eXfIi9MtYsUo4k=
X-Endpoint-Received: by B4 Relay for michielvanbeers@gmail.com/20261107 with auth_id=1444
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LM3630A driver always programs the full-scale current of both
control banks to the chip maximum of 28.25 mA. This series adds the
common led-max-microamp property to the binding and makes the driver
program it, so boards whose LEDs are rated for less can set a lower
limit.

My use case is the frontlight of the Onyx Boox Leaf e-reader (SDM636),
where Onyx's Android kernel sets the full-scale current of both banks
to 12.5 mA. The board devicetree is not upstream yet.

Patch 1 documents the property, patch 2 implements it. Both are meant
to go through the backlight tree.

Testing:
- Onyx Boox Leaf, 7.2.y kernel (sdm660-mainline) with patch 2 applied:
  led-max-microamp = <12500> on both banks reads back as code 0x0a in
  both full-scale registers, and the frontlight works normally. 5000
  and 28250 give codes 0x00 and 0x1f, with bank A visibly dimmer at
  5 mA; 28500 makes probe fail with -EINVAL. The driver in 7.4-rc1
  differs from 7.2.y only by an unrelated change in lm3630a_remove().
- dt_binding_check, and dtbs_check of all in-tree boards with an
  LM3630A (rk3566-pinenote, the i.MX6 Kobo and Tolino e-readers,
  Nexus 5, OnePlus One): no warnings for this binding.
- arm64 build with W=1 and sparse: no new warnings.

AI disclosure: I prepared this series with Claude Code (Anthropic,
Claude Opus 5.5). It drafted the driver change and the commit messages
from my description of the problem and the datasheet, and proposed the
checks above; I ran the checks and the hardware test, reviewed every
line, and take responsibility for the patches.

---
Michiel van Beers (2):
      dt-bindings: backlight: lm3630a: Add led-max-microamp
      backlight: lm3630a: Allow setting the full-scale current per bank

 .../bindings/leds/backlight/lm3630a-backlight.yaml |  9 +++++
 drivers/video/backlight/lm3630a_bl.c               | 40 +++++++++++++++++++---
 include/linux/platform_data/lm3630a_bl.h           |  4 +++
 3 files changed, 49 insertions(+), 4 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261107-lm3630a-led-max-microamp-c693253a95c5

Best regards,
--  
Michiel van Beers <michielvanbeers@gmail.com>

