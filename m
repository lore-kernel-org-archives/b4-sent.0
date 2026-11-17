From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Subject: [PATCH v2 0/2] iio: light: adux1020: guard() conversion and
 follow-up cleanup
Date: Tue, 17 Nov 2026 07:11:00 +0000
Message-Id: <20261117-adux1020-guard-v2-0-89707fa070c9@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ6CMBBFr0JmbU2noBZW3sOwKO0AY4SaFgiGc
 HcB1y5f8v77C0QKTBGKZIFAE0f2/QbqlIBtTd+QYLcxKKmuiFIL48YZpZKiGU1wItVKWrrlmc5
 S2EbvQDXPR/BR/jiO1ZPssFd2o+U4+PA5Hifcvb/xCQUKV+X2olWNRObedIZfZ+s7KNd1/QJXm
 FzevgAAAA==
X-Change-ID: 20261108-adux1020-guard-3820ce794843
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux@analog.com, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>, 
 Joshua Crofts <crofts@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794899463; l=1513;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=8fhMW5mm0iEr5bWCoFt/XsKE4zlSiXDS51NkKQm5AEo=;
 b=3vJ+8ilR+BrxEexRFvic6Ry2GRChnC/YBYJimlZz6hIONX0l+nL2BybrWml2IJUEryhP/XrTw
 qauGYSVybpKDBEylSQYSxzRkLuIZYWPLnFwJBpnV9W4vaus54XhIA5h
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Patch 1 converts the driver to guard(mutex), as Jonathan suggested
when applying the sampling frequency hardening patch. Patch 2 uses the
direct returns this allows to flatten the channel type checks in
adux1020_read_raw() and adux1020_write_raw().

Tested on arm64 QEMU with i2c-stub and lockdep enabled: reading and
writing the sampling frequency (valid and invalid values), reading the
LED current, reading in_proximity_raw and enabling the threshold
event. No lockdep warnings and no hangs after the error paths.

I prepared these patches with the help of an AI coding assistant, and
reviewed and tested them myself.

Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
Changes in v2:
- Drop the unreferenced Link tag (Andy)
- Move ret to the end of the declarations in adux1020_read_raw() (Andy)
- New patch 2: return early on unsupported channel types instead of
  nesting (Jonathan)
- Link to v1: https://patch.msgid.link/20261108-adux1020-guard-v1-1-db9c582f1eea@gmail.com

---
Raffaele Tranfaglia (2):
      iio: light: adux1020: use guard() to simplify lock handling
      iio: light: adux1020: return early on unsupported channel types

 drivers/iio/light/adux1020.c | 189 ++++++++++++++++++-------------------------
 1 file changed, 77 insertions(+), 112 deletions(-)
---
base-commit: d922ed738439e1d5b4701df7f4cdd49a09925624
change-id: 20261108-adux1020-guard-3820ce794843

Best regards,
--  
Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>

