From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Subject: [PATCH 0/2] iio: imu: inv_icm42600: switch to use generic name irq
 get
Date: Fri, 04 Apr 2025 17:52:01 +0200
Message-Id: <20250404-iio-imu-inv-icm42600-rework-interrupt-using-names-v1-0-72ed5100da14@tdk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACIA8GcC/x2NwQ6CMBAFf4Xs2U1qK6L+CvGAZcUX05ZsKZoQ/
 t3G48xhZqMsCsl0azZSWZGRYoXjoSH/GuIkjLEyWWNb42zLQGKEwogrw4eTPRvDKp+k7+oWUS3
 zwiUjThyHIJkf7tp5GTt7cS3V7qzyxPf/7O/7/gOFo0kXgwAAAA==
X-Change-ID: 20250325-iio-imu-inv-icm42600-rework-interrupt-using-names-b397ced72835
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743781928; l=1064;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=g4Iysgwpe8lGdu8CwXjRXHZRqni06iQGyaV8tJgj1mw=;
 b=TIiNFxaOUvvI94XEv0fEIFpl7os48WSsLvDqHC/Y90wC0sNKrGzsJaKW8hxSY8oFarfIY5Xfo
 rAQy4lJtgEQASAfcS6FPC21sCgXoPcukzntnHP5rYY9dO9NdD6t50CO
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The purpose of this series is to switch to fwnode_irq_get_by_name()
in the core module instead of using irq from the bus parsing.
Add interrupt naming and support only INT1.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
Jean-Baptiste Maneyrol (2):
      dt-bindings: iio: imu: icm42600: add interrupt naming support
      iio: imu: inv_icm42600: switch to use generic name irq get

 .../devicetree/bindings/iio/imu/invensense,icm42600.yaml    |  8 ++++++++
 drivers/iio/imu/inv_icm42600/inv_icm42600.h                 |  2 +-
 drivers/iio/imu/inv_icm42600/inv_icm42600_core.c            | 13 +++++++++++--
 drivers/iio/imu/inv_icm42600/inv_icm42600_i2c.c             |  2 +-
 drivers/iio/imu/inv_icm42600/inv_icm42600_spi.c             |  2 +-
 5 files changed, 22 insertions(+), 5 deletions(-)
---
base-commit: f8ffc92ae9052e6615896052f0c5b808bfc17520
change-id: 20250325-iio-imu-inv-icm42600-rework-interrupt-using-names-b397ced72835

Best regards,
-- 
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

