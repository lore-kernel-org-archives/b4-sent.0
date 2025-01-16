From: Vasiliy Doylov <nekodevelopper@gmail.com>
Subject: [PATCH RESEND v4 0/5] iio: accel: mc3230: add mount matrix, of
 match and mc3510c support
Date: Thu, 16 Jan 2025 16:52:41 +0300
Message-Id: <20250116-mainlining-mc3510c-v4-0-a41308b85ec2@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Vasiliy Doylov <nekodevelopper@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1546;
 i=nekodevelopper@gmail.com; h=from:subject:message-id;
 bh=zJGJo69lBvaa7jyTghcNGFOtdhlAd60prLEiVMAUezY=;
 b=owGbwMvMwCW2fZ/SFZeSpU2Mp9WSGNI7+SOXVjnvblV5p7ST9egzHS3ffOOpdhz+03h+7A25H
 NuQGaTcUcLCIMbFICumyGKz0WO2WH645KRpTxVg5rAygQxh4OIUgImILmD4cayVn8832yZvUnzD
 2akrDpd4Tav1al97+9Umef3+hMy9DP801kXxGci8uNr8enFP5u0zXR5su481rikTq3PpaFnq7MM
 HAA==
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
Changes in v4:
- Fixed commit messages
- Added const modificator to chip_infos
- Return name->chip_id->product_code->scale order
- `{}` replaced by `{ }` (with space)
- Link to v3: https://lore.kernel.org/r/20250112-mainlining-mc3510c-v3-0-9ee6520ab69d@gmail.com

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
 drivers/iio/accel/mc3230.c                         | 95 ++++++++++++++++++----
 2 files changed, 80 insertions(+), 17 deletions(-)
---
base-commit: 2b88851f583d3c4e40bcd40cfe1965241ec229dd
change-id: 20250111-mainlining-mc3510c-564702fba487

Best regards,
-- 
Vasiliy Doylov <nekodevelopper@gmail.com>

