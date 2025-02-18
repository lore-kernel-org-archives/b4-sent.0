From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH 0/2] iio: small fixes and improvements
Date: Tue, 18 Feb 2025 10:31:24 +0000
Message-Id: <20250218-dev-iio-misc-v1-0-bf72b20a1eb8@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAH1htGcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDI0ML3ZTUMt3MzHzd3MziZN0UcwsTI9NESxNLC1MloJaCotS0zAqwcdG
 xtbUAlvOjl14AAAA=
X-Change-ID: 20250218-dev-iio-misc-d78425a94985
To: linux-iio@vger.kernel.org
Cc: Olivier Moysan <olivier.moysan@foss.st.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739874693; l=740;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=CKIe0qJhJkr78+nRNyahW/0Imlybj2XSKCQoyCG9RZc=;
 b=Vb07n5T0DAHyzXu/0cREM7Qcxs5PCgVjlG+WK3HA87N0ZIZvEXZ5+0KSvxwhveP3p+Z1A0ey4
 tl01yWRDNA/BRKCnm9/SgJoZRxoFlbckc6xRvPUHx3MiKBOzAgkycpM
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The first patch is a fix for the backend code dealing with
direct_register_access. We need to properly terminate the received
string before passing it to sscanf().

The second patch is about using the simple_write_to_buffer() which makes
the direct_register_access write side more symmetric with the read side.

---
Nuno Sá (2):
      iio: backend: make sure to NULL terminate stack buffer
      iio: core: make use of simple_write_to_buffer()

 drivers/iio/industrialio-backend.c | 4 +++-
 drivers/iio/industrialio-core.c    | 9 +++++----
 2 files changed, 8 insertions(+), 5 deletions(-)
---
base-commit: c0f115a8d97599623294c8e9ec28530e19c1e85b
change-id: 20250218-dev-iio-misc-d78425a94985
--

Thanks!
- Nuno Sá

