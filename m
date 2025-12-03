From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH 0/2] iio: dac: adi-axi-dac: Minor cleanups
Date: Wed, 03 Dec 2025 15:53:35 +0000
Message-Id: <20251203-iio-axi-dac-minor-changes-v1-0-b54650cbeb33@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAP9cMGkC/yWMQQqAIBQFrxJ/3Ye0XNRVooXVt94iDYUIpLsnt
 RyYmUxJIiTRUGWKciEh+AKqrmjZrd+EsRYm3WijdNMyENje4NUufMCHyL+XuO+Ms8ZpUTJT6c8
 oDvf3HqfneQFkKzA9awAAAA==
X-Change-ID: 20251203-iio-axi-dac-minor-changes-945fa5f2e1eb
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764777217; l=480;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=2AHFe2w84lGFKnqTr1gFzttLc8+02i8mtrCuH+ghiPk=;
 b=SzlRm2vupn+/WEUI+CdieEBLI5MV8CvrUuIZflaGGVBxeZ0RrIGOnuL7UDHNqUHXv3CqxrugA
 ZHVHaYTM3ZTCGaVnSmmRQ0M9CohrVtP6Tw0lQ+BelzfB+Vx9v1lA7DW
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Small series to use dev_err_probe() and turn dev_info() into dev_dbg()

---
Nuno Sá (2):
      iio: dac: adi-axi-dac: Make use of dev_err_probe()
      iio: dac: adi-axi-dac: Turn dev_info() into dev_dbg()

 drivers/iio/dac/adi-axi-dac.c | 28 +++++++++++++---------------
 1 file changed, 13 insertions(+), 15 deletions(-)
---
base-commit: f9e05791642810a0cf6237d39fafd6fec5e0b4bb
change-id: 20251203-iio-axi-dac-minor-changes-945fa5f2e1eb
--

Thanks!
- Nuno Sá

