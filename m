From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH 0/2] Onboard USB device support for RTL8188 2.4GHz USB WiFi
 module
Date: Thu, 03 Apr 2025 16:07:47 +0200
Message-Id: <20250403-rtl-onboard-v1-0-10ca9a6a4ee0@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIADOW7mcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDEwNj3aKSHN38vKT8xKIU3TRjC2NTkzSDJEOTJCWgjoKi1LTMCrBp0bG
 1tQB8OGQZXQAAAA==
X-Change-ID: 20250403-rtl-onboard-f38354f0b14b
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.neuschaefer@gmx.net>, 
 Matthias Kaehlcke <mka@chromium.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jes Sorensen <Jes.Sorensen@gmail.com>, linux-wireless@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743689273; l=886;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=39VMYhU+74mMPI9DI3V/VxZjDFcE/1tMwt7m4qa+2nU=;
 b=GBtBg4J3jFJRTewN2BJhs+xjZvDIbF3WaNoVycTobq+8M+1FCplFQjhzYoe7LKvp7cOnCZZQn
 J1i+FWjzMRFAP9zWIkQuT5OMKg/oKA3Iw3DhlMNPK2EfO2MHeNGPhRr
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset adds rtl8188 (usbbda,179) to the onboard_usb_dev driver.
It is found in a set-top box called "Fernsehfee 3.0".

As a side note, this device is currently marked untested in the RTL8XXXU
driver. In my experience it works (tested with a WPA2 home network).

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
J. Neuschäfer (2):
      dt-bindings: net: wireless: Add Realtek RTL8188 USB WiFi
      usb: misc: onboard_dev: Add Realtek RTL8188 WiFi (0bda:0179)

 .../bindings/net/wireless/realtek,rtl8188.yaml     | 51 ++++++++++++++++++++++
 drivers/usb/misc/onboard_usb_dev.c                 |  1 +
 drivers/usb/misc/onboard_usb_dev.h                 |  8 ++++
 3 files changed, 60 insertions(+)
---
base-commit: 38fec10eb60d687e30c8c6b5420d86e8149f7557
change-id: 20250403-rtl-onboard-f38354f0b14b

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

