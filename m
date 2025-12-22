From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v3 0/2] iio: dac: adi-axi-dac: Minor cleanups
Date: Mon, 22 Dec 2025 13:48:00 +0000
Message-Id: <20251222-iio-axi-dac-minor-changes-v3-0-29199f239d9c@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIABBMSWkC/43NzQrCMAzA8VeRno30YxXqyfcQD22XbgHXSitjM
 vbudvOiF/H4D8kvMyuYCQs77WaWcaRCKdZQ+x3zvY0dArW1meRSC8kVECWwE0FrPQwUU4b3XgH
 T6GB1kCjQsXp/zxho2uzLtXZP5ZHyc3s1inX6jzoK4OB0c9TcO3RKnW20t9QdfBrYyo7ygxLmF
 yVBAJrgvefCOC6+qGVZXhbw7dAOAQAA
X-Change-ID: 20251203-iio-axi-dac-minor-changes-945fa5f2e1eb
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766411287; l=634;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=O3tzWFV3hU8gAqQTMrh5Kjjke5lNsISbR9xd5iSHpAY=;
 b=VNHgMtgdsdb0y9i0aZo4JPWapkaaswaRFWavmdIR9/5+MS8c7GiDXquPKB3j2Our4ViwkLrEU
 oSXSlzTFStZCtfRb99lcD/FWIsjSO83H3VzTL7VGJvO+5a4TJMNKF4F
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Here it's v3 with the patch split in two.

---
Changes in v3:
- Patch 1:
  * New patch.
- Link to v2: https://lore.kernel.org/r/20251219-iio-axi-dac-minor-changes-v2-1-e9fccc019b01@analog.com

---
Nuno Sá (2):
      iio: dac: adi-axi-dac: Make use of a local struct device variable
      iio: dac: adi-axi-dac: Make use of dev_err_probe()

 drivers/iio/dac/adi-axi-dac.c | 66 ++++++++++++++++++++-----------------------
 1 file changed, 31 insertions(+), 35 deletions(-)
---
base-commit: f9e05791642810a0cf6237d39fafd6fec5e0b4bb
change-id: 20251203-iio-axi-dac-minor-changes-945fa5f2e1eb
--

Thanks!
- Nuno Sá

