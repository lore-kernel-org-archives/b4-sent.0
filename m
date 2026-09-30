From: Armandas Kvietkus <armandas.kvietkus@proton.me>
Subject: [PATCH 0/2] Input: Add Awinic AW8697 haptics driver
Date: Wed, 30 Sep 2026 18:08:02 +0200
Message-Id: <20260930-mainlining-v1-0-c303cbdb00c8@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4avIrDUp4vcqYtHWYIQhLSIRd1csv
 8V7Fzi0hA6q4AKLBzla2CMKAzCD4h4Ftd4QyziTZSLFrIgnYuJeSN0WOtepUZkBH6wWOzq/Wd3
 8drse0WzvAe77Ac557Q5uAAAA
X-Change-ID: 20260930-mainlining-0bd8b7b5ca6c
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Griffin Kroah-Hartman <griffin.kroah@fairphone.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Armandas Kvietkus <armandas.kvietkus@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790784482; l=1161;
 i=armandas.kvietkus@proton.me; h=from:subject:message-id;
 bh=i/nl+2/ftfJQdEEeUWjYhOBTqNBkCsF47VtX9GXuLpU=;
 b=A2JRVmR0dxoD+z/IKhCWstkdllfASWFoGHAeektW123uL5V2saBbgtQX1hcW5qqx+7+o2ratu
 YKRgU+bre0lAhy+oP2I45YabkFTsAOTsuc9KOIOQ8DTcTEz0HMVZjxQ
X-Developer-Key: i=armandas.kvietkus@proton.me; a=ed25519;
 pk=wuqmImJ9sKlDVcwALOvfGhjj7G8EBjjM4TpCdmlrAf8=
X-Endpoint-Received: by B4 Relay for armandas.kvietkus@proton.me/default with auth_id=974
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a driver for the Awinic AW8697 LRA haptic driver IC.
It is the vibrator in the Xiaomi POCO F3.

The AW8697 is an older generation than the AW86927. The register map
is different, so it gets its own driver. The binding reuses
awinic,aw86927.yaml.

Tested on the phone: rumble at several strengths, 72 effects in a row,
stop on close, driver rebind and module reload.

Signed-off-by: Armandas Kvietkus <armandas.kvietkus@proton.me>
---
Armandas Kvietkus (2):
      dt-bindings: input: awinic,aw86927: Add Awinic AW8697
      Input: aw8697 - Add Awinic AW8697 haptics driver

 .../devicetree/bindings/input/awinic,aw86927.yaml  |   4 +-
 MAINTAINERS                                        |   6 +
 drivers/input/misc/Kconfig                         |  14 +
 drivers/input/misc/Makefile                        |   1 +
 drivers/input/misc/aw8697.c                        | 725 +++++++++++++++++++++
 5 files changed, 749 insertions(+), 1 deletion(-)
---
base-commit: 165768bb70265b5c38cf0b73fafd75be235f8b14
change-id: 20260930-mainlining-0bd8b7b5ca6c

Best regards,
--  
Armandas Kvietkus <armandas.kvietkus@proton.me>

