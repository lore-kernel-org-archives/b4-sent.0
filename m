From: Mikael Gonella-Bolduc <mgonellabolduc@dimonoff.com>
Subject: [PATCH 0/2] Add support for Avago/Broadcom APDS9160
Date: Tue, 19 Nov 2024 15:36:55 -0500
Message-Id: <20241119-apds9160-driver-v1-0-fa00675b4ea4@dimonoff.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOf2PGcC/x3MQQqAIBBA0avIrBMaK6muEi1Ex5qNxQgRiHdPW
 r7F/wUyCVOGVRUQejjzlRqwU+BPlw7SHJrB9GZExEW7O+QFba+D8EOiZ+vjRLMNNEzQqlso8vs
 ft73WD10JX6xhAAAA
X-Change-ID: 20241119-apds9160-driver-86cf5e86de35
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>
Cc: Mikael Gonella-Bolduc <m.gonella.bolduc@gmail.com>, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, llvm@lists.linux.dev, 
 Mikael Gonella-Bolduc <mgonellabolduc@dimonoff.com>, 
 Hugo Villeneuve <hvilleneuve@dimonoff.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732048621; l=926;
 i=mgonellabolduc@dimonoff.com; s=20241119; h=from:subject:message-id;
 bh=5ZtJ47OwVXBSoFV+aJ4Xr6HwqQoievLKVIyNMZI/poc=;
 b=+ma2BrFzBD30dJSA+R6419ctgdetUJPQudiqX55DnAVS9N7flyeN+0wL/u1JvSjUCbi8q+pqj
 6PrWSEvetk0C9U/p4dynYYXUO38MIYK7wBAMY8+O/QG3h/CX6/bITkh
X-Developer-Key: i=mgonellabolduc@dimonoff.com; a=ed25519;
 pk=p4tvPfGPfXRyChsgHc6s7HwB6YBl2JqqcP3BXtoDitE=
X-Endpoint-Received: by B4 Relay for mgonellabolduc@dimonoff.com/20241119 with auth_id=279
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

APDS9160 is an ALS and proximity sensor.
https://www.broadcom.com/products/optical-sensors/integrated-ambient-light-and-proximity-sensors/apds-9160-003

Signed-off-by: Mikael Gonella-Bolduc <mgonellabolduc@dimonoff.com>
---
Mikael Gonella-Bolduc (2):
      dt-bindings: iio: light: Add APDS9160 binding
      iio: light: Add APDS9160 ALS & Proximity sensor driver

 .../bindings/iio/light/avago,apds9160.yaml         |   50 +
 MAINTAINERS                                        |    7 +
 drivers/iio/light/Kconfig                          |   13 +
 drivers/iio/light/Makefile                         |    1 +
 drivers/iio/light/apds9160.c                       | 1420 ++++++++++++++++++++
 5 files changed, 1491 insertions(+)
---
base-commit: adc218676eef25575469234709c2d87185ca223a
change-id: 20241119-apds9160-driver-86cf5e86de35

Best regards,
-- 
Mikael Gonella-Bolduc <mgonellabolduc@dimonoff.com>

