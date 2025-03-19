From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 00/13] iio: light: Modernize al3010 and al3320a codebase
Date: Wed, 19 Mar 2025 21:59:39 +0100
Message-Id: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADsw22cC/32NQQ6CMBBFr0Jm7Zhpm2p15T0Mi1oGmESBtISgp
 He3cgCX7yX//Q0SR+EE12qDyIskGYcC+lBB6P3QMUpTGDRpS4Yc+qchRSgyYuTu5Sck4wJ7c2m
 dbaDspsitrHvzXhfuJc1jfO8Xi/rZf7VFIeHjdNbWWHZamZusMh/DB+qc8xfyIQIDsAAAAA==
X-Change-ID: 20250308-al3010-iio-regmap-038cea39f85d
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2111; i=david@ixit.cz;
 h=from:subject:message-id; bh=8STHuFc23s5ULduJ7aYVu6n8GpJ8UmJn4qmi5rEoGew=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2zA9dM2IigZ+WKdbs+x1m9BqHCcuqSmS8yQ45
 k8maostMXyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9swPQAKCRBgAj/E00kg
 coxGEAC6OpsSBl0OPAGqFhuQO2RGtAEYNsZKTtBhofN18Xig/hHMPc78pQIC3cDs6IDaYsSxXQC
 eXvjJES2rQL+RzCRlY0BMPmQ0szDlcD+bmspi6CYyRDkDxcSAzL+1nKFHOkfutvf3YjzoLOvS+Y
 sCvky9NZI0zWS0tGxtO5wl3ax8yXrs1tdPlvswpAMiYmg1rY3UMW2bqmaxIJle+b9v/fQnv6neC
 yolZyCjcaJHxmreo0aVJ4z0f6CP47gpgM5OS1zTyMt5xNBfswKLrNkRZsCizG9NVJHFee3TpOL3
 eCXiHBHapm6HoP7UVYxLOW1jR6yUAb9/R9H6OiypB/W1Ot2Q7xGZx1jzFjv1hOPSU5ny1AbvdpI
 uUSbKsouLPDUHJ8GbCW1mY+f0FOI5hJ/XNA6ZBFFCNKZyaxV7MhQ45txevdBNj21ZTiuo1CyzyI
 VNGmXPRYNZZzLht2NFdDaEOFIngomFLsgpc/EV9rsgwbS1SDNV24Ast4fc4ft6mT0A9stH6I4fZ
 9jmsMWzOOt3dmBdMAnzX3T7rGQ07M3rGlDw1kbS1TFUZZjUtCBcvOuFXQoH5x/ssuQ39MESr6fw
 Ry+DB3FxXBGBlt8GfipmAKR79vNgMqNSJ3LoIusNTVQedHv6q9YuHXshNtRcUZc4SO7TnMP4xQA
 s78kdnblK2PnaVw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series targetting improved readability of code
and modernizing code to match AL3000a (recently upstreamed).

Except slightly improved error reporting,
there shouldn't be any function changes.

Module  before after
al3010  72 kB  58 kB
al3320a 72 kB  58 kB

Signed-off-by: David Heidelberg <david@ixit.cz>
---
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
David Heidelberg (13):
      iio: light: al3010: Use unsigned int for the indexing
      iio: light: al3320a: Use unsigned int for the indexing
      iio: light: al3010: Remove DRV_NAME definition
      iio: light: al3320a: Remove DRV_NAME definition
      iio: light: al3010: Abstract device reference in the probe function
      iio: light: al3320a: Abstract device reference in the probe function
      iio: light: al3010: Split set_pwr function into set_pwr_on and _off
      iio: light: al3320a: Split set_pwr function into set_pwr_on and _off
      iio: light: al3010: Move devm_add_action_or_reset back to _probe
      iio: light: al3010: Improve al3010_init error handling with dev_err_probe
      iio: light: al3320a: Improve error handling with dev_err_probe
      iio: light: al3010: Implement regmap support
      iio: light: al3320a: Implement regmap support

 drivers/iio/light/al3010.c  | 103 +++++++++++++++++++++------------------
 drivers/iio/light/al3320a.c | 115 +++++++++++++++++++++++---------------------
 2 files changed, 116 insertions(+), 102 deletions(-)
---
base-commit: ff7f9b199e3f4cc7d61df5a9a26a7cbb5c1492e6
change-id: 20250308-al3010-iio-regmap-038cea39f85d

Best regards,
-- 
David Heidelberg <david@ixit.cz>

