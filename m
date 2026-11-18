From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Subject: [PATCH v3 0/2] iio: light: adux1020: guard() conversion and
 follow-up cleanup
Date: Wed, 18 Nov 2026 07:29:53 +0000
Message-Id: <20261118-adux1020-guard-v3-0-2c6a18954fc7@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ6CMBQFr0K6tua3oG1deQ/jorQfqBEwLTQYw
 t2luCExLid5M28mAb3DQC7ZTDxGF1zfrZAfMmIa3dVInV2ZcOBnxkBSbceJAQdaj9pbmksOBoU
 qZJGTVXp5rNy0BW/3L4exfKAZUiUtGheG3r+3x8jS7m88MsqoLZU5SV4xRH2tW+2eR9O3JMUj3
 +lM/OicApVKgKg0CDBqry/L8gE3ffc7/QAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794986997; l=1839;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=RXUFbqMqVQo9jZv0Us7HCxZkFucYXq5iLDMq628Oc0k=;
 b=nxO0SD52gnUGe73c9OUMJStq8JsN9On8kXyP7UxtGE8EFxtrSqvl/0OeZxnloSAemDwHs1O+6
 tgKzkORU2NFAOeQUAdtbbu5vySThxbBjygb+90ItmeVW6VuM0UCRexh
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
Changes in v3:
- Patch 2: add a local regmap pointer in adux1020_read_raw() and
  adux1020_write_raw(), and use 'if (ret)' for regmap_read() errors
  (Andy)
- Patch 2: split the adux1020_find_index() arguments logically (Andy)
- Link to v2: https://patch.msgid.link/20261117-adux1020-guard-v2-0-89707fa070c9@gmail.com

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

