From: Joshua Crofts <joshua.crofts1@gmail.com>
Subject: [PATCH 0/7] iio: light: opt3001: driver cleanup
Date: Mon, 11 May 2026 12:04:05 +0200
Message-Id: <20260511-opt3001-cleanup-v1-0-f7879dc3455c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJWpAWoC/x3MQQqAIBBA0avErBtwtIK6SrQQm2ogVLQiiO6et
 HyL/x/InIQzDNUDiS/JEnwB1RW4zfqVUeZi0Ep3qiXCEA+jFKHb2fozoqOGaGZqTK+hVDHxIvd
 /HKf3/QBeb772YQAAAA==
X-Change-ID: 20260511-opt3001-cleanup-c1411de14392
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778493846; l=1156;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=Q1rBnzssda7tdLwjVM6yNMHp5lDEFrPzQPGj06IIvNE=;
 b=/+p4LeIyG0DDi3UZU1Qms2lGU+xW0Tyo4EOnNspDbQDu1duMoRwvwwkq/mNBdoLE1YCokXAab
 kSRylgBkEXBAF+hEHA48ZCl/2twrtqzRv9LrsJY7/ksnJTnjHRnst0Z
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series deals with cleaning up the TI OPT3001 sensor driver,
moving it to more modern kernel practices and improving the code style.

Changes include:
- moving the driver to use devm_* functions
- IWYU cleanups
- removal of unnecessary macros and comments
- using dev_err_probe() in probe and probe path functions
- checkpatch.pl warning cleanups

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
Joshua Crofts (7):
      iio: light: opt3001: make headers conform to iwyu
      iio: light: opt3001: use macros from bits.h header
      iio: light: opt3001: prefer dev_err_probe()
      iio: light: opt3001: move driver to guard(mutex)() use
      iio: light: opt3001: localize for loop iterator
      iio: light: opt3001: remove unnecessary comments
      iio: light: opt3001: switch driver to managed resources

 drivers/iio/light/opt3001.c | 208 +++++++++++++++++++-------------------------
 1 file changed, 88 insertions(+), 120 deletions(-)
---
base-commit: 74d173f29572951629d1e0b7456b424006e51b87
change-id: 20260511-opt3001-cleanup-c1411de14392

Best regards,
-- 
Joshua Crofts <joshua.crofts1@gmail.com>

