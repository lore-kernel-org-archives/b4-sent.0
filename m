From: Vasiliy Doylov <nekodevelopper@gmail.com>
Subject: [PATCH 0/4] iio: accel: mc3230: add mount matrix, of match and
 mc3510c support
Date: Sat, 11 Jan 2025 23:11:05 +0300
Message-Id: <20250111-mainlining-mc3510c-v1-0-57be503addf8@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFnQgmcC/x3MQQqAIBBA0avErBMcy4quEi3MphqoKRQikO6et
 HyL/xNECkwR+iJBoJsjn5KBZQF+c7KS4jkbjDZWI6I6HMvOwrKqw1cWtVe2qVttlsnVXQs5vAI
 t/PzTYXzfDyS0haxkAAAA
X-Change-ID: 20250111-mainlining-mc3510c-564702fba487
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Vasiliy Doylov <nekodevelopper@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=836;
 i=nekodevelopper@gmail.com; h=from:subject:message-id;
 bh=t8rO8WUD6uhO20YWVe+sw/4QjdoLdy6VBKrhGozu+zQ=;
 b=owGbwMvMwCW2fZ/SFZeSpU2Mp9WSGNKbLkTb/1qydZrOWtN789QCfqot4Ta/sfgky/0711Iks
 0tETTUiOkpZGMS4GGTFFFlsNnrMFssPl5w07akCzBxWJpAhDFycAjAR/g+MDAedVfNX+j3V+neK
 6Zh72ka+GvvaCWIzf71T27pY6w2X+mmG/4Gz2bt4OezdXdzsmbs0dv+8Urv37SRt3TNGOYKpf1+
 XMwEA
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
Vasiliy Doylov (4):
      iio: accel: mc3230: add mount matrix support
      iio: accel: mc3230: add OF match table
      iio: accel: mc3230: add mc3510c support
      dt-bindings: iio: accel: mc3230: document mc3510c

 .../devicetree/bindings/trivial-devices.yaml       |  2 +
 drivers/iio/accel/mc3230.c                         | 88 ++++++++++++++++++----
 2 files changed, 76 insertions(+), 14 deletions(-)
---
base-commit: 2b88851f583d3c4e40bcd40cfe1965241ec229dd
change-id: 20250111-mainlining-mc3510c-564702fba487

Best regards,
-- 
Vasiliy Doylov <nekodevelopper@gmail.com>

