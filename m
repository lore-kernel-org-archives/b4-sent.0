From: Marian Poltak <marianpoltak@gmail.com>
Subject: [PATCH bluez v2 0/2] shared/gatt-client: Fix init when Service
 Changed lacks Indicate
Date: Fri, 13 Nov 2026 17:53:39 +0100
Message-Id: <20261113-svc-chngd-notify-only-v2-0-e07cc198f32b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNSw6DMBBDr4Jm3amYgIroqveoWEB+jARJldCoF
 HH3RrlAF148W7YPiDqwjnCvDgg6cWTvMohLBXIendXIKjOIWtyISGBMEuXsrELnNzY7erfsaEi
 R6nvVmKaF3H0FbfhTdp8wLW/9hSHbM8fNh728JSrhn+FEWKPs1NSNss0yD7uOvFylX2E4z/MH+
 48ijsEAAAA=
X-Change-ID: 20261112-svc-chngd-notify-only-f1d1d99d3f34
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794588819; l=1251;
 i=marianpoltak@gmail.com; s=20261112; h=from:subject:message-id;
 bh=cU0eWVhQ+xVj3g+Gv9TfHlL2h2IVIvL88iR1p7mjDvc=;
 b=pljTBl/XB8PkI2Qt5r0/6dJ1VZPhoETA3nKfGcT5sZuVLXWXq5k2gcLlQ1EjRBfg+KpIE65qO
 HPB2oF9K3+RDSNXpb+USZboVb7mF6xMhiknimi6j/OQprUQ2cw9TWVR
X-Developer-Key: i=marianpoltak@gmail.com; a=ed25519;
 pk=VPxSnAMaNkyjfVbKo8tQ1gFPwqOoZoPqtVZ8znSiAiA=
X-Endpoint-Received: by B4 Relay for marianpoltak@gmail.com/20261112 with auth_id=1502
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some devices, e.g. the Aqara Presence Sensor P2 in Matter commissioning
mode, declare the Service Changed characteristic as Read | Notify only.
The client initialization then fails because indications are requested
explicitly, so no services are exported although ServicesResolved is
set.

Patch 1 requests indications only when the characteristic supports
them. Patch 2 adds unit tests for both cases.

---
Changes in v2:
- unit/test-gatt: keep the new tests running until the Service Changed
  CCC write is exchanged; they previously ended as "Not Run" once the
  client reported ready (reported by Copilot review).
- Link to v1: https://patch.msgid.link/20261112-svc-chngd-notify-only-v1-0-c7db7ac47acf@gmail.com

---
Marian Poltak (2):
      shared/gatt-client: Fix init when Service Changed lacks Indicate
      unit/test-gatt: Add Service Changed registration tests

 src/shared/gatt-client.c | 15 +++++++++++++-
 unit/test-gatt.c         | 53 ++++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 67 insertions(+), 1 deletion(-)
---
base-commit: 9659adb6819d7e0284d0d2ba226a3894423d8db4
change-id: 20261112-svc-chngd-notify-only-f1d1d99d3f34

Best regards,
-- 
Marian Poltak <marianpoltak@gmail.com>

