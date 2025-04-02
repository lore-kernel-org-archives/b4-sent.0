From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v4 0/5] iio: light: Modernize al3010 and al3320a codebase
Date: Wed, 02 Apr 2025 21:33:23 +0200
Message-Id: <20250402-al3010-iio-regmap-v4-0-d189bea87261@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAASR7WcC/33NQQ6CMBCF4auQrq2ZzlABV97DuCilwCQqpBCCE
 u5uYYMxxOU/yfdmEp3z7Dpxjibh3cAdN88Q8SEStjbPykkuQgsE1ECQSnMnUCCZG+ld9TCtBEq
 tM5SVqS5EcK13JY/r5vUWuuaub/xrfTGo5fpvbVASZH5KUJN2KSq68Mj90b7FsjXgl1fZnsfgF
 SlIMCtAxz+eNh8D7nkK3loqDCaU6xw3P8/zByLKH7IwAQAA
X-Change-ID: 20250308-al3010-iio-regmap-038cea39f85d
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2341; i=david@ixit.cz;
 h=from:subject:message-id; bh=h8tuvLDl3dyrMAHTp36dgdIbL6QYBpALFuJOwvb3DtQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn7ZEJdW8z5YiN6QhjsBgTBRscuK546wMo+6Olk
 VdZn8oC+LKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+2RCQAKCRBgAj/E00kg
 cvqUEADIYmKqGehh/rtSMJdz0ro0TLyKN6/f7m/2eQ03EGb0w4CeBqTKAKJxK1a6PfGDttTkkmo
 eQ21rH2Du1l4baXDGm02JvjCzRVMUj+qb4TbRvaH4+tm0sLLaSGtdyydQV2o20pXoA2l9kmyo0U
 G3wYLWfSSeomYLNROOPIhF9BdDav4ja9GQlo+/oNM+X3GIs2RXR7reLZy9X4DO3VjIvT76itLiC
 IMcJiXVNg60XBY52hibee2tPxfo5x/O+cWipMA9+KwRDNmw4b5GBj92Dme3tJB1nb/53oiIr4cz
 UV1FJKg5kCTVVG/IX3TaruRRMsRRNUJbpTNudh4FBm4TPOW5HOkvf6KpeGHDsSl3veuh9m2cN3a
 s3t6ZC8VQyviMZOMHr8JaDNT3hX/wxXVLqVlGFQiTXVt8H21oxIfWta+wxR39wNjERkMB089O6u
 etXU7giCX7P5jWaewiA5W4iaowZQPn6d8E6wTfc/ELrCTVsuiTjqms+m1INnbQu0qzxgZ5nkXSB
 cSALXFy3567me+KvsCdfjrsGbopWhvaawoYKOnxOnGoOUjxUFbzBIOl1o3X4ETcb9DGyHD4zfer
 kFH7kT0VZi55SQ5NgUeWLdkCq0ia4xYpW/IZKFT4ytZMnZfZVuaEXo7HHVMME+P2S5HTaER978t
 jj4Ok3tGrnWJf1g==
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
Changes in v4:
- Fixed mixed-up rebase changes between commits and added
  regmap_get_device into _init functions to get the device.
- Link to v3: https://lore.kernel.org/r/20250402-al3010-iio-regmap-v3-0-cc3da273b5b2@ixit.cz

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

 drivers/iio/light/al3000a.c |  9 +++--
 drivers/iio/light/al3010.c  | 85 +++++++++++++++++++++++--------------------
 drivers/iio/light/al3320a.c | 89 +++++++++++++++++++++++++--------------------
 3 files changed, 100 insertions(+), 83 deletions(-)
---
base-commit: f8ffc92ae9052e6615896052f0c5b808bfc17520
change-id: 20250308-al3010-iio-regmap-038cea39f85d

Best regards,
-- 
David Heidelberg <david@ixit.cz>

