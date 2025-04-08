From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH v2 0/2] Onboard USB device support for RTL8188ETV 2.4GHz
 USB WiFi module
Date: Tue, 08 Apr 2025 21:13:11 +0200
Message-Id: <20250408-rtl-onboard-v2-0-0b6730b90e31@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAEd19WcC/23MywrCMBCF4VcpszYyuVTUVd9DukjaqQ1IpiQhK
 CXvbuza5X/gfDskip4S3LsdIhWfPIcW6tTBtNrwJOHn1qBQ9WhQi5hfgoNjG2ex6KvuzYJOGgf
 tsUVa/PvQHmPr1afM8XPgRf7W/06RAoXEyd7sxRoiHDZOmfgcKMNYa/0C8hFdd6cAAAA=
X-Change-ID: 20250403-rtl-onboard-f38354f0b14b
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Matthias Kaehlcke <mka@chromium.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jes Sorensen <Jes.Sorensen@gmail.com>, linux-wireless@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, Bitterblue Smith <rtl8821cerfe2@gmail.com>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744139638; l=1198;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=CKwo4CEyVgAnPR0XP4Ca6WTn2rjHiPkVkvAQlXqXWe0=;
 b=uUhCgcSt/puX3o3dWNQZSDas53VdL2UfuHpeEbhOQOvmlroP9iHibEpRQjLg2ojIeIgbRcZ+a
 0KTiyVQ+UswBYmyG95EETp/oya+UIrjBca2XXS3o0ODLyw+0pcTHz6E
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset adds rtl8188etv (usbbda,179) to the onboard_usb_dev driver.
It is found in a set-top box called "Fernsehfee 3.0".

As a side note, this device is currently marked untested in the RTL8XXXU
driver. In my experience it works (tested with a WPA2 home network).

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
Changes in v2:
- Fix editing errors (email address and TODO comment) in binding
- Refer to more specific RTL8188ETV instead of RTL8188
- Use unambiguous SPDX identifier GPL-2.0-only instead of GPL-2.0
- Link to v1: https://lore.kernel.org/r/20250403-rtl-onboard-v1-0-10ca9a6a4ee0@posteo.net

---
J. Neuschäfer (2):
      dt-bindings: net: wireless: Add Realtek RTL8188ETV USB WiFi
      usb: misc: onboard_dev: Add Realtek RTL8188ETV WiFi (0bda:0179)

 .../bindings/net/wireless/realtek,rtl8188e.yaml    | 50 ++++++++++++++++++++++
 drivers/usb/misc/onboard_usb_dev.c                 |  1 +
 drivers/usb/misc/onboard_usb_dev.h                 |  8 ++++
 3 files changed, 59 insertions(+)
---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250403-rtl-onboard-f38354f0b14b

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

