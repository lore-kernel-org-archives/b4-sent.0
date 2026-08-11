From: Esteban Urrutia <esteuwu@proton.me>
Subject: [PATCH v3 0/2] Add support for Parade PS5169 USB Type-C linear
 redriver
Date: Mon, 10 Aug 2026 23:31:35 -0400
Message-Id: <20260810-ps5169-bup-v3-0-a2178b2834d7@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1WNSw7CIAAFr9KwFsNHfq68h3EBlFpMLATaRtP07
 kKNSV1O8mbeArJL3mVwbhaQ3OyzD0MBemiA7fVwd9C3hQFBhCNBOIyZYa6gmSKUSHDJcGsJY6A
 IMbnOv7bY9fblPJmHs2Mt1EXv8xjSe3ubcd39wmIfnjFE0AqupeuoIVRdYgpjGI5PB2p4JntV/
 amkqARRg/RJSYn1Xl3X9QNImWtB8QAAAA==
X-Change-ID: 20260726-ps5169-bup-8076851dc255
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786419136; l=2771;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=CfrP8kWx2G67xzQzKPJ9k7kNbxnIkVMydTs6RXlHbA4=;
 b=Jsl7dB1ifuJdsLRVVMj5jfgNLTGpPh09C0r5Jmj6u69cErBw+e2yKZK6+0oXI68ZlxK3/F+jG
 /Khc/OKlDt/AnzAuor084Engnbb+9a4hjzC5o/jZYK/QBzqLSgDamMH
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Parade PS5169 is an USB Type-C linear redriver capable of handling:
- Two-lane USB 3.2 Gen2x2, at 10Gb/s
- Four-lane DP 1.4, at HBR3 (8.1Gb/s)
- Two-lane USB 3.2 Gen2x2, at 10Gb/s AND two-lane DP 1.4, at HBR3
(8.1Gb/s)

This redriver features programmable equalization and gain settings.
This series also future-proofs the binding and adds support for the
Parade PS5170.
Unlike PS5169, PS5170 embeds the AUX switch into the redriver.

The PS5169 redriver is found in the Motorola ThinkPhone by motorola,
device in which this driver was tested on.

Given Parade does not publish datasheets for their redrivers/retimers,
this implementation is based on downstream drivers.
Most of my work is based on [1], while registers were decoded from other
implementations, such as [2] and [3].

Switch/retimer set functions were adapted from NB7VPQ904M/PTN36502
implementations.

[1] https://github.com/LineageOS/android_kernel_motorola_sm8475/blob/lineage-22.2/drivers/usb/misc/ssusb-redriver-ps5169.c
[2] https://github.com/ilsubyeega/tb321fu-zui16/blob/main/kernel-6.1.68/kernel/drivers/usb/redriver/ps5169.c
[3] https://github.com/ferstar/xiaomi_xaga_kernel/blob/mglru/drivers/misc/mediatek/typec/mux/ps5170.c

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
Changes in v3:
- Change data type for equalization level.
- Fix port refs in DT. (Krzysztof)
- Normalize DT syntax.
- Normalize register and respective bit/mask/value defines/names.
- Properly handle if-then condition in DT. (Krzysztof)
- Properly handle mutex init.
- Remove parade,aux-rx-data-reverse.
  - Will be added back when its effects can be properly described.
  - Related registers have been kept.
- Use -db instead of -level for equalization properties. (Krzysztof)
- Use __le16 data type instead of using the cpu_to_le16() macro.
- Link to v2: https://patch.msgid.link/20260729-ps5169-bup-v2-0-203b0a49881a@proton.me

Changes in v2:
- Fix valid issues raised by Sashiko
- Link to v1: https://patch.msgid.link/20260727-ps5169-bup-v1-0-c76a8ef3b239@proton.me

---
Esteban Urrutia (2):
      dt-bindings: usb: Add Parade PS5169 redriver bindings
      usb: typec: Add support for Parade PS5169 USB Type-C redriver

 .../devicetree/bindings/usb/parade,ps5169.yaml     | 193 +++++++
 MAINTAINERS                                        |   7 +
 drivers/usb/typec/mux/Kconfig                      |  10 +
 drivers/usb/typec/mux/Makefile                     |   1 +
 drivers/usb/typec/mux/ps5169.c                     | 592 +++++++++++++++++++++
 5 files changed, 803 insertions(+)
---
base-commit: 3d08ff75a47a3e7e2ab45a3bcab6723b4d906422
change-id: 20260726-ps5169-bup-8076851dc255

Best regards,
--  
Esteban Urrutia <esteuwu@proton.me>

