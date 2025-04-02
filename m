From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 0/5] iio: light: Modernize al3010 and al3320a codebase
Date: Wed, 02 Apr 2025 21:14:12 +0200
Message-Id: <20250402-al3010-iio-regmap-v3-0-cc3da273b5b2@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAISM7WcC/32NQQ6CMBBFr0K6tmbasVJceQ/josIAkyiQljQo4
 e4WViyMy/eT9/4sAnmmIC7ZLDxFDtx3CfCQibJ1XUOSq8RCgzaAYKV7IiiQzL301LzcIAFtSQ6
 L2ppKJG/wVPO0NW/3xC2Hsffv7SKqdf1Xi0qCfJxzbdCQ1QqvPPF4LD9ibUW981Xxy9fJV6gg1
 0UF5rTzl2X5Arjh/xHwAAAA
X-Change-ID: 20250308-al3010-iio-regmap-038cea39f85d
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2104; i=david@ixit.cz;
 h=from:subject:message-id; bh=Cfri1NLIzlUgZilRlHcF6Uc8bZB/2/S835fUpiVCEG8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn7Yy2OJq9mTFL96N/Fw3kTF1F7S/tllq1bbteS
 1f06jEzeaCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+2MtgAKCRBgAj/E00kg
 cqp4D/9rC1CkpeBs9N5PZlrTlGgeR1Caex2oJyaDmfKIYtJknSCVfJJE9eXHrkd4Lq33sPTwR1Q
 oyn0Tm2Ej1Ca5DxgBTeMbDG00KZOBFECTv+H0QgwB3zLJRmVi4Ua1F92syzWAhjFM6N2zoYRB0h
 wz5Cnuf8MhcUMfZcY4ZK5mVt+sRD/z8PbB2I1fjXrJzC7j7FOkFOmEQgEBIeEwkKI1K6yDN95Bu
 6MtSzfEPH7HTu+V1o8omsMJPrB/x2ptthgnztBDLKBHZqj4Xsi6kMRGCiGu+7J1eq9P2gUBnZ/S
 6wfIFinlzWvC/rF32x2SQZr0JE+s7GpiHSFndbSTu7Rr6g24OsgBrocSgqhqRAeW/zc7A6DxjZg
 2qemO+7z+3EOiIOmJskJW/Po1PZOZekyeRZEtQmL8QjvK34hqYn5A3CGavAbqkSbbh15N7WXu0D
 IvS0u5E6jaczlcS9aBDtPncp7kIV3cAjA+iq779rq9kwum0lP3sIMrjr80j0Wn2ZE6aAYARFXOg
 YN16VnaLzVHUtVcC+1/iP+KvJizQxB1aeYTwLfOhbSdJe6Ji5a1K4L/jjBjgif3slYixUEiDpe6
 +2XSk2/vOZffHExSjgk4PEpmCzI6+yIPpQ/o57xES9IlfH/Qy31pFWiRlUYuHF/I3vRNGiC3aZG
 RhjSMrAH4zPmdKA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series aims to improve code readability and modernize it to align
with the recently upstreamed AL3000a.

Apart from slightly improved error reporting, and error handling
there should be no functional changes.

Module  before after
al3010  72 kB  58 kB
al3320a 72 kB  58 kB

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v3:
- Stripped patches merged from second version of patchset.
- Dropped iio: light: al3010: Move devm_add_action_or_reset back to _probe
  in favor of opposite approach moving devm_add.. to _init for al3xx0a:
  - iio: light: al3000a: Fix an error handling path in al3000a_probe()
  - iio: light: al3320a: Fix an error handling path in al3320a_probe()
- Link to v2: https://lore.kernel.org/r/20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz

Changes in v2:
- Dropped Daniel's email update.
- Dropped DRV_NAME introduction for al3000a
- Added DRV_NAME define removal for al3010 and al3320a.
- Splitted unsigned int conversion into separate patches.
- Replaced generic value with specific raw and gain variable.
- Use dev_err_probe() for error handling.
- Separated devm_add_action_or_reset move from _init back to _probe.
- Dropped copyright update.
- Link to v1: https://lore.kernel.org/r/20250308-al3010-iio-regmap-v1-0-b672535e8213@ixit.cz

---
David Heidelberg (5):
      iio: light: al3010: Improve al3010_init error handling with dev_err_probe()
      iio: light: al3000a: Fix an error handling path in al3000a_probe()
      iio: light: al3320a: Fix an error handling path in al3320a_probe()
      iio: light: al3010: Implement regmap support
      iio: light: al3320a: Implement regmap support

 drivers/iio/light/al3000a.c |  8 ++--
 drivers/iio/light/al3010.c  | 80 +++++++++++++++++++++-------------------
 drivers/iio/light/al3320a.c | 90 +++++++++++++++++++++++++--------------------
 3 files changed, 98 insertions(+), 80 deletions(-)
---
base-commit: f8ffc92ae9052e6615896052f0c5b808bfc17520
change-id: 20250308-al3010-iio-regmap-038cea39f85d

Best regards,
-- 
David Heidelberg <david@ixit.cz>

