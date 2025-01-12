From: Vasiliy Doylov <nekodevelopper@gmail.com>
Subject: [PATCH v3 0/5] iio: accel: mc3230: add mount matrix, of match and
 mc3510c support
Date: Sun, 12 Jan 2025 15:25:34 +0300
Message-Id: <20250112-mainlining-mc3510c-v3-0-9ee6520ab69d@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL60g2cC/32NQQ6DIBBFr2Jm3WlApZqueo/GBcKAkygaaEgb4
 91LPUCX7+f/93dIFJkS3KsdImVOvIYCzaUCM+ngCdkWhlrUSkgpcdEcZg4cPC6mUVIYVLe2E7U
 bddt3UIZbJMfvU/ocCk+cXmv8nB9Z/tK/uixRoOpGUqLR1rr+4Utrvpp1geE4ji8i/3o+tAAAA
 A==
X-Change-ID: 20250111-mainlining-mc3510c-564702fba487
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Vasiliy Doylov <nekodevelopper@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1275;
 i=nekodevelopper@gmail.com; h=from:subject:message-id;
 bh=e0ydEge+kSwWNQjHzk+12rYyMrffoSe8Ys0yrFFY5Yc=;
 b=owGbwMvMwCW2fZ/SFZeSpU2Mp9WSGNKbt7xyabhccEjz2dU1S5LOHJX17J1/vfFE6J3O/vm3V
 isnXv38uqOUhUGMi0FWTJHFZqPHbLH8cMlJ054qwMxhZQIZwsDFKQATWbOLkWGOdt+SaetnO/67
 9ZRxk3jf2y+xtoLL44Vvcc3i3jeJ4epmRoZ3H3c/3xd0cc8sue1r3m7X4rvytFbFIqFitlVqosL
 G0NlsAA==
X-Developer-Key: i=nekodevelopper@gmail.com; a=openpgp;
 fpr=3CB1489B166F57199296E520B7BE22D44474A582
X-Endpoint-Received: by B4 Relay for nekodevelopper@gmail.com/default with auth_id=314
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Changes includes:
- Add mount matrix handling
- Add match table to work with DT
- Add MC3510C support

MC3510C use same registors as MC3230, but different value scale.

Signed-off-by: Vasiliy Doylov <nekodevelopper@gmail.com>
---
Changes in v2:
- Ordered commits
- Fixed comment style
- Ordered struct members
- Fixed device table
- MC5310C commit splitted
- Link to v1: https://lore.kernel.org/r/20250111-mainlining-mc3510c-v1-0-57be503addf8@gmail.com

Changes in v3:
- Fixed patch (poped stash)
- Link to v2: https://lore.kernel.org/all/20250112-mainlining-mc3510c-v2-0-322804a545cf@gmail.com

---
Vasiliy Doylov (5):
      dt-bindings: iio: accel: mc3230: document mc3510c
      iio: accel: mc3230: add mount matrix support
      iio: accel: mc3230: add OF match table
      iio: accel: mc3230: add multiple devices support
      iio: accel: mc3230: add mc3510c support

 .../devicetree/bindings/trivial-devices.yaml       |  2 +
 drivers/iio/accel/mc3230.c                         | 93 ++++++++++++++++++----
 2 files changed, 79 insertions(+), 16 deletions(-)
---
base-commit: 2b88851f583d3c4e40bcd40cfe1965241ec229dd
change-id: 20250111-mainlining-mc3510c-564702fba487

Best regards,
-- 
Vasiliy Doylov <nekodevelopper@gmail.com>

