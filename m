From: =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
Subject: [PATCH v2 0/2] Add support for the DFRobot SEN0322 oxygen sensor
Date: Mon, 05 May 2025 09:52:57 +0200
Message-Id: <20250505-iio-chemical-sen0322-v2-0-217473983b42@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAFluGGgC/4WNTQ6CMBBGr0Jm7Zh2+BFdeQ/DgtYpTAItaQ3RE
 O5u5QIu30u+922QOAonuBUbRF4lSfAZ6FSAHXs/MMozM5CiWlXUokhAO/Istp8wsVclEVrXOmM
 MX+qqgTxdIjt5H9lHl3mU9Arxc7ys+mf/BFeNCq9Gt2VTOscV3Ye5l+lswwzdvu9fIFMUBbgAA
 AA=
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746431586; l=1057;
 i=gomba007@gmail.com; s=20230706; h=from:subject:message-id;
 bh=HoVwgT0i6eQ5F0/UMVrAUgnAI8MgPO+NzAAD51dIqnU=;
 b=XO542HNnKgid7hj9NoQ+7o+FzzeC5MmDo6ymU7S/zh5narQlm6FOtiUtWlvP7SwqEbdGKljGa
 giu/oVLF0aDDmfU3ACwuNKlTSBu2+/vmVthiVtgXhDk6IVour77yTg5
X-Developer-Key: i=gomba007@gmail.com; a=ed25519;
 pk=iY9MjPCbud82ULS2PQJIq3QwjKyP/Sg730I6T2M8Y5U=
X-Endpoint-Received: by B4 Relay for gomba007@gmail.com/20230706 with auth_id=60
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset adds a driver and the documentation for the
DFRobot SEN0322 oxygen sensor.

Signed-off-by: Tóth János <gomba007@gmail.com>
---
Changes in v2:
- Add SEN0322 to trivial-devices.
- Use _RAW and _SCALE instead of fixed-point math.
- Refactor based on reviewer's suggestions.
- Link to v1: https://lore.kernel.org/r/20250428-iio-chemical-sen0322-v1-0-9b18363ffe42@gmail.com

---
Tóth János (2):
      dt-bindings: trivial-devices: Document SEN0322
      iio: chemical: Add driver for SEN0322

 .../devicetree/bindings/trivial-devices.yaml       |   2 +
 MAINTAINERS                                        |   6 +
 drivers/iio/chemical/Kconfig                       |  10 ++
 drivers/iio/chemical/Makefile                      |   1 +
 drivers/iio/chemical/sen0322.c                     | 167 +++++++++++++++++++++
 5 files changed, 186 insertions(+)
---
base-commit: b4432656b36e5cc1d50a1f2dc15357543add530e
change-id: 20250428-iio-chemical-sen0322-cf8fbbbe7546

Best regards,
-- 
Tóth János <gomba007@gmail.com>

