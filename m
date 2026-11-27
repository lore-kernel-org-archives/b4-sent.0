From: Fabio Forni <development@redaril.me>
Subject: [PATCH v2 0/2] iio: afe: rescale: Get driver data using
 platform_get_match_data()
Date: Sat, 28 Nov 2026 00:22:08 +0100
Message-Id: <20261128-iio_rescale_platform_ids-v2-0-4c35f16c4f77@redaril.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/43NQQqDMBBA0auEWZuSCVKrq95DRIZkrANqZCLSI
 t691BN0+xfvH5BZhTM05gDlXbKkBRrjCwNhpOXFViI0Brzzd3TuYUVSr5wDTdyvE21D0rmXmK2
 LnqpIoa5KgsLAqjzI+6LbrjAwSt6Sfq7Tjr/6B7qjReuwHjBgWTrvn8qRVKbbzNCd5/kF5OXzM
 MEAAAA=
X-Change-ID: 20261008-iio_rescale_platform_ids-0d2a7dac974a
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Johan Hovold <johan@kernel.org>, Peter Rosin <peda@lysator.liu.se>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: driver-core@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-iio@vger.kernel.org, Fabio Forni <development@redaril.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1477;
 i=development@redaril.me; h=from:subject:message-id;
 bh=PBSXqgaqkOnXYBgeJ3eZjM3FUUbpqsbEEol5o21C8RY=;
 b=owGbwMvMwCXWeKho1tqFWemMp9WSGLK5BDYGOIhX22z/7WaSd0JtVqqBuj3bzVO603imL392k
 qt1Q4FgRykLgxgXg6yYIst/J6NN3WYmRrf6JWph5rAygQxh4OIUgIlsZGP4p2329/PqD0fsq3cX
 rEzefsbd+WPikT+5WVvP7m729AzsmsbI0Kl4YepSJ+4jaXZrp0r/iZRe6tSr4hQl9587Lzri/1s
 TZgA=
X-Developer-Key: i=development@redaril.me; a=openpgp;
 fpr=FF4232B28B363432DA8F187D81C2729AADA16A67
X-Endpoint-Received: by B4 Relay for development@redaril.me/default with auth_id=1033
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a new helper to get data when drivers are bound using platform_device
plus swnodes, that typically happpens when such drivers are dynamically
instantiated.

As swnodes do not implement device_get_match_data(), a fallback mechanism
is needed to access driver_data inside platform_device_id structs. While
drivers can have such logic locally, Andy Shevchenko suggested to add a
global helper for this situation. See discussion in v1. 

v1 was about adding the logic above in iio-rescale: the same goal applies
to this revision. iio-rescale is modified to call the new
platform_get_match_data() helper.

Signed-off-by: Fabio Forni <development@redaril.me>
---
Changes in v2:
- Add platform_get_match_data()
- Use platform_get_match_data() in iio-rescale
- Use imperative mood throughout commits and cover letter
- Link to v1: https://lore.kernel.org/r/20261008-iio_rescale_platform_ids-v1-1-019f1c144022@redaril.me

---
Fabio Forni (2):
      drivers: core: platform: Add platform_get_match_data() helper
      iio: afe: iio-rescale: Add platform IDs

 drivers/base/platform.c         | 28 ++++++++++++++++++++++++++++
 drivers/iio/afe/iio-rescale.c   | 18 +++++++++++++++++-
 include/linux/platform_device.h |  2 ++
 3 files changed, 47 insertions(+), 1 deletion(-)
---
base-commit: 4dce97c6c265544342e716e62fd24bbb232590c5
change-id: 20261008-iio_rescale_platform_ids-0d2a7dac974a

Best regards,
-- 
Fabio Forni <development@redaril.me>

